//
//  CapturePathTests.swift
//  EchoesTests
//

import Testing
import UIKit

@testable import Echoes

/// 拍照来源的选择逻辑。
///
/// 加这组测试是因为开发时在模拟器上点相机键"没有呼出相机、却出现了一张照片"，
/// 需要有一条测试说清楚这是**有意为之的兜底**，而不是走错了分支。
@Suite("拍照来源")
@MainActor
struct CapturePathTests {

    /// 记录一条实测事实：**不能**假设"模拟器没有相机"。
    ///
    /// 开发时点相机键没呼出相机、却出现了一照片，查下来就是因为
    /// `isSourceTypeAvailable(.camera)` 在 iOS 27 模拟器上返回 `true`。
    /// 兜底因此改为运行时判断，这条测试把这个前提钉住。
    @Test("相机可用性必须按运行时判断，不能靠编译期假设")
    func cameraAvailabilityIsRuntimeDependent() {
        let sourceAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)
        let frontAvailable = UIImagePickerController.isCameraDeviceAvailable(.front)

        // 关键事实：这两个 API 的答案**可以不一样** ——
        // iOS 27 模拟器上 source 为 true 而 front 为 false。
        // 所以不能拿 `.camera` 源可用当"有相机"用。
        #expect(frontAvailable == CaptureCoordinator.hasFrontCamera)

        if !frontAvailable {
            #expect(CaptureCoordinator.hasFrontCamera == false)
        }
        _ = sourceAvailable   // 仅作记录，不参与判据
    }

    @Test("工厂按运行时能力选择实现")
    func factoryPicksImplementationByCapability() {
        let store = MemoryStore()
        let coordinator = CaptureCoordinator.makeDefault(store: store)

        if CaptureCoordinator.hasFrontCamera {
            #expect(coordinator.camera is UIImagePickerCamera,
                    "有前置相机就应该用系统相机，而不是采样图兜底")
        } else {
            #expect(coordinator.camera is SimulatedCamera,
                    "没有前置相机才应该退回采样图")
        }
    }

    @Test("采样图兜底按顺序轮换，且每张都能取到")
    func simulatedCameraReturnsBundledImages() async throws {
        let camera = SimulatedCamera()
        var seen: [UIImage] = []

        for _ in 0..<AppInfo.SampleImage.names.count {
            let captured = try await camera.captureFrontPhoto()
            seen.append(captured.image)
            #expect(captured.orientation == .up)
        }

        // 轮换一整圈：拿到 4 张不同的图
        #expect(seen.count == AppInfo.SampleImage.names.count)
        let distinct = Set(seen.map { ObjectIdentifier($0) })
        #expect(distinct.count == AppInfo.SampleImage.names.count, "兜底应该在采样图之间轮换")

        // 每张都有真实像素，能送进识别管线
        for image in seen {
            #expect(image.cgImage != nil)
        }
    }

    @Test("采样图都在包里")
    func sampleImagesAreBundled() {
        let missing = AppInfo.SampleImage.names.filter { UIImage(named: $0) == nil }
        #expect(missing.isEmpty, "包装里缺少采样图：\(missing)")
    }

    /// `UIImagePickerCamera` **不会**静默换成采样图：没有相机就抛明确错误。
    ///
    /// 只有环境确实没有相机时才检验 —— 有相机时它会真的弹相机，没法在测试里跑。
    @Test("系统相机在无相机环境下抛明确错误，不静默兜底")
    func realCameraThrowsWhenUnavailable() async {
        guard !CaptureCoordinator.hasFrontCamera else { return }

        let camera = UIImagePickerCamera()
        do {
            _ = try await camera.captureFrontPhoto()
            Issue.record("相机不可用时不应该返回照片")
        } catch let error as CameraError {
            #expect(error == .unavailable || error == .frontCameraUnavailable)
        } catch {
            Issue.record("抛出了非 CameraError：\(error)")
        }
    }
}
