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
            print("ok")
        
        case .cancel:
            alert("cancelled","photo")
        
        case .exception(let error):
            alert("\(error)", "photo")
    }
}
