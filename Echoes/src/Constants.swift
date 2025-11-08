//
//  Constants.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/7.
//

import Foundation
import UIKit

enum emotions{
    case joy
    case sad
    case calm
    case fear
    case anger
    case surprise
}

struct tabview_words{
    static let home = "Home"
    static let emotion = "Emotions"
    static let memory = "Memories"
    static let photos = "Photos"
}

struct tabview_images{
    static let home = "house"
    static let emotion = "person.fill"
    static let memory = "memories"
    static let photos = "photo"
}

struct camera_button{
    static let image = "camera.fill"
}

struct text_info{
    static let font = "SmileySans-Oblique"
}

struct camera_info{
    static let source = UIImagePickerController.SourceType.camera
    static let camera_mode = UIImagePickerController.CameraCaptureMode.photo
    static let camera = UIImagePickerController.CameraDevice.front
    static let allow_edit: Bool = false
}

let intro_text: String =
"""
Echoes is built by a small team who believe photos are more than pixels — they’re emotions and stories. We design calm, human-centered tools that help you capture feelings and revisit memories with care.
"""
let rate_us_text: String = "If you like Echoes, a 5-star rating really helps! ✨"
