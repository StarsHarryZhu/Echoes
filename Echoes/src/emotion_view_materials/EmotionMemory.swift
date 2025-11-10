//
//  EmotionMemory.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/9.
//

import Foundation

struct emotion_memory: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let date: Date
    let cover: String?
    let emotion: emotion
}
