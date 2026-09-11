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
}
