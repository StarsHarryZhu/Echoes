//
//  MemoryMigrator.swift
//  Echoes
//

import Foundation
import UIKit

/// 把重构前的旧归档搬到新目录结构。
///
/// 重构前的布局：
/// ```
/// Documents/
///   memories.json          [ { id, date, cover: "/…/Documents/<uuid>.jpg", emotion } ]
///   <uuid>.jpg             图片散在 Documents 根目录
/// ```
/// 新布局见 `ImageStore`。
///
/// 迁移原则：**只搬不改**。旧文件一律保留（改名加 `.migrated` 后缀），
/// 中途任何一步失败都会让调用方拿到错误，旧数据原封不动还在。
///
/// 这是个可选步骤，将来可以整体删掉 —— 判断依据是 `Documents/memories.json`
/// 是否还存在。上线若干版本、确认没有用户还在旧格式之后就能移除。
nonisolated final class MemoryMigrator: @unchecked Sendable {

    /// 旧图片所在目录（`Documents` 根）。
    let legacyRootDirectory: URL
    private let imageStore: ImageStore

    init(imageStore: ImageStore, legacyRootDirectory: URL? = nil) {
        self.imageStore = imageStore
        self.legacyRootDirectory = legacyRootDirectory
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// 旧清单文件的位置。
    var legacyManifestURL: URL {
        legacyRootDirectory.appendingPathComponent(ImageStore.Namespace.manifest)
    }

    /// 旧清单是否还在（决定要不要迁移）。
    var needsMigration: Bool {
        FileManager.default.fileExists(atPath: legacyManifestURL.path)
    }

    /// 执行迁移。
    ///
    /// - Returns: 迁移过来的记录（可能为空数组 —— 旧清单为空，或其中的图片都已不在）。
    @discardableResult
    func migrate() throws -> [Memory] {
        guard needsMigration else { return [] }

        try imageStore.ensureDirectories()

        let data = try Data(contentsOf: legacyManifestURL)

        // 旧清单必须走 `MemoryManifest` 的解码策略：日期是 ISO8601 **字符串**，
        // 而裸 `JSONDecoder()` 的默认策略把它当成"自 2001 年起的秒数"，
        // 于是报 "isn't in the correct format" —— 迁移整体失败。
        // 旧的 Memory 结构没有 filename，只有 cover 绝对路径；
        // `Memory.init(from:)` 已做兼容（capturedAt←date、filename←cover 的文件名）。
        let legacy: [Memory]
        do {
            legacy = try MemoryManifest.decode(data)
        } catch {
            throw MigrationError.manifestUnreadable(error.localizedDescription)
        }

        var migrated: [Memory] = []
        migrated.reserveCapacity(legacy.count)

        for memory in legacy {
            let sourceURL = legacyRootDirectory.appendingPathComponent(memory.filename)

            // 旧图可能已经不在了（用户手动删过）。跳过，不阻断整个迁移。
            guard FileManager.default.fileExists(atPath: sourceURL.path),
                  let image = UIImage(contentsOfFile: sourceURL.path) else {
                continue
            }

            // 用新的命名与尺寸规范重新落盘，顺带生成缩略图。
            let saved = try imageStore.saveImages(image, id: memory.id)
            migrated.append(
                Memory(
                    id: memory.id,
                    capturedAt: memory.capturedAt,
                    filename: saved.filename,
                    pixelSize: saved.pixelSize,
                    emotion: memory.emotion,
                    confidence: memory.confidence,
                    scores: memory.scores,
                    thumbnailFilename: saved.thumbnailFilename
                )
            )
        }

        // 旧文件改名保留，而不是删除 —— 迁移结果不满意时还能翻回去看。
        try archiveLegacyManifest()
        archiveLegacyImages(keeping: legacy.map(\.filename))

        return migrated
    }

    // MARK: - 内部实现

    private func archiveLegacyManifest() throws {
        let archived = legacyManifestURL.appendingPathExtension("migrated")
        try? FileManager.default.removeItem(at: archived)
        try FileManager.default.moveItem(at: legacyManifestURL, to: archived)
    }

    /// 把迁移过来的旧图片也改名成 `.migrated`，避免和 `Images/` 里的新文件混淆。
    private func archiveLegacyImages(keeping filenames: [String]) {
        for filename in filenames {
            let source = legacyRootDirectory.appendingPathComponent(filename)
            guard FileManager.default.fileExists(atPath: source.path) else { continue }
            let archived = source.appendingPathExtension("migrated")
            try? FileManager.default.removeItem(at: archived)
            try? FileManager.default.moveItem(at: source, to: archived)
        }
    }
}

extension MemoryMigrator {
    enum MigrationError: LocalizedError {
        case manifestUnreadable(String)

        var errorDescription: String? {
            switch self {
            case .manifestUnreadable(let reason):
                return "旧的归档清单读不出来：\(reason)"
            }
        }
    }
}
