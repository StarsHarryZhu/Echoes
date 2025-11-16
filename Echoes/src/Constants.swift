//
//  Constants.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/7.
//

import Foundation
import Combine
import UIKit
import SwiftUI

enum emotion: String, CaseIterable, Identifiable, Hashable {
    case angry = "Angry"
    case disgust = "Disgust"
    case fear = "Fear"
    case happy = "Happy"
    case neutral = "Neutral"
    case sad = "Sad"
    case surprise = "Surprise"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .angry: return "flame.fill"
        case .disgust: return "leaf.circle.fill"   // 可随便换，你自己选图标
        case .fear: return "exclamationmark.triangle.fill"
        case .happy: return "sun.max.fill"
        case .neutral: return "circle.fill"
        case .sad: return "cloud.rain.fill"
        case .surprise: return "sparkles"
        }
    }

    var tint: Color {
        switch self {
        case .angry: return .red
        case .disgust: return .green
        case .fear: return .orange
        case .happy: return .yellow
        case .neutral: return .gray
        case .sad: return .blue
        case .surprise: return .purple
        }
    }
}

struct emotion_memory: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let date: Date
    let cover: String?
    let emotion: emotion
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
