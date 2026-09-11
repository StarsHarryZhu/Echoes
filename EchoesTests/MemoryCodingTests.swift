//
//  MemoryCodingTests.swift
//  EchoesTests
//

import Foundation
import Testing

@testable import Echoes

@Suite("Memory 的编解码与向后兼容")
struct MemoryCodingTests {

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    /// 固定时间点，避免测试结果随运行时刻变化。
    private static let fixedDate = Date(timeIntervalSince1970: 1_787_000_000)

    @Test("新格式可以完整往返")
    func roundTrip() throws {
        let original = Memory(
            id: UUID(),
            capturedAt: Self.fixedDate,
            filename: "ABC.jpg",
            pixelSize: CGSize(width: 2048, height: 1536),
            emotion: .surprise,
            confidence: 0.87,
            scores: [.surprise: 0.87, .happy: 0.09, .neutral: 0.04],
            thumbnailFilename: "ABC-thumb.jpg"
        )

        let data = try Self.makeEncoder().encode([original])
        let decoded = try Self.makeDecoder().decode([Memory].self, from: data)

        #expect(decoded.count == 1)
        let memory = try #require(decoded.first)
        #expect(memory.id == original.id)
        #expect(memory.capturedAt == original.capturedAt)
        #expect(memory.filename == original.filename)
        #expect(memory.pixelSize == original.pixelSize)
        #expect(memory.emotion == .surprise)
        #expect(memory.confidence == original.confidence)
        #expect(memory.scores == original.scores)
        #expect(memory.thumbnailFilename == original.thumbnailFilename)
    }

    @Test("编码后不再写出旧字段名 date / cover")
    func doesNotWriteLegacyKeys() throws {
        let memory = Memory(
            capturedAt: Self.fixedDate,
            filename: "X.jpg",
            emotion: .happy,
            confidence: 0.5
        )

        let data = try Self.makeEncoder().encode([memory])
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(json.contains("\"capturedAt\""))
        #expect(!json.contains("\"cover\""))
        // "date" 是 "capturedAt" 的子串之外还要确认没有独立的 date 键
        #expect(!json.contains("\"date\""))
    }

    // MARK: - 旧格式

    /// 重构前的真实格式：`date` + `cover` 绝对路径 + 没有 confidence。
    private static let legacyJSON = """
    [
      {
        "id" : "3F2504E0-4F89-11D3-9A0C-0305E82C3301",
        "date" : "2026-08-15T09:30:00Z",
        "cover" : "/var/mobile/Containers/Data/Application/XXX/Documents/3F2504E0-4F89-11D3-9A0C-0305E82C3301.jpg",
        "emotion" : "Happy"
      },
      {
        "id" : "3F2504E0-4F89-11D3-9A0C-0305E82C3302",
        "date" : "2026-08-16T10:00:00Z",
        "cover" : "/var/mobile/Containers/Data/Application/XXX/Documents/3F2504E0-4F89-11D3-9A0C-0305E82C3302.jpg",
        "emotion" : "surprise"
      }
    ]
    """

    @Test("旧格式仍能解码")
    func decodesLegacyFormat() throws {
        let data = try #require(Self.legacyJSON.data(using: .utf8))
        let decoded = try Self.makeDecoder().decode([Memory].self, from: data)

        #expect(decoded.count == 2)
        let first = try #require(decoded.first)
        #expect(first.emotion == .happy)
        #expect(first.confidence == 0, "旧记录没有置信度，应默认为 0")
        #expect(first.scores == nil)
    }

    @Test("旧格式的绝对路径被裁剪成文件名")
    func legacyAbsolutePathBecomesFilename() throws {
        let data = try #require(Self.legacyJSON.data(using: .utf8))
        let decoded = try Self.makeDecoder().decode([Memory].self, from: data)

        let first = try #require(decoded.first)
        // 这是关键：沙盒路径会变，只有文件名是可移植的。
        #expect(first.filename == "3F2504E0-4F89-11D3-9A0C-0305E82C3301.jpg")
        #expect(!first.filename.contains("/"))
    }

    @Test("新格式里写成完整路径的 filename 也会被裁剪")
    func absoluteFilenameIsSanitized() throws {
        let json = """
        [{
          "id" : "3F2504E0-4F89-11D3-9A0C-0305E82C3303",
          "capturedAt" : "2026-08-15T09:30:00Z",
          "filename" : "/tmp/somewhere/Y.jpg",
          "emotion" : "Sad",
          "confidence" : 0.4
        }]
        """
        let data = try #require(json.data(using: .utf8))
        let decoded = try Self.makeDecoder().decode([Memory].self, from: data)
        #expect(decoded.first?.filename == "Y.jpg")
    }

    @Test("既没有 filename 也没有 cover 时抛错，而不是静默丢弃")
    func missingBothFilenamesThrows() throws {
        let json = """
        [{
          "id" : "3F2504E0-4F89-11D3-9A0C-0305E82C3304",
          "capturedAt" : "2026-08-15T09:30:00Z",
          "emotion" : "Sad"
        }]
        """
        let data = try #require(json.data(using: .utf8))
        #expect(throws: (any Error).self) {
            try Self.makeDecoder().decode([Memory].self, from: data)
        }
    }

    @Test("无法识别的表情会抛错，而不是被静默改成 Neutral")
    func unknownEmotionThrows() throws {
        let json = """
        [{
          "id" : "3F2504E0-4F89-11D3-9A0C-0305E82C3305",
          "capturedAt" : "2026-08-15T09:30:00Z",
          "filename" : "Z.jpg",
          "emotion" : "Contempt"
        }]
        """
        let data = try #require(json.data(using: .utf8))
        #expect(throws: (any Error).self) {
            try Self.makeDecoder().decode([Memory].self, from: data)
        }
    }

    @Test("Emotion 在字典里按字符串键往返")
    func emotionDictionaryRoundTrip() throws {
        let scores: [Emotion: Float] = [.angry: 0.1, .happy: 0.8, .sad: 0.1]
        let data = try Self.makeEncoder().encode(scores)
        let decoded = try Self.makeDecoder().decode([Emotion: Float].self, from: data)
        #expect(decoded == scores)
    }

    // MARK: - 概率分布的磁盘格式

    /// 直接 `encode([Emotion: Float])` 时，因为 `Emotion` 不是 `String`/`Int`，
    /// Swift 会写出**扁平交错数组** `["Happy", 0.9, "Sad", 0.1]` —— 能读回来，
    /// 但人不可读、外部工具也解析不了。这里守住它必须是 JSON 对象。
    @Test("概率分布写成 JSON 对象，而不是扁平交错数组")
    func scoresEncodedAsObject() throws {
        let memory = Memory(
            capturedAt: Self.fixedDate,
            filename: "S.jpg",
            emotion: .happy,
            confidence: 0.8,
            scores: [.happy: 0.8, .sad: 0.2]
        )

        let data = try Self.makeEncoder().encode([memory])
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(json.contains("\"Happy\" : 0.8"), "概率分布应该是 {键: 值} 的对象\n\(json)")
        #expect(json.contains("\"Sad\" : 0.2"))
        // 扁平数组的特征：字符串键后面直接跟数字，中间没有冒号
        #expect(!json.contains("\"Happy\", \\n"), "不应出现扁平交错数组\n\(json)")
    }

    @Test("对象格式的概率分布能读回并还原成 Emotion 键")
    func scoresObjectRoundTrip() throws {
        let scores: [Emotion: Float] = [.fear: 0.55, .neutral: 0.3, .angry: 0.15]
        let memory = Memory(
            capturedAt: Self.fixedDate,
            filename: "S.jpg",
            emotion: .fear,
            confidence: 0.55,
            scores: scores
        )

        let data = try Self.makeEncoder().encode([memory])
        let decoded = try Self.makeDecoder().decode([Memory].self, from: data)
        #expect(decoded.first?.scores == scores)
    }

    @Test("兼容早期写出的扁平交错数组格式")
    func decodesLegacyFlatScores() throws {
        let json = """
        [{
          "id" : "3F2504E0-4F89-11D3-9A0C-0305E82C3306",
          "capturedAt" : "2026-08-15T09:30:00Z",
          "filename" : "F.jpg",
          "emotion" : "Happy",
          "confidence" : 0.9,
          "scores" : ["Happy", 0.9, "Sad", 0.1]
        }]
        """
        let data = try #require(json.data(using: .utf8))
        let decoded = try Self.makeDecoder().decode([Memory].self, from: data)

        let scores = try #require(decoded.first?.scores)
        #expect(scores[.happy] == 0.9)
        #expect(scores[.sad] == 0.1)
    }

    @Test("旧记录没有 confidence 时，从概率分布里补一个")
    func missingConfidenceFallsBackToScores() throws {
        let json = """
        [{
          "id" : "3F2504E0-4F89-11D3-9A0C-0305E82C3307",
          "capturedAt" : "2026-08-15T09:30:00Z",
          "filename" : "G.jpg",
          "emotion" : "Happy",
          "scores" : { "Happy" : 0.62, "Sad" : 0.38 }
        }]
        """
        let data = try #require(json.data(using: .utf8))
        let decoded = try Self.makeDecoder().decode([Memory].self, from: data)
        #expect(decoded.first?.confidence == 0.62)
    }
}
