//
//  EmotionGridItem.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/9.
//

import SwiftUI

struct EmotionGridItem: View {
    var name_size: CGFloat = 18
    var count_size: CGFloat = 8
    let emotion: emotion
    let count: Int

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(LinearGradient(colors: [emotion.tint.opacity(0.9), emotion.tint.opacity(0.5)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(height: 150)
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(.white.opacity(0.18), lineWidth: 1))
                .shadow(radius: 6, y: 3)

            // 白色数字徽章
            Text("\(count)")
//                .font(.caption).bold()
                .modifier(text_style(
                    size: name_size,
                ))
                .foregroundColor(.white)
                .padding(.horizontal, 8).padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

            HStack(spacing: 10) {
                Image(systemName: emotion.icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.95))
                    .shadow(radius: 2)
                Text(emotion.rawValue)
                    .modifier(text_style(
                        size: name_size,
                    ))
                    .foregroundStyle(.white)
            }
            .padding(12)
        }
    }
}

//#Preview {
//    EmotionGridItem()
//}
