//
//  EmotionScoreBars.swift
//  Echoes
//

import SwiftUI

/// 七种表情的置信度分布。
///
/// 模型的完整概率分布原先被直接丢弃，只留了一个表情名。把这些画出来，
/// 用户才能理解"为什么判成这个表情"。
struct EmotionScoreBars: View {

    let scores: [EmotionReport.Score]
    /// 高亮这一项（冠军）。
    let highlight: Emotion

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.memoryEvidence)
                .appText(13, weight: .semibold)
                .foregroundStyle(.secondary)

            ForEach(scores) { score in
                row(score)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .accessibilityElement(children: .contain)
    }

    private func row(_ score: EmotionReport.Score) -> some View {
        let isHighlighted = score.emotion == highlight

        return HStack(spacing: 10) {
            Image(systemName: score.emotion.symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(score.emotion.tint)
                .frame(width: 16)

            Text(score.emotion.displayName)
                .appText(14)
                .fontWeight(isHighlighted ? .semibold : .regular)
                .frame(width: 78, alignment: .leading)

            GeometryReader { proxy in
                let width = proxy.size.width
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.tertiarySystemFill))
                    Capsule()
                        .fill(score.emotion.tint.opacity(isHighlighted ? 1 : 0.55))
                        .frame(width: max(2, width * CGFloat(min(max(score.confidence, 0), 1))))
                }
            }
            .frame(height: 8)

            Text(percent(score.confidence))
                .appText(12)
                .foregroundStyle(.secondary)
                .frame(width: 38, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(score.emotion.displayName) \(percent(score.confidence))")
    }
}
