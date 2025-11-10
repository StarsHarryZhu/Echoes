//
//  Capture.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/8.
//

import Foundation
import UIKit

@MainActor
func capture() async {
    
    let camera = camera_control()
    let result = await camera.capture()
    
    switch result{
    case .success(let image):
        let result = emotion_detect(from: image!)
        
        switch result{
        case .success(let emotion_pack):
            alert("success", "package return")
        case .fail:
            alert("fail to get emotion")
        }
        
    case .cancel:
        alert("cancelled")
        
    case .exception(let error):
        alert("\(error)", "photo")
    }
}
