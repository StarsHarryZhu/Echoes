//
//  Memory.swift
//  Echoes
//

import Foundation

/// 一条归档记录：一次拍照得到的照片、当时的表情判定、以及判定依据。
///
/// 存储位置约定：图片只存**文件名**，不存绝对路径。
/// 旧版本存的是 `Documents/<uuid>.jpg` 的绝对路径，而沙盒路径在重装 / 恢复备份后
/// 会变化，导致 `UIImage(named:)` 永远取不到图 —— 这是本次重构修掉的 bug 之一。
///
/// 标为 `nonisolated` 是因为本工程开启了 `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`，
/// 纯值类型默认也会被隔离到 MainActor，而它要在 `MemoryStore` 的后台任务里构造。
nonisolated struct Memory: Identifiable, Hashable, Codable, Sendable {

    let id: UUID
    /// 拍照时刻。
    let capturedAt: Date
    /// 原图文件名（相对于 `ImageStore` 的图片目录）。
    let filename: String
    /// 该图片文件的像素尺寸，用于避免列表布局时反复解码原图。
    var pixelSize: CGSize?
    /// 判定得到的表情。
    let emotion: Emotion
    /// `emotion` 的置信度，取值范围 0...1。
    let confidence: Float
    /// 模型输出的完整概率分布。旧记录可能为 nil。
    var scores: [Emotion: Float]?
    /// 缩略图文件名。旧记录可能为 nil，此时回退到原图。
    var thumbnailFilename: String?

    init(
        id: UUID = UUID(),
        capturedAt: Date = Date(),
        filename: String,
        pixelSize: CGSize? = nil,
        emotion: Emotion,
        confidence: Float,
        scores: [Emotion: Float]? = nil,
        thumbnailFilename: String? = nil
    ) {
        self.id = id
        self.capturedAt = capturedAt
        self.filename = filename
        self.pixelSize = pixelSize
        self.emotion = emotion
        self.confidence = confidence
        self.scores = scores
        self.thumbnailFilename = thumbnailFilename
    }
}

// MARK: - 向后兼容解码

nonisolated extension Memory {

    private enum CodingKeys: String, CodingKey {
        case id
        case capturedAt
        // 旧版本字段名
        case date
        case filename
        case cover
        case pixelSize
        case emotion
        case confidence
        case scores
        case thumbnailFilename
    }

    /// 手写解码器，保证旧版 `memories.json` 不会让整个归档读不出来。
    ///
    /// 能读的旧格式：
    /// - `date`（对应新的 `capturedAt`）
    /// - `cover`：`Documents/<uuid>.jpg` 的绝对路径 → 取最后一段作为文件名
    /// - 缺少 `confidence` / `scores` / `pixelSize` / `thumbnailFilename` → 给默认值
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)

        if let captured = try container.decodeIfPresent(Date.self, forKey: .capturedAt) {
            capturedAt = captured
        } else {
            capturedAt = try container.decode(Date.self, forKey: .date)
        }

        if let name = try container.decodeIfPresent(String.self, forKey: .filename) {
            // 防御：万一存进来的是完整路径，只取文件名
            filename = (name as NSString).lastPathComponent
        } else if let cover = try container.decodeIfPresent(String.self, forKey: .cover) {
            filename = (cover as NSString).lastPathComponent
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .filename,
                in: container,
                debugDescription: "记录既没有 filename 也没有 cover"
            )
        }

        let rawEmotion = try container.decode(String.self, forKey: .emotion)
        guard let parsed = Emotion(modelLabel: rawEmotion) else {
            throw DecodingError.dataCorruptedError(
                forKey: .emotion,
                in: container,
                debugDescription: "无法识别的表情：\(rawEmotion)"
            )
        }
        emotion = parsed

        confidence = try container.decodeIfPresent(Float.self, forKey: .confidence) ?? 0
        scores = try container.decodeIfPresent([Emotion: Float].self, forKey: .scores)
        pixelSize = try container.decodeIfPresent(CGSize.self, forKey: .pixelSize)
        thumbnailFilename = try container.decodeIfPresent(String.self, forKey: .thumbnailFilename)
    }

    /// 显式写出编码器，避免新旧字段名混用（例如同时写出 `date` 和 `capturedAt`）。
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(capturedAt, forKey: .capturedAt)
        try container.encode(filename, forKey: .filename)
        try container.encodeIfPresent(pixelSize, forKey: .pixelSize)
        try container.encode(emotion, forKey: .emotion)
        try container.encode(confidence, forKey: .confidence)
        try container.encodeIfPresent(scores, forKey: .scores)
        try container.encodeIfPresent(thumbnailFilename, forKey: .thumbnailFilename)
    }
}
