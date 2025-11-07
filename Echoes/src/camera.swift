//
//  camera.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/7.
//

import Foundation
import UIKit

class camera_control: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private var continuation: CheckedContinuation<camera_return, Never>?
    
    func capture() async -> camera_return {
        
        let source = UIImagePickerController.SourceType.camera;
        guard UIImagePickerController.isSourceTypeAvailable(source)
        else {
            return camera_return.exception("Camera is not available")
        }
        
        guard let root_view_controller = UIApplication.shared.connectedScenes
                        .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController })
                        .first
        else {
            return camera_return.exception("Could not present camera")
        }
        
        let picker = UIImagePickerController()
        picker.sourceType = source
        picker.allowsEditing = false
        picker.delegate = self
        
        return await withCheckedContinuation { (continuation: CheckedContinuation<camera_return, Never>) in
            self.continuation = continuation
            root_view_controller.present(picker, animated: true)
        }
    }
    func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[.originalImage] as? UIImage
        self.continuation?.resume(returning: camera_return.success(image))
        picker.dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.continuation?.resume(returning: camera_return.cancel)
        picker.dismiss(animated: true)
    }
}
