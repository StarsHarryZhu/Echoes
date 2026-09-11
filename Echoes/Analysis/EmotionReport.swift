//
//  EmotionReport.swift
//  Echoes
//

import Foundation

/// 一次表情识别的完整结果。
///
/// 重构前 `emotion_detect(from:)` 只返回一个表情字符串，把模型给出的概率分布、
/// 置信度和人脸位置全部丢掉了。这些信息对用户看「为什么判成这个表情」很重要，
/// 所以在这里一并保留。
nonisolated struct EmotionReport: Sendable, Hashable {

    /// 判定得到的表情。
    let emotion: Emotion
    /// 该表情的置信度，0...1。
    let confidence: Float
    /// 模型输出的完整概率分布，已按置信度降序排列，总和为 1。
    let rankedScores: [Score]
    /// 判定所依据的人脸在**归一化图像坐标系**中的位置（原点左下）。
    /// 走了整图降级路径时为 `.zero`。
    let faceBox: CGRect
    /// 非 `nil` 表示这次判定走了降级路径（没能按人脸裁剪）。
    /// 界面上要据此提示用户结果可能不准。
    var degradedReason: EmotionAnalysisError?

    nonisolated struct Score: Sendable, Hashable, Identifiable {
        let emotion: Emotion
        let confidence: Float

        var id: String { emotion.rawValue }
    }

    /// 置信度是否低到需要在界面上提醒用户。
    var isLowConfidence: Bool { confidence.isLowEmotionConfidence }

    /// 除冠军之外最有可能的候选，用于详情页展示「次选」。
    var runnerUp: Score? {
        rankedScores.dropFirst().first
    }
}

// MARK: - Hashable

nonisolated extension EmotionReport {

    static func == (lhs: EmotionReport, rhs: EmotionReport) -> Bool {
        lhs.emotion == rhs.emotion
            && lhs.confidence == rhs.confidence
            && lhs.rankedScores == rhs.rankedScores
            && lhs.faceBox == rhs.faceBox
            && lhs.degradedReason == rhs.degradedReason
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(emotion)
        hasher.combine(confidence)
        hasher.combine(rankedScores)
        hasher.combine(faceBox)
        hasher.combine(degradedReason?.errorDescription)
    }
}

// MARK: - 失败原因的比较

nonisolated extension EmotionAnalysisError: Equatable {

    static func == (lhs: EmotionAnalysisError, rhs: EmotionAnalysisError) -> Bool {
        switch (lhs, rhs) {
        case (.imageHasNoPixels, .imageHasNoPixels),
             (.noFaceDetected, .noFaceDetected),
             (.allFacesTooSmall, .allFacesTooSmall):
            return true
        case (.modelUnavailable(let l), .modelUnavailable(let r)),
             (.inferenceFailed(let l), .inferenceFailed(let r)):
            return l == r
        default:
            return false
        }
    }
}
