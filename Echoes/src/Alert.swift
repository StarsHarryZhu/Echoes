//
//  Alert.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/8.
//

import Foundation
import SwiftUI

func alert(_ message: String, _ title: String = "Echoes") {
    
    DispatchQueue.main.async {
        
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root_VC = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        
        var top_VC = root_VC
        while let presented = top_VC.presentedViewController {
            top_VC = presented
        }
        
        top_VC.present(alert, animated: true)
    }
}
