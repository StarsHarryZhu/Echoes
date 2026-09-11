//
//  EmotionListView.swift
//  Echoes
//

import SwiftUI

/// 某个表情下的全部照片。
struct EmotionListView: View {

    @Environment(MemoryStore.self) private var store

    let emotion: Emotion
    let onSelect: (Memory) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    private var items: [Memory] {
        store.items(for: emotion)
    }

    var body: some View {
        Group {
            if items.isEmpty {
                emptyState
            } else {
                grid
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(emotion.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Image(systemName: emotion.symbol)
                        .foregroundStyle(emotion.tint)
                    Text(emotion.displayName)
                        .appText(20, weight: .semibold)
                }
            }
        }
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(items) { memory in
                    Button {
                        onSelect(memory)
                    } label: {
                        cell(memory)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
        }
    }

    private func cell(_ memory: Memory) -> some View {
        MemoryThumbnail(memory: memory)
            .frame(height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(alignment: .bottomLeading) {
                Text(DateFormatters.short.string(from: memory.capturedAt))
                    .appText(12, weight: .bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(.black.opacity(0.35), in: Capsule())
                    .padding(8)
            }
            .shadow(radius: 3, y: 2)
            .accessibilityLabel(
                L10n.memoryAccessibilityLabel(
                    date: DateFormatters.full.string(from: memory.capturedAt),
                    emotion: emotion.displayName
                )
            )
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label(L10n.emotionListEmptyTitle(emotion), systemImage: emotion.symbol)
        } description: {
            Text(L10n.emotionListEmptyMessage)
        }
    }
}
