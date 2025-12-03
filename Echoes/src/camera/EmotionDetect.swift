//
//  EmotionDetect.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/8.
//

import Foundation
import UIKit

enum emotion_return{
    case success(emotion_memory)
    case fail(String)
}

func emotion_detect(from image: UIImage) -> emotion_return {
    let result = detect_face(in: image)
    switch result{
        case .success(let face):
            if face == nil {
                alert("Fail to detecting face")
            } else {
                guard let result = emotion_service.shared.predict(from: image) else {
                    return .fail("Fail to detect emotion")
                }
                let (emotion, confidence) = result;
                let date = Date();
                
                
            }
        
        case .fail(let message):
            alert(message)
        
    }
    return .fail("Not implemented")
}
