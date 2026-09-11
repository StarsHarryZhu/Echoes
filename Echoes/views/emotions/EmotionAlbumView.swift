//
//  EmotionAlbumView.swift
//  Echoes
//

import SwiftUI

/// 按表情归档的总览页。
struct EmotionAlbumView: View {

    @Environment(MemoryStore.self) private var store

    let onSelect: (Emotion) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        Group {
            if store.isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = store.startupError {
                StartupErrorView(message: error)
            } else {
                grid
            }
        }
        .background(Color(.systemGroupedBackground))
        // 底部中间是悬浮快门键，列表末尾给它留出空间。
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 92) }
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Emotion.displayOrder) { emotion in
                    Button {
                        onSelect(emotion)
                    } label: {
                        EmotionGridItem(
                            emotion: emotion,
                            count: store.count(for: emotion)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
        }
    }
}
