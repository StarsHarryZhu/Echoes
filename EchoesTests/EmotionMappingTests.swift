//
//  EmotionMappingTests.swift
//  EchoesTests
//

import Foundation
import Testing

@testable import Echoes

@Suite("表情与模型标签的映射")
struct EmotionMappingTests {

    /// 模型实际输出的类标签（取自 `EmotionClassifier.mlpackage`：全小写）。
    ///
    /// 这条清单是**契约**：模型换版本时若标签变了，这里会立刻失败，
    /// 而不是等到用户发现所有照片都被判成 Neutral。
    private static let modelLabels = [
        "angry", "disgust", "fear", "happy", "neutral", "sad", "surprise",
    ]

    @Test("模型的每个标签都能映射到 Emotion")
    func everyModelLabelMaps() {
        for label in Self.modelLabels {
            #expect(Emotion(modelLabel: label) != nil, "标签 '\(label)' 没有对应的 Emotion")
        }
    }

    @Test("模型标签数量与 Emotion 数量一致")
    func countsMatch() {
        #expect(Self.modelLabels.count == Emotion.allCases.count)
    }

    @Test("模型标签与 Emotion 一一对应，没有重复或缺失")
    func oneToOne() {
        let mapped = Self.modelLabels.compactMap { Emotion(modelLabel: $0) }
        #expect(Set(mapped).count == Emotion.allCases.count)

        // 反过来：每个 case 都必须能被某个模型标签命中。
        for emotion in Emotion.allCases {
            #expect(
                Self.modelLabels.contains { Emotion(modelLabel: $0) == emotion },
                "\(emotion.rawValue) 没有对应的模型标签"
            )
        }
    }

    @Test("大小写与前后空白不敏感", arguments: [
        "HAPPY", "Happy", "  happy  ", "hApPy", "\thappy\n",
    ])
    func caseAndWhitespaceInsensitive(label: String) {
        #expect(Emotion(modelLabel: label) == .happy)
    }

    @Test("无法识别的标签返回 nil", arguments: [
        "", "  ", "contempt", "happiness", "fearful", "快乐", "angryy",
    ])
    func unknownLabelsReturnNil(label: String) {
        #expect(Emotion(modelLabel: label) == nil)
    }

    @Test("rawValue 与模型标签只在大小写上不同")
    func rawValueMatchesModelSpelling() {
        for emotion in Emotion.allCases {
            #expect(
                Self.modelLabels.contains(emotion.rawValue.lowercased()),
                "\(emotion.rawValue) 的 rawValue 与模型标签不一致"
            )
        }
    }

    @Test("displayOrder 覆盖全部表情且无重复")
    func displayOrderIsComplete() {
        let order = Emotion.displayOrder
        #expect(order.count == Emotion.allCases.count)
        #expect(Set(order) == Set(Emotion.allCases))
    }
}

@Suite("置信度阈值")
struct ConfidenceTests {

    @Test("低于阈值算低置信")
    func belowThreshold() {
        #expect(Float(0.1).isLowEmotionConfidence)
        #expect(Float(0).isLowEmotionConfidence)
    }

    @Test("达到或高于阈值不算低置信")
    func atOrAboveThreshold() {
        #expect(!Emotion.lowConfidenceThreshold.isLowEmotionConfidence)
        #expect(!Float(0.9).isLowEmotionConfidence)
    }
}
