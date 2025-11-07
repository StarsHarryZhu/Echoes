//
//  Constants.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/7.
//

import Foundation
import UIKit

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

enum camera_return{
    case success(UIImage?)
    case cancel
    case exception(String)
}
