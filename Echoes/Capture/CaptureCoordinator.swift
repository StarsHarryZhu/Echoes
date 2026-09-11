//
//  CaptureCoordinator.swift
//  Echoes
//

import ImageIO
import Observation
import SwiftUI
import UIKit

/// 拍照 → 识别 → 预览 → 归档 的流程编排。
///
/// 重构前这条链路写在全局函数 `capture()` 里，识别完**直接静默入库**：
/// 用户看不到判成了什么表情，也无从确认或放弃。而且错误提示走的是
/// `Alert.swift` 里手写的 `UIAlertController`（要在 `presentedViewController`
/// 链上自己找顶层控制器），和 SwiftUI 的界面状态各说各话。这里把状态收进一个
/// `@Observable` 对象，界面直接读 `phase` 渲染。
@MainActor
@Observable
final class CaptureCoordinator {

    enum Phase: Equatable {
        /// 空闲。
        case idle
        /// 相机已经弹出，等用户按快门。
        case capturing
        /// 拿到照片，正在识别人脸与表情。
        case analyzing
        /// 识别完成，等用户确认保存或放弃。
        case reviewing(EmotionReport)
        /// 正在写入磁盘。
        case saving
        /// 出错。
        case failed(String)

        /// 是否应该显示"正在识别"的进度指示。
        var isBusy: Bool {
            switch self {
            case .capturing, .analyzing, .saving: return true
            default: return false
            }
        }

        /// 是否应该禁掉快门按钮（避免连点）。
        var acceptsNewCapture: Bool {
            switch self {
            case .idle, .failed: return true
            default: return false
            }
        }
    }

    // MARK: 状态

    private(set) var phase: Phase = .idle
    /// 待确认的照片。`phase` 是 `Equatable` 的纯状态，图片单独放这里。
    private(set) var pendingImage: UIImage?
    /// 最近一次保存成功的记录，用于界面给一下确认反馈。
    private(set) var lastSaved: Memory?
    /// 预览页是否已经点了「保存」。界面用它区分"被用户关掉"和"正在保存"。
    private(set) var hasCommittedReview = false
    /// 待确认照片的来源。界面据此说明"这是示例图，不是真拍的"。
    private(set) var pendingSource: CaptureSource = .camera

    // MARK: 依赖

    /// 测试会读它来确认注入了哪个实现。
    let camera: any CameraCapturing
    private let analyzer: EmotionAnalyzer
    private let store: MemoryStore

    init(
        camera: any CameraCapturing,
        analyzer: EmotionAnalyzer = .shared,
        store: MemoryStore
    ) {
        self.camera = camera
        self.analyzer = analyzer
        self.store = store
    }

    /// 生产环境的组合：有前置相机就用系统相机，否则用包内采样图。
    ///
    /// 判据是**运行时能力**，而不是 `#if targetEnvironment(simulator)`。
    /// 实测 iOS 27 的模拟器上：
    /// - `isSourceTypeAvailable(.camera)` → `true`
    /// - `isCameraDeviceAvailable(.front)` → `false`
    ///
    /// 也就是说"camera 源可用"并不代表"有能用的相机"，更不代表"有前置相机"。
    /// 之前用 `#if targetEnvironment(simulator)` 反而歪打正着地绕开了这个坑；
    /// 换成只判断 camera 源之后，模拟器会被误判成"有相机"、走真机路径、
    /// 最后拿不到照片。
    ///
    /// Echoes 必须用前置相机，所以判据是 `isCameraDeviceAvailable(.front)`。
    static func makeDefault(store: MemoryStore) -> CaptureCoordinator {
        let camera: any CameraCapturing = Self.hasFrontCamera ? UIImagePickerCamera() : SimulatedCamera()
        return CaptureCoordinator(camera: camera, store: store)
    }

    /// 当前环境是否有可用的**前置**相机。
    static var hasFrontCamera: Bool {
        UIImagePickerController.isCameraDeviceAvailable(.front)
    }

    // MARK: - 流程

    /// 快门：弹相机 → 识别 → 进入预览。
    func startCapture() async {
        guard phase.acceptsNewCapture else { return }

        // 上一次的预览图先清掉，避免识别过程中界面上还挂着上一张。
        pendingImage = nil
        pendingSource = .camera
        hasCommittedReview = false
        phase = .capturing

        let captured: CapturedPhoto
        do {
            captured = try await camera.captureFrontPhoto()
        } catch let error as CameraError where error.isCancellation {
            // 用户主动取消：安静回到空闲，不弹错误。
            phase = .idle
            return
        } catch {
            phase = .failed(error.localizedDescription)
            return
        }

        phase = .analyzing
        do {
            let report = try await analyzer.analyze(
                image: captured.image,
                orientation: captured.orientation
            )
            pendingImage = captured.image
            pendingSource = captured.source
            phase = .reviewing(report)
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    /// 预览页「保存」。
    ///
    /// 先把 report 与 image 取到局部变量再切 phase —— 切到 `.saving` 会让预览页的
    /// `isPresented` 变 false，没有任何时机问题；但如果先切 phase 再去读 `pendingImage`，
    /// 就会读到已经被界面清掉的值。
    func savePendingMemory() async {
        guard case .reviewing(let report) = phase, let image = pendingImage else { return }

        hasCommittedReview = true
        phase = .saving
        do {
            let memory = try await store.add(image: image, report: report)
            lastSaved = memory
            pendingImage = nil
            phase = .idle
        } catch {
            phase = .failed(L10n.saveFailed(error.localizedDescription))
        }
        hasCommittedReview = false
    }

    /// 预览页「重拍」/「放弃」。
    func discardPendingMemory() {
        guard !hasCommittedReview else { return }
        pendingImage = nil
        phase = .idle
    }

    /// 关掉错误弹窗。
    func clearFailure() {
        if case .failed = phase {
            phase = .idle
        }
    }

    /// 界面已经消费过「刚保存」的反馈。
    func acknowledgeSaved() {
        lastSaved = nil
    }
}
