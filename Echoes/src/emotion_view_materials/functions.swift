//
//  functions.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/9.
//

import Foundation
import UIKit
import SwiftUI


func cover_image(of m: emotion_memory) -> Image {
    if let n = m.cover, UIImage(named: n) != nil { return Image(n) }
    return Image(systemName: "photo.on.rectangle.angled")
}

func formatted_date(_ date: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "yy/MM/dd"
    return f.string(from: date)
}
