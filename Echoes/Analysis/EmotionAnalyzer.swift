//
//  EmotionAnalyzer.swift
//  Echoes
//

import CoreML
import Foundation
import ImageIO
import UIKit
import Vision

/// 表情识别失败的原因。每种情况在界面上给不同的提示。
enum EmotionAnalysisError: LocalizedError {
    case imageHasNoPixels
    case noFaceDetected
    case allFacesTooSmall
    case modelUnavailable(String)
    case inferenceFailed(String)

    var errorDescription: String? {
        switch self {
        case .imageHasNoPixels:
            return "这张照片读不出像素数据，换一张试试。"
        case .noFaceDetected:
            return "没有在照片里找到人脸。请正对前置相机、让脸部完整出现在取景框里再试一次。"
        case .allFacesTooSmall:
            return "照片里检测到的人脸太小，识别不准。靠近一点再拍一张。"
        case .modelUnavailable(let reason):
            return "表情识别模型加载失败：\(reason)"
        case .inferenceFailed(let reason):
            return "表情识别出错：\(reason)"
        }
    }
}

/// 表情识别服务：人脸检测 + 表情分类。
///
/// 用 iOS 27 的 Swift 原生 Vision API（`ImageRequestHandler` /
/// `DetectFaceRectanglesRequest` / `CoreMLRequest`）重写了重构前基于
/// `VNImageRequestHandler` + 回调闭包 + `try!` 的旧实现。
///
/// 重构前的三处硬伤：
/// 1. 把**整张照片**丢给一个 224×224 灰度人脸模型 —— 背景和身体占了大部分像素；
/// 2. 人脸检测的结果只用来判断"有没有脸"，没有送去裁剪；
/// 3. 模型加载用 `try!`，模型一旦出问题 App 直接崩。
actor EmotionAnalyzer {

    static let shared = EmotionAnalyzer()

    /// 人脸框外扩比例。原框通常紧贴脸颊，裁进太紧会切掉嘴角和眉毛，
    /// 而这两个部位正是表情分类最依赖的特征。
    private let faceExpansionFactor: CGFloat = 1.35

    /// 人脸框短边小于该比例（相对整图）就认为太小、识别不可靠。
    private let minimumFaceSide: CGFloat = 0.06

    /// 已加载的模型。惰性加载的结果缓存在这里 ——
    /// `EmotionClassifier` 由 CoreML 代码生成产生，而本工程设置了
    /// `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`，所以它隐式是 MainActor 隔离的，
    /// 不能在 actor 的 `init` 里构造，只能在 actor 隔离的方法里建。
    private var cachedContainer: Result<Vision.CoreMLModelContainer, EmotionAnalysisError>?

    // MARK: - 对外入口

    /// 分析一张照片，返回表情判定结果及其依据。
    ///
    /// - Parameter orientation: 照片的 EXIF 方向。前置相机拍出的图常带
    ///   `imageOrientation` / EXIF 不一致的情况，必须显式传入，否则人脸框会错位。
    func analyze(
        image: UIImage,
        orientation: CGImagePropertyOrientation = .up,
        allowWholeImageFallback: Bool? = nil
    ) async throws -> EmotionReport {
        guard let cgImage = image.cgImage else {
            throw EmotionAnalysisError.imageHasNoPixels
        }

        let container = try await loadModelContainer()
        let fallbackEnabled = allowWholeImageFallback ?? Self.faceDetectionFallbackEnabled

        // 人脸检测跑在整图上 —— 把整图缩到 224×224 再检测会让小脸消失。
        let handler = Vision.ImageRequestHandler(cgImage, orientation: orientation)
        let face = try await locateFace(cgImage, handler: handler)

        let region: Vision.NormalizedRect?
        if let face {
            guard min(face.boundingBox.width, face.boundingBox.height) >= minimumFaceSide else {
                // 脸太小，裁出来识别只会更糊。除非允许降级，否则直接报错。
                guard fallbackEnabled else {
                    throw EmotionAnalysisError.allFacesTooSmall
                }
                return try await classifyWithFallback(
                    handler: handler,
                    container: container,
                    reason: .allFacesTooSmall
                )
            }
            // 只把脸那一块送去分类。`regionOfInterest` 是相对整图的归一化矩形，
            // 裁剪 + 缩放到模型要求的 224×224 灰度输入由 Vision 完成
            // （见 EmotionClassifier 的 inputSpec）。
            region = expandedRegion(around: face.boundingBox, by: faceExpansionFactor)
        } else if fallbackEnabled {
            return try await classifyWithFallback(
                handler: handler,
                container: container,
                reason: .noFaceDetected
            )
        } else {
            throw EmotionAnalysisError.noFaceDetected
        }

        return try await classify(
            handler: handler,
            container: container,
            region: region,
            faceBox: face?.boundingBox.cgRect,
            degradedReason: nil
        )
    }

    // MARK: - 步骤

    /// 找人脸。
    ///
    /// `nil` 表示"没能检测"（没有人脸，或这个人脸检测在**当前环境**跑不起来）。
    /// 目前已知模拟器上 `DetectFaceRectanglesRequest` 会失败并返回
    /// `internalError("Could not create inference context")` —— 视觉模型的推理后端
    /// 在模拟器里建不起来。注意这与我们的表情模型无关：`CoreMLRequest` 跑
    /// `EmotionClassifier` 在模拟器上是正常的。真机上人脸检测可用。
    private func locateFace(
        _ cgImage: CGImage,
        handler: Vision.ImageRequestHandler
    ) async throws -> Vision.FaceObservation? {
        do {
            let faces = try await handler.perform(Vision.DetectFaceRectanglesRequest())
            return largestFace(in: faces)
        } catch {
            // 检测器本身不可用，不是"照片里没有脸"。
            return nil
        }
    }

    /// 降级路径：整幅图直接送分类。
    ///
    /// 相比裁剪人脸，整图识别会让背景和身体占掉大量像素，准确率更低 ——
    /// 但比什么都给不出来强。是否启用由设置里的开关决定。
    private func classifyWithFallback(
        handler: Vision.ImageRequestHandler,
        container: Vision.CoreMLModelContainer,
        reason: EmotionAnalysisError
    ) async throws -> EmotionReport {
        try await classify(
            handler: handler,
            container: container,
            region: nil,
            faceBox: nil,
            degradedReason: reason
        )
    }

    private func classify(
        handler: Vision.ImageRequestHandler,
        container: Vision.CoreMLModelContainer,
        region: Vision.NormalizedRect?,
        faceBox: CGRect?,
        degradedReason: EmotionAnalysisError?
    ) async throws -> EmotionReport {
        var request = Vision.CoreMLRequest(model: container)
        request.cropAndScaleAction = .scaleToFill
        if let region {
            request.regionOfInterest = region
        }

        let observations: [any Vision.VisionObservation]
        do {
            observations = try await handler.perform(request)
        } catch {
            throw EmotionAnalysisError.inferenceFailed(error.localizedDescription)
        }

        let classifications = observations.compactMap { $0 as? Vision.ClassificationObservation }
        guard !classifications.isEmpty else {
            throw EmotionAnalysisError.inferenceFailed("模型没有返回任何分类结果")
        }

        // 模型输出的是**未归一化的 logits**（实测某个类别的值是 -2.08），
        // 直接当概率用会让百分比条显示负数、总和也不为 1。这里做一次 softmax。
        var emotionByLabel: [Emotion: Float] = [:]
        for observation in classifications {
            guard let emotion = Emotion(modelLabel: observation.identifier) else { continue }
            emotionByLabel[emotion] = max(emotionByLabel[emotion] ?? -.greatestFiniteMagnitude,
                                          observation.confidence)
        }
        let probabilities = Self.softmax(emotionByLabel)
        guard !probabilities.isEmpty else {
            throw EmotionAnalysisError.inferenceFailed("模型的输出里没有可识别的表情标签")
        }

        // 七个类别全部保留。未出现在结果里的补 0，保证详情页永远画得出完整的概率条。
        var scores: [Emotion: Float] = [:]
        for emotion in Emotion.allCases {
            scores[emotion] = probabilities[emotion] ?? 0
        }

        let top = probabilities.max { $0.value < $1.value }
        let emotion = top?.key ?? .neutral
        let confidence = top?.value ?? 0

        return EmotionReport(
            emotion: emotion,
            confidence: confidence,
            rankedScores: rank(scores: scores),
            faceBox: faceBox ?? .zero,
            degradedReason: degradedReason
        )
    }

    /// 把任意实数值的分数归一化成加起来等于 1 的概率。
    ///
    /// 用数值稳定的写法：先减去最大值再取指数，避免 `exp` 溢出。
    private static func softmax(_ values: [Emotion: Float]) -> [Emotion: Float] {
        guard let maxValue = values.values.max(), maxValue.isFinite else { return [:] }

        var exponentials: [Emotion: Float] = [:]
        var total: Float = 0
        for (emotion, value) in values where value.isFinite {
            let exponential = expf(value - maxValue)
            exponentials[emotion] = exponential
            total += exponential
        }
        guard total > 0 else { return [:] }

        return exponentials.mapValues { $0 / total }
    }

    /// 是否允许在检测不到人脸时退回整图识别。
    nonisolated static var faceDetectionFallbackEnabled: Bool {
        // 默认开：宁可给一个"不保证准"的结果，也好过告诉用户"识别不了"。
        // 用户可以在设置里关掉，改用严格模式。
        if UserDefaults.standard.object(forKey: AppPreferenceKey.faceDetectionFallback) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: AppPreferenceKey.faceDetectionFallback)
    }

    // MARK: - 模型加载

    /// 在主线程上一次性装上模型。
    ///
    /// 生成的 `EmotionClassifier` 隐式继承本工程的 `MainActor` 默认隔离，
    /// 只能在主 actor 上构造；构造完把 `MLModel`（`@unchecked Sendable`）
    /// 取回 actor 内部使用。Vision 会自动绑定模型唯一的图像输入，
    /// 无需手工设置 `inputImageFeatureName`。
    private func loadModelContainer() async throws -> Vision.CoreMLModelContainer {
        if let cached = cachedContainer {
            return try cached.get()
        }

        let loaded: Result<MLModel, EmotionAnalysisError> = await MainActor.run {
            do {
                return .success(try EmotionClassifier(configuration: MLModelConfiguration()).model)
            } catch {
                return .failure(.modelUnavailable(error.localizedDescription))
            }
        }

        let result: Result<Vision.CoreMLModelContainer, EmotionAnalysisError>
        switch loaded {
        case .success(let model):
            do {
                result = .success(try Vision.CoreMLModelContainer(model: model))
            } catch {
                result = .failure(.modelUnavailable(error.localizedDescription))
            }
        case .failure(let error):
            result = .failure(error)
        }

        cachedContainer = result
        return try result.get()
    }

    // MARK: - 辅助

    /// 把七个类别的概率按置信度降序排好，同分时按 `sortIndex` 稳定排序。
    ///
    /// 单独拆出来是因为写成一个链式闭包时，Swift 类型检查器会超时
    /// （"unable to type-check this expression in reasonable time"）。
    private func rank(scores: [Emotion: Float]) -> [EmotionReport.Score] {
        var ranked: [EmotionReport.Score] = []
        ranked.reserveCapacity(Emotion.allCases.count)
        for emotion in Emotion.allCases {
            let value: Float = scores[emotion] ?? 0
            ranked.append(EmotionReport.Score(emotion: emotion, confidence: value))
        }
        ranked.sort { lhs, rhs in
            if lhs.confidence == rhs.confidence {
                return lhs.emotion.sortIndex < rhs.emotion.sortIndex
            }
            return lhs.confidence > rhs.confidence
        }
        return ranked
    }

    /// 取面积最大的那张脸 —— 自拍场景下通常就是用户本人。
    private func largestFace(in faces: [Vision.FaceObservation]) -> Vision.FaceObservation? {
        var best: Vision.FaceObservation?
        var bestArea: CGFloat = 0
        for face in faces {
            let area = face.boundingBox.width * face.boundingBox.height
            if area > bestArea {
                bestArea = area
                best = face
            }
        }
        return best
    }

    /// 以 `box` 为中心按 `factor` 外扩，并夹回单位矩形内。
    private func expandedRegion(
        around box: Vision.NormalizedRect,
        by factor: CGFloat
    ) -> Vision.NormalizedRect {
        let rect = box.cgRect
        let width = min(rect.width * factor, 1)
        let height = min(rect.height * factor, 1)
        let midX = rect.midX
        let midY = rect.midY

        var originX = midX - width / 2
        var originY = midY - height / 2
        originX = min(max(originX, 0), 1 - width)
        originY = min(max(originY, 0), 1 - height)

        return Vision.NormalizedRect(
            x: originX,
            y: originY,
            width: width,
            height: height
        )
    }
}
