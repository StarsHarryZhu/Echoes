//
//  EmotionRecognation.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/7.
//

import Foundation
import UIKit
import Vision


enum emotion_return{
    case success(emotion)
    case fail(String)
}

func emotion_detect(in image: UIImage) -> emotion_return{
    guard let CG_image = image.cgImage else {
        return .fail("Failed to get CGImage from UIImage")
    }
    
    return .fail("Not implemented")
}
