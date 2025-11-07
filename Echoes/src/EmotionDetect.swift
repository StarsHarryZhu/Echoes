//
//  EmotionRecognation.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/7.
//

import Foundation
import UIKit
import Vision
import VisionKit

enum emotion_return{
    case success(String)
    case fail(String)
}

func detect_emotion(from image: UIImage) -> emotion_return{
    guard let CGImage = image.cgImage else {
        return emotion_return.fail("❌ 无法从 UIImage 获取 CGImage")
    }
    
    let request = VNDetectFaceRectanglesRequest()
    let handler = VNImageRequestHandler(cgImage: CGImage, options: [:])
    
    return emotion_return.fail("😄 暂时没有实现情绪识别功能")
}
