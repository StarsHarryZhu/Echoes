//
//  Emotion.swift
//  Echoes
//

import SwiftUI

/// Echoes 归档使用的七种表情。
///
/// `rawValue` 必须与 `EmotionClassifier.mlpackage` 的类标签逐字对应
/// （模型输出为小写：angry / disgust / fear / happy / neutral / sad / surprise）。
/// 这条约束由 `EmotionMappingTests` 守着，模型换版本后不会静默错位。
///
/// 标为 `nonisolated` 是因为本工程开启了 `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`，
/// 纯值类型默认也会被隔离到 MainActor，而它需要能在 `EmotionAnalyzer` 这个
/// 独立 actor 里自由使用。
nonisolated enum Emotion: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case angry = "Angry"
    case disgust = "Disgust"
    case fear = "Fear"
    case happy = "Happy"
    case neutral = "Neutral"
    case sad = "Sad"
    case surprise = "Surprise"

    var id: String { rawValue }

    /// 把 CoreML 输出的类标签映射回 `Emotion`。
    ///
    /// 大小写无关，前后空白会被忽略；无法识别时返回 `nil`，
    /// 由调用方决定降级策略（当前为 `.neutral`）。
    init?(modelLabel: String) {
        let normalized = modelLabel
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard let match = Emotion.allCases.first(where: {
            $0.rawValue.lowercased() == normalized
        }) else {
            return nil
        }

        self = match
    }

    /// 展示名。目前与 `rawValue` 一致，单独留出是为了将来接本地化。
    var displayName: String { rawValue }

    /// SF Symbol 名称。
    var symbol: String {
        switch self {
        case .angry: return "flame.fill"
        case .disgust: return "leaf.fill"
        case .fear: return "exclamationmark.triangle.fill"
        case .happy: return "sun.max.fill"
        case .neutral: return "circle.fill"
        case .sad: return "cloud.rain.fill"
        case .surprise: return "sparkles"
        }
    }

    /// 归档卡片与标签使用的主色。
    var tint: Color {
        switch self {
        case .angry: return .red
        case .disgust: return .green
        case .fear: return .orange
        case .happy: return .yellow
        case .neutral: return .gray
        case .sad: return .blue
        case .surprise: return .purple
        }
    }

    /// 表情归档页的固定展示顺序，不依赖 `allCases` 的声明顺序。
    var sortIndex: Int {
        switch self {
        case .happy: return 0
        case .neutral: return 1
        case .surprise: return 2
        case .sad: return 3
        case .angry: return 4
        case .fear: return 5
        case .disgust: return 6
        }
    }

    /// 按 `sortIndex` 排好序的全部表情。
    static var displayOrder: [Emotion] {
        allCases.sorted { $0.sortIndex < $1.sortIndex }
    }
}

// MARK: - 置信度

nonisolated extension Emotion {
    /// 低于该置信度时只做提示，但仍然归档 —— 表情识别本身是概率性的，
    /// 丢掉结果比留一个"不太确定"的结果更糟。
    static let lowConfidenceThreshold: Float = 0.25
}

nonisolated extension Float {
    /// 该置信度是否低到需要在界面上提醒用户。
    var isLowEmotionConfidence: Bool {
        self < Emotion.lowConfidenceThreshold
    }
}
