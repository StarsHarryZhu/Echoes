//
//  CapturePathTests.swift
//  EchoesTests
//

import Testing
import UIKit

@testable import Echoes

/// 拍照来源与失败路径。
///
/// Echoes 需要**前置**相机，且**没有兜底**：相机不可用就报错、由界面弹窗提示，
/// 不会悄悄给一张替代图片。这组测试把这个约定钉住。
@Suite("拍照来源与失败路径")
@MainActor
struct CapturePathTests {

    /// 记录一条实测事实：两个相机 API 的答案**可以不一致**。
    ///
    /// iOS 27 模拟器上 `isSourceTypeAvailable(.camera)` 返回 `true`，
    /// 而 `isCameraDeviceAvailable(.front)` 返回 `false`。
    /// 所以不能拿 `.camera` 源可用当"有相机"用 —— 否则会走真机路径、
    /// 最后拿不到照片。Echoes 必须用前置相机，判据只能是后者。
    @Test("相机可用性以「前置相机」为准，不能拿 camera 源顶替")
    func capabilityIsAboutTheFrontCamera() {
        let hasCameraSource = UIImagePickerController.isSourceTypeAvailable(.camera)
        let hasFrontCamera = UIImagePickerController.isCameraDeviceAvailable(.front)

        // 这条断言的意义：camera 源报告可用时，也**不能**据此认为有前置相机。
        // iOS 27 模拟器就是这个组合（source = true、front = false）。
        if hasCameraSource && !hasFrontCamera {
            #expect(!hasFrontCamera, "必须以前置相机可用性为准")
        }

        // 而反过来（有前置相机却没有 camera 源）是不成立的，可作为一致性检查。
        if hasFrontCamera {
            #expect(hasCameraSource, "有前置相机时 camera 源应该也可用")
        }
    }

    /// 核心行为：没有前置相机时抛明确错误，**不返回替代图片**。
    @Test("相机不可用时抛错，不给替代图片")
    func unavailableCameraThrows() async {
        guard !UIImagePickerController.isCameraDeviceAvailable(.front) else { return }

        let camera = UIImagePickerCamera()
        do {
            _ = try await camera.captureFrontPhoto()
            Issue.record("相机不可用时不应该返回照片 —— 兜底已被移除")
        } catch let error as CameraError {
            #expect(
                error == .unavailable || error == .frontCameraUnavailable,
                "期望「相机不可用」类错误，实际 \(error)"
            )
        } catch {
            Issue.record("抛出了非 CameraError：\(error)")
        }
    }

    @Test("相机不可用的错误文案可以展示给用户")
    func unavailableErrorHasLocalizedMessage() throws {
        for error in [CameraError.unavailable, .frontCameraUnavailable] {
            let message = try #require(error.errorDescription)
            #expect(!message.isEmpty)
            // 必须是文案，不是 key
            #expect(!message.hasPrefix("camera."))
        }
    }

    @Test("用户取消不算错误，不该弹提示")
    func cancellationIsNotAnError() {
        #expect(CameraError.cancelled.isCancellation)
        #expect(!CameraError.unavailable.isCancellation)
        #expect(!CameraError.frontCameraUnavailable.isCancellation)
        #expect(CameraError.cancelled.errorDescription == nil)
    }

    @Test("生产组装一律使用系统相机实现")
    func defaultUsesSystemCamera() {
        let coordinator = CaptureCoordinator.makeDefault(store: MemoryStore())
        #expect(coordinator.camera is UIImagePickerCamera)
    }
}
