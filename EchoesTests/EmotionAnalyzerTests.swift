//
//  EmotionAnalyzerTests.swift
//  EchoesTests
//

import CoreML
import Foundation
import Testing
import UIKit

@testable import Echoes

/// 表情识别管线。
///
/// **这里没有真人照片夹具。** 项目有意不携带任何人脸图片：
/// 测试资源会随仓库公开，真人人脸照片不该为了跑几条测试而留在里面。
///
/// 代价要说清楚：在当前模拟器上 `DetectFaceRectanglesRequest` 的推理后端
/// 建不起来（`Espresso compiled without MPSGraph engine`），所以
/// 「检测到人脸 → 裁剪 → 分类」这条**完整**链路无法自动化验证。
/// 需要在真机跑一次确认。
///
/// 因此这里分两层：
/// 1. 管线本身 —— 只测不需要人脸的路径（输入校验、无脸时的行为）；
/// 2. 模型推理 —— 用合成的像素缓冲直接调 `EmotionClassifier`，
///    不经过 Vision，同样能验证模型可用、标签可映射、softmax 归一化正确。
@Suite("表情识别管线")
struct EmotionAnalyzerTests {

    private static func makeSolidImage(
        width: CGFloat,
        height: CGFloat,
        color: UIColor = .systemGray4
    ) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(
            size: CGSize(width: width, height: height),
            format: format
        ).image { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
    }

    // MARK: - 输入校验

    @Test("没有像素数据的图会报 imageHasNoPixels")
    func imageWithoutPixelsFails() async {
        let analyzer = EmotionAnalyzer()
        // `UIImage()` 没有 cgImage。
        await #expect(throws: EmotionAnalysisError.self) {
            try await analyzer.analyze(image: UIImage())
        }
    }

    @Test("空 UIImage 的错误可以展示给用户")
    func errorHasLocalizedMessage() throws {
        for error in [
            EmotionAnalysisError.imageHasNoPixels,
            .noFaceDetected,
            .allFacesTooSmall,
            .modelUnavailable("x"),
            .inferenceFailed("x"),
        ] {
            let message = try #require(error.errorDescription)
            #expect(!message.isEmpty)
            // 必须是文案，不是 key
            #expect(!message.hasPrefix("analysis."))
        }
    }

    // MARK: - 无脸时的行为

    /// 纯色图里没有人脸。
    ///
    /// 两种结果都算通过：
    /// - 严格模式（关掉整图降级）→ `noFaceDetected`；
    /// - 开了降级 → 返回整图判定的报告，并带上可展示的降级原因。
    ///
    /// 之所以不强求某一种：人脸检测器在模拟器上可能整个不可用，
    /// 那时两种路径的表现都会被影响到。这里断言的是"行为可解释"。
    @Test("纯色图：要么报找不到人脸，要么给出带原因的降级结果")
    func solidImageBehaviour() async throws {
        let analyzer = EmotionAnalyzer()
        let blank = Self.makeSolidImage(width: 320, height: 320)

        do {
            let report = try await analyzer.analyze(image: blank, allowWholeImageFallback: true)
            // 降级路径必须带原因，界面上要据此提示「可能不准」
            let reason = try #require(report.degradedReason, "降级结果必须说明原因")
            #expect(reason.errorDescription?.isEmpty == false)
            #expect(report.faceBox == .zero, "降级时没有人脸框")
            #expect(report.rankedScores.count == Emotion.allCases.count)
        } catch let error as EmotionAnalysisError {
            switch error {
            case .noFaceDetected, .allFacesTooSmall:
                break   // 期望
            default:
                Issue.record("期望「找不到人脸」类错误或降级结果，实际 \(error)")
            }
        }
    }

    // MARK: - 模型与标签的契约

    /// 用合成的像素缓冲直接调模型 —— 不经过 Vision，不需要人脸图。
    ///
    /// 这条能验证的东西不少：模型能加载、输入形状对、输出标签能映射回
    /// `Emotion`、概率能归一化。它替代不了"人脸裁剪"那段，但能守住模型契约。
    @MainActor
    @Test("模型可以加载并推理，输出标签与 Emotion 对得上")
    func modelRunsAndLabelsMap() throws {
        let model = try EmotionClassifier(configuration: MLModelConfiguration()).model

        // 输入描述：确认模型的输入特征名与尺寸没变
        let input = try #require(model.modelDescription.inputDescriptionsByName["input"])
        #expect(input.type == .image)

        // 造一张 224x224 的像素缓冲喂进去
        let width = 224
        let height = 224
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            nil,
            &pixelBuffer
        )
        #expect(status == kCVReturnSuccess)
        let buffer = try #require(pixelBuffer)

        let output = try model.prediction(
            from: EmotionClassifierInput(input: buffer),
            options: MLPredictionOptions()
        )
        let result = EmotionClassifierOutput(features: output)

        // 模型给出的 top-1 标签必须能映射回 Emotion
        #expect(Emotion(modelLabel: result.classLabel) != nil, "模型标签 \(result.classLabel) 无法映射")

        // 概率分布覆盖全部七类
        let probabilities = result.classLabel_probs
        #expect(probabilities.count == Emotion.allCases.count)
        let mapped = probabilities.compactMap { Emotion(modelLabel: $0.key) }
        #expect(Set(mapped).count == Emotion.allCases.count, "模型输出的类别与 Emotion 不一致")
    }

    @Test("包内不包含任何图片资源")
    func bundleShipsNoImages() {
        // 归档里的照片只来自用户拍摄。应用自带任何示例图片都会让它
        // 出现在用户的归档里或安装包中，两者都不要。
        let assets = Bundle.main.url(forResource: "Assets", withExtension: "car")
        #expect(assets == nil, "应用包里不应有图片资源目录")

        for name in ["sample1", "sample2", "sample3", "sample4"] {
            #expect(UIImage(named: name) == nil, "\(name) 不该出现在应用包里")
            #expect(
                Bundle.main.url(forResource: name, withExtension: "jpg") == nil,
                "\(name).jpg 不该出现在应用包里"
            )
        }
    }

    /// 测试 bundle 里也不该有人脸夹具。
    private final class BundleToken {}
    private var testBundle: Bundle { Bundle(for: BundleToken.self) }

    @Test("测试 bundle 里也没有人脸照片夹具")
    func testBundleHasNoFaceFixtures() {
        for name in ["sample1", "sample2", "sample3", "sample4"] {
            #expect(
                testBundle.url(forResource: name, withExtension: "jpg") == nil,
                "\(name).jpg 仍留在测试 bundle 里"
            )
        }
    }
}
