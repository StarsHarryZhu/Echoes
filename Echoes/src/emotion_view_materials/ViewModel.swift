//
//  ViewModel.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/9.
//

import Foundation
import SwiftUI
import Combine

final class emotions_view_model: ObservableObject {
    @Published var all: [emotion_memory] = {
        let es: [emotion] = [.joy,.sad,.calm,.angry,.surprise,.fear,.love,.neutral]
        return (0..<24).map { i in
            // 造一些不同日期
            emotion_memory(title: "Memory \(i+1)",
                          date: .now.addingTimeInterval(Double(-i * 86_400)),
                          cover: nil,
                          emotion: es[i % es.count])
        }
    }()
    func items(for e: emotion) -> [emotion_memory] { all.filter { $0.emotion == e } }
}
