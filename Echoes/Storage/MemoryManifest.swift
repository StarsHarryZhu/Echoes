//
//  MemoryManifest.swift
//  Echoes
//

import Foundation

/// 归档清单（`memories.json`）的读写。
///
/// 从 `MemoryStore` 里抽出来单独成类型，是为了让这些方法天然是 `nonisolated` 的 ——
/// 它们要在后台任务里跑，而 `MemoryStore` 本身是 `@MainActor`。
nonisolated enum MemoryManifest {

    /// 日期用 ISO8601，输出排序后便于 diff 与人工排查。
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

    /// 写清单。
    ///
    /// 用原子写：中途崩溃 / 断电报废的是临时文件，原清单仍然完整。
    static func write(_ memories: [Memory], to url: URL) throws {
        let data = try makeEncoder().encode(memories)
        try data.write(to: url, options: .atomic)
    }

    /// 读清单。
    ///
    /// 文件不存在 → 返回空数组（首次运行）。
    /// 解码失败 → 把坏文件复制一份带时间戳的备份，然后抛错。
    /// 重构前这里是把 `all = []` 一吞了事，用户的归档就这么没了。
    static func read(from url: URL) throws -> [Memory] {
        let data = try readData(from: url)
        guard let data else { return [] }

        do {
            let decoded = try makeDecoder().decode([Memory].self, from: data)
            return decoded.sorted { $0.capturedAt > $1.capturedAt }
        } catch {
            backupCorruptedManifest(at: url)
            throw ManifestError.corrupted(error.localizedDescription)
        }
    }

    /// 只读原始数据，不做解码。
    ///
    /// 迁移旧归档时用这个 —— 旧清单必须走**同一套**日期解码策略
    /// （`.iso8601`），否则 `JSONDecoder` 的默认策略（自 2001 年起的秒数）
    /// 会把 `"2026-08-15T09:30:00Z"` 判为格式错误。
    static func readData(from url: URL) throws -> Data? {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        return try Data(contentsOf: url)
    }

    /// 用与 `read(from:)` 相同的策略解码任意 `[Memory]` 数据。迁移路径使用。
    static func decode(_ data: Data) throws -> [Memory] {
        try makeDecoder().decode([Memory].self, from: data)
    }

    /// 把损坏的清单复制成 `memories.corrupt-<时间戳>.json`。
    /// 原文件保留在原地，不动它。
    private static func backupCorruptedManifest(at url: URL) {
        let stamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let backup = url.deletingLastPathComponent()
            .appendingPathComponent("memories.corrupt-\(stamp).json")
        try? FileManager.default.removeItem(at: backup)
        try? FileManager.default.copyItem(at: url, to: backup)
    }
}

extension MemoryManifest {
    enum ManifestError: LocalizedError {
        case corrupted(String)

        var errorDescription: String? {
            switch self {
            case .corrupted(let reason):
                return L10n.manifestCorrupted(reason)
            }
        }
    }
}
