//
//  MemoryDetailView.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/9.
//

import SwiftUI

struct MemoryDetailView: View {
    var text_size: CGFloat = 14
    var date_size: CGFloat = 22
    let memory: emotion_memory

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(memory.emotion.tint.opacity(0.12))
                        .frame(height: 320)
                    cover_image(of: memory)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(.quaternary, lineWidth: 1)
                )
                .padding(.horizontal)

                // 日期：25/11/10
                Text(formattedDate(memory.date))
                    .modifier(text_style(size: date_size))
                    .bold()

                // 情绪标签：图标 + 名称
                HStack(spacing: 8) {
                    Image(systemName: memory.emotion.icon)
                        .foregroundStyle(memory.emotion.tint)
                    Text(memory.emotion.rawValue)
                        .modifier(text_style(size: text_size))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 24)
        }
        // ✅ 自定义导航标题：和 EmotionListView 一样（图标 + 自定义字体）
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    Image(systemName: memory.emotion.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(memory.emotion.tint)
                    Text(memory.emotion.rawValue)
                        .font(.custom(text_info.font, size: 22))
                        .bold()
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Helpers
    private func cover_image(of memory: emotion_memory) -> Image {
        if let n = memory.cover, UIImage(named: n) != nil {
            return Image(n)
        }
        return Image(systemName: "photo.on.rectangle.angled")
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yy/MM/dd" // 格式如：25/11/10
        return f.string(from: date)
    }
}
