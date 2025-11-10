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
    case joy = "Joy", sad = "Sad", calm = "Calm", angry = "Angry",
         surprise = "Surprise", fear = "Fear", love = "Love", neutral = "Neutral"
    var id: String { rawValue }

    var icon: String {
        switch self {
        case .joy: return "sun.max.fill"
        case .sad: return "cloud.rain.fill"
        case .calm: return "leaf.fill"
        case .angry: return "flame.fill"
        case .surprise: return "sparkles"
        case .fear: return "exclamationmark.triangle.fill"
        case .love: return "heart.fill"
        case .neutral: return "circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .joy: return .yellow
        case .sad: return .blue
        case .calm: return .teal
        case .angry: return .red
        case .surprise: return .purple
        case .fear: return .orange
        case .love: return .pink
        case .neutral: return .gray
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
