//
//  EmotionRecognation.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/7.
//

import Foundation
import UIKit
import Vision

enum face_return{
    case success(VNFaceObservation?)
    case fail(String)
}

func detect_face(in image: UIImage) -> face_return{
    
    guard let cgImage = image.cgImage else {
        return .fail("无法从 UIImage 获取 CGImage")
    }
    
    var detected_face: VNFaceObservation? = nil
    
    let request = VNDetectFaceLandmarksRequest { request, error in
        if let _ = error {
            detected_face = nil
            return
        }
        
        guard let faces = request.results as? [VNFaceObservation],
              !faces.isEmpty else {
            detected_face = nil
            return
        }
        
        detected_face = faces.max(by: {
            ($0.boundingBox.width * $0.boundingBox.height) <
            ($1.boundingBox.width * $1.boundingBox.height)
        })
    }
    
    let handler = VNImageRequestHandler(
        cgImage: cgImage,
        orientation: CGImagePropertyOrientation(image.imageOrientation),
        options: [:]
    )
    
    do {
        try handler.perform([request])
    } catch {
        return .fail("Vision 请求执行失败:")
    }
    
    return .success(detected_face)
}
