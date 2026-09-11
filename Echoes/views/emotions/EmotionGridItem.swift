//
//  EmotionGridItem.swift
//  Echoes
//

import SwiftUI

/// 表情归档总览里的一张分类卡片。
struct EmotionGridItem: View {

    var nameSize: CGFloat = 18
    let emotion: Emotion
    let count: Int

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [emotion.tint.opacity(0.9), emotion.tint.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 150)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(.white.opacity(0.18), lineWidth: 1)
                )
                .shadow(radius: 6, y: 3)

            countBadge
            nameRow
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(emotion.displayName)，\(count) 张")
    }

    private var countBadge: some View {
        Text("\(count)")
            .appText(13, weight: .bold)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }

    private var nameRow: some View {
        HStack(spacing: 10) {
            Image(systemName: emotion.symbol)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.white.opacity(0.95))
                .shadow(radius: 2)
            Text(emotion.displayName)
                .appText(nameSize, weight: .semibold)
                .foregroundStyle(.white)
        }
        .padding(12)
    }
}
