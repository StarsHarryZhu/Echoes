//
//  EmotionsView.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/7.
//

import SwiftUI
import Combine

struct EmotionsView: View {
    @StateObject private var vm = emotions_view_model()
    private let cols = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: cols, spacing: 12) {
                    ForEach(emotion.allCases) { emo in
                        let count = vm.items(for: emo).count
                        NavigationLink(value: emo) {
                            EmotionGridItem(emotion: emo, count: count)   // 右上角仅数字徽章（白色）
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)
            }
            .navigationTitle("Emotion Album")
            .navigationDestination(for: emotion.self) { emo in
                EmotionListView(emotion: emo, items: vm.items(for: emo))
            }
            .navigationDestination(for: emotion_memory.self) { m in
                MemoryDetailView(memory: m)
            }
        }
    }
}

#Preview {
    EmotionsView()
}
