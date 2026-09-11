//
//  CameraController.swift
//  Echoes
//

import Foundation
import ImageIO
import UIKit

/// 拍照能力的抽象。上层（`CaptureCoordinator`）只依赖这个协议，
/// 将来换成 AVFoundation 自定义相机时不用动上层代码。
@MainActor
protocol CameraCapturing {
    /// 弹前置相机拍照。
    ///
    /// - Returns: 拍到的照片，以及该照片像素数据对应的方向。
    /// - Throws: `CameraError`。用户主动取消抛 `.cancelled`。
    func captureFrontPhoto() async throws -> (image: UIImage, orientation: CGImagePropertyOrientation)
}

/// 拍照过程中的失败原因。
enum CameraError: LocalizedError {
    case unavailable
    case frontCameraUnavailable
    case noPresentingViewController
    case noImageReturned
    case cancelled

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return L10n.cameraUnavailable
        case .frontCameraUnavailable:
            return L10n.cameraFrontUnavailable
        case .noPresentingViewController:
            return L10n.cameraNoPresenter
        case .noImageReturned:
            return L10n.cameraNoImage
        case .cancelled:
            return nil
        }
    }

    /// 用户主动取消不算错误，界面不该弹提示。
    var isCancellation: Bool {
        if case .cancelled = self { return true }
        return false
    }
}

/// 基于 `UIImagePickerController` 的前置相机实现。
///
/// 重构前是 `camera_control`：`capture()` 里 new 一个实例、存在局部变量里就 await，
/// 没有任何强引用保证它活到回调那一刻；续体也可能被重复 resume 而崩。
/// 这里两处都修了：实例由持有者强引用，续体带一次性保护。
@MainActor
final class UIImagePickerCamera: NSObject, CameraCapturing, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    private var continuation: CheckedContinuation<(image: UIImage, orientation: CGImagePropertyOrientation), any Error>?
    private var isAwaitingResult = false

    func captureFrontPhoto() async throws -> (image: UIImage, orientation: CGImagePropertyOrientation) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            throw CameraError.unavailable
        }
        guard UIImagePickerController.isCameraDeviceAvailable(.front) else {
            throw CameraError.frontCameraUnavailable
        }
        guard let presenter = Self.topViewController() else {
            throw CameraError.noPresentingViewController
        }

        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraDevice = .front
        picker.cameraCaptureMode = .photo
        // 前置自拍：打开镜像，所见即所得。（`showsCameraControls` 保持默认，
        // 用系统原生取景界面；自定义取景是后续换 AVFoundation 的事。）
        picker.allowsEditing = false
        picker.delegate = self

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            self.isAwaitingResult = true
            presenter.present(picker, animated: true)
        }
    }

    // MARK: - UIImagePickerControllerDelegate

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        guard let image = info[.originalImage] as? UIImage else {
            finish(with: .failure(CameraError.noImageReturned))
            picker.dismiss(animated: true)
            return
        }

        // 前置相机拍出的图带 `imageOrientation`，像素数据本身没转正。
        // Vision 需要这个方向才能在正确的坐标系里找人脸。
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        finish(with: .success((image, orientation)))
        picker.dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        finish(with: .failure(CameraError.cancelled))
        picker.dismiss(animated: true)
    }

    // MARK: - 内部实现

    /// 只允许 resume 一次。系统在极端情况下（快速取消 + 完成）可能回调两次，
    /// 重复 resume 会直接终止进程。
    private func finish(
        with result: Result<(image: UIImage, orientation: CGImagePropertyOrientation), any Error>
    ) {
        guard isAwaitingResult, let continuation else { return }
        isAwaitingResult = false
        self.continuation = nil
        continuation.resume(with: result)
    }

    /// 找到当前可以 present 的控制器。
    ///
    /// 重构前用的是 `connectedScenes.compactMap { $0.keyWindow?.rootViewController }.first`
    /// 再直接 present —— 如果 root 之上已经有别的东西在弹（比如设置页或一个 alert），
    /// 这个 present 会被系统忽略并卡住 await。这里沿着 `presentedViewController` 往上找。
    private static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let window = scenes
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
            ?? scenes.flatMap(\.windows).first

        var controller = window?.rootViewController
        while let presented = controller?.presentedViewController {
            controller = presented
        }
        return controller
    }
}

#if targetEnvironment(simulator)

/// 模拟器没有相机，`UIImagePickerController.isSourceTypeAvailable(.camera)` 恒为 false，
/// 也就永远走不到人脸识别那段代码。这里用包内采样图顶上，
/// 让整条「拍照 → 识别 → 归档」链路在模拟器上也能跑通、被测到。
@MainActor
final class SimulatedCamera: CameraCapturing {

    /// 每次取一张不同的采样图，方便观察不同表情的结果。
    private var nextIndex = 0

    func captureFrontPhoto() async throws -> (image: UIImage, orientation: CGImagePropertyOrientation) {
        let names = AppInfo.SampleImage.names
        for offset in 0..<names.count {
            let name = names[(nextIndex + offset) % names.count]
            if let image = UIImage(named: name) {
                nextIndex = (nextIndex + offset + 1) % names.count
                return (image, .up)
            }
        }
        guard let fallback = UIImage(named: AppInfo.SampleImage.fallback) else {
            throw CameraError.unavailable
        }
        return (fallback, .up)
    }
}

#endif
