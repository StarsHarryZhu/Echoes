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

        let decodedScores = try Self.decodeScores(from: container)
        scores = decodedScores
        // 旧记录没有 confidence：能从事后算出来的概率分布里补一个，否则记 0。
        confidence = try container.decodeIfPresent(Float.self, forKey: .confidence)
            ?? decodedScores?.values.max()
            ?? 0
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
        try Self.encodeScores(scores, into: &container)
        try container.encodeIfPresent(thumbnailFilename, forKey: .thumbnailFilename)
    }

    /// 概率分布编码成 `{"Happy": 0.9, ...}` 这样的**对象**。
    ///
    /// 直接 `encode([Emotion: Float])` 的话，因为 `Emotion` 不是 `String`/`Int`，
    /// Swift 会退化成扁平的交错数组（`["Happy", 0.9, "Sad", 0.1, …]`）——
    /// 能读回来，但人不可读、别的工具也解析不了。
    private static func encodeScores(
        _ scores: [Emotion: Float]?,
        into container: inout KeyedEncodingContainer<CodingKeys>
    ) throws {
        guard let scores else { return }
        let keyed = scores.reduce(into: [String: Float]()) { result, pair in
            result[pair.key.rawValue] = pair.value
        }
        try container.encode(keyed, forKey: .scores)
    }

    /// 解码概率分布。先探测 `scores` 的容器类型，再按对应格式解析。
    ///
    /// 不能用 `try? decodeIfPresent([String: Float].self, ...)` 去"猜"格式：
    /// 类型不匹配的失败和"字段根本不存在"都会变成 nil，分不清该走哪条路 ——
    /// 第一版就是这么写的，结果旧的扁平数组被静默丢成 nil。
    private static func decodeScores(
        from container: KeyedDecodingContainer<CodingKeys>
    ) throws -> [Emotion: Float]? {
        guard container.contains(.scores), try !container.decodeNil(forKey: .scores) else {
            return nil
        }

        var scores: [Emotion: Float] = [:]

        if let keyed = try? container.nestedContainer(keyedBy: AnyCodingKey.self, forKey: .scores) {
            // 新格式：{ "Happy": 0.9, "Sad": 0.1 }
            for key in keyed.allKeys {
                guard let emotion = Emotion(modelLabel: key.stringValue),
                      let value = try? keyed.decode(Float.self, forKey: key) else {
                    continue
                }
                scores[emotion] = value
            }
        } else if var flat = try? container.nestedUnkeyedContainer(forKey: .scores) {
            // 早期格式：["Happy", 0.9, "Sad", 0.1]
            while !flat.isAtEnd {
                guard let label = try? flat.decode(String.self),
                      let value = try? flat.decode(Float.self),
                      let emotion = Emotion(modelLabel: label) else {
                    break
                }
                scores[emotion] = value
            }
        }

        return scores.isEmpty ? nil : scores
    }
}

/// 解码概率分布时用的通用键 —— 键来自 `Emotion.rawValue`，编译期未知。
private nonisolated struct AnyCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}
