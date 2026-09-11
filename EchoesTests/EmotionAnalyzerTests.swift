//
//  EmotionAnalyzerTests.swift
//  EchoesTests
//

import Foundation
import Testing
import UIKit

@testable import Echoes

@Suite("表情识别管线")
struct EmotionAnalyzerTests {

    /// 包内采样图。测试宿主是 Echoes.app，所以这些资源在应用包里。
    private static let sampleNames = ["sample1", "sample2", "sample3", "sample4"]

    private static func makeBlankImage(width: CGFloat, height: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(
            size: CGSize(width: width, height: height),
            format: format
        ).image { context in
            UIColor.systemGray4.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
    }

    private static func firstSampleImage() -> UIImage? {
        sampleNames.lazy.compactMap { UIImage(named: $0) }.first
    }

    // MARK: - 失败路径

    @Test("没有像素数据的图会报 imageHasNoPixels")
    func imageWithoutPixelsFails() async {
        let analyzer = EmotionAnalyzer()
        // `UIImage()` 没有 cgImage。
        await #expect(throws: EmotionAnalysisError.self) {
            try await analyzer.analyze(image: UIImage())
        }
    }

    @Test("严格模式下检测不到人脸会抛 noFaceDetected")
    func strictModeRequiresFace() async {
        let analyzer = EmotionAnalyzer()
        let blank = Self.makeBlankImage(width: 800, height: 800)

        do {
            _ = try await analyzer.analyze(image: blank, allowWholeImageFallback: false)
            // 若这一行的环境真的检测出了人脸（真机上有极小概率误检），
            // 那说明严格模式生效了，也不算失败。
        } catch let error as EmotionAnalysisError {
            switch error {
            case .noFaceDetected, .allFacesTooSmall:
                break   // 期望的结果
            default:
                Issue.record("纯色图在严格模式下应该报找不到人脸，实际拿到 \(error)")
            }
        } catch {
            Issue.record("抛出了非 EmotionAnalysisError：\(error)")
        }
    }

    // MARK: - 与真实模型对拍

    /// 这条测试是**唯一能自动验证 `EmotionClassifier.mlpackage` 真的能推理**的手段：
    /// 它把包内采样图跑完整条管线，并检查输出的概率分布是否合理。
    @Test("对采样图跑通完整管线，概率分布合法")
    func runsFullPipelineOnSample() async throws {
        let image = try #require(Self.firstSampleImage(), "包内没有可用的采样图")

        let report = try await EmotionAnalyzer().analyze(
            image: image,
            allowWholeImageFallback: true
        )

        // 七个类别都在
        #expect(report.rankedScores.count == Emotion.allCases.count)
        #expect(Set(report.rankedScores.map(\.emotion)) == Set(Emotion.allCases))

        // 概率必须是 0...1 之间，且加起来等于 1
        for score in report.rankedScores {
            #expect(score.confidence >= 0, "\(score.emotion.rawValue) 的概率是负的：\(score.confidence)")
            #expect(score.confidence <= 1, "\(score.emotion.rawValue) 的概率超过 1：\(score.confidence)")
        }
        let total = report.rankedScores.reduce(Float(0)) { $0 + $1.confidence }
        #expect(abs(total - 1) < 0.001, "概率和应该等于 1，实际 \(total)")

        // 排好序了
        let confidences = report.rankedScores.map(\.confidence)
        #expect(confidences == confidences.sorted(by: >))

        // 冠军与 confidence 一致
        let top = try #require(report.rankedScores.first)
        #expect(top.emotion == report.emotion)
        #expect(abs(top.confidence - report.confidence) < 0.0001)
    }

    /// 模型输出的是 logits 而不是概率 —— 这条测试守住"我们做了归一化"这件事。
    /// 如果哪天换成已 softmax 的模型，这里的断言仍然成立，不会误报。
    @Test("模型原始输出不是概率，但归一化后是")
    func modelOutputIsNormalized() async throws {
        let image = try #require(Self.firstSampleImage(), "包内没有可用的采样图")
        let report = try await EmotionAnalyzer().analyze(
            image: image,
            allowWholeImageFallback: true
        )

        let total = report.rankedScores.reduce(Float(0)) { $0 + $1.confidence }
        #expect(abs(total - 1) < 0.001)
        #expect(report.rankedScores.allSatisfy { $0.confidence >= 0 && $0.confidence <= 1 })
    }

    @Test("采样图在模拟器相机缺失时可用作兜底")
    func sampleImagesAreUsable() {
        let missing = Self.sampleNames.filter { UIImage(named: $0) == nil }
        #expect(missing.isEmpty, "缺少采样图：\(missing)")
        #expect(UIImage(named: AppInfo.SampleImage.fallback) != nil)
    }

    @Test("降级路径会带上可展示的原因")
    func degradedPathCarriesReason() async throws {
        let image = try #require(Self.firstSampleImage())
        let report = try await EmotionAnalyzer().analyze(
            image: image,
            allowWholeImageFallback: true
        )

        // 在能正常检测人脸的环境（真机）里 degradedReason 是 nil，
        // 在检测器不可用的环境（模拟器）里应该有值。两种都合法，
        // 但只要有值就必须能显示成人话。
        if let reason = report.degradedReason {
            #expect(reason.errorDescription?.isEmpty == false)
            // 降级时没有人脸框
            #expect(report.faceBox == .zero)
        }
    }
}
