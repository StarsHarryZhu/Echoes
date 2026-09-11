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

    /// 生产环境的组合：始终用系统前置相机。
    ///
    /// **没有兜底**。相机不可用时 `UIImagePickerCamera` 会抛 `CameraError`，
    /// 由 `RootView` 弹出提示让用户知道 —— 而不是悄悄给一张替代图片。
    static func makeDefault(store: MemoryStore) -> CaptureCoordinator {
        CaptureCoordinator(camera: UIImagePickerCamera(), store: store)
    }

    // MARK: - 流程

    /// 快门：弹相机 → 识别 → 进入预览。
    func startCapture() async {
        guard phase.acceptsNewCapture else { return }

        // 上一次的预览图先清掉，避免识别过程中界面上还挂着上一张。
        pendingImage = nil
        hasCommittedReview = false
        phase = .capturing

        let captured: (image: UIImage, orientation: CGImagePropertyOrientation)
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
