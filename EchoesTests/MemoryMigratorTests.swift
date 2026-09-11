//
//  MemoryMigratorTests.swift
//  EchoesTests
//

import Foundation
import Testing
import UIKit

@testable import Echoes

/// 一套「旧布局」沙盒：`legacyRoot/memories.json` + `legacyRoot/<uuid>.jpg`。
private struct LegacySandbox {
    let legacyRoot: URL
    let archiveRoot: URL

    init() {
        let base = FileManager.default.temporaryDirectory
            .appendingPathComponent("EchoesMigratorTests-\(UUID().uuidString)", isDirectory: true)
        legacyRoot = base.appendingPathComponent("Documents", isDirectory: true)
        archiveRoot = base.appendingPathComponent("Archive", isDirectory: true)
        try? FileManager.default.createDirectory(at: legacyRoot, withIntermediateDirectories: true)
    }

    func cleanUp() {
        try? FileManager.default.removeItem(at: legacyRoot.deletingLastPathComponent())
    }

    func writeImage(named filename: String) throws {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let image = UIGraphicsImageRenderer(
            size: CGSize(width: 320, height: 240),
            format: format
        ).image { context in
            UIColor.systemBrown.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 320, height: 240))
        }
        let data = try #require(image.jpegData(compressionQuality: 0.9))
        try data.write(to: legacyRoot.appendingPathComponent(filename))
    }

    /// 旧版清单的字段：`date` + `cover` 绝对路径，没有 confidence。
    func writeManifest(entries: [(id: UUID, date: String, emotion: String)]) throws {
        let items = entries.map { entry -> String in
            let cover = legacyRoot.appendingPathComponent("\(entry.id.uuidString).jpg").path
            return """
                {
                  "id" : "\(entry.id.uuidString)",
                  "date" : "\(entry.date)",
                  "cover" : "\(cover)",
                  "emotion" : "\(entry.emotion)"
                }
            """
        }
        let json = "[\n" + items.joined(separator: ",\n") + "\n]"
        try Data(json.utf8).write(to: legacyRoot.appendingPathComponent("memories.json"))
    }
}

@Suite("旧归档迁移", .serialized)
struct MemoryMigratorTests {

    @Test("没有旧清单时不需要迁移")
    func noLegacyManifest() {
        let sandbox = LegacySandbox()
        defer { sandbox.cleanUp() }

        let imageStore = ImageStore(rootDirectory: sandbox.archiveRoot)
        let migrator = MemoryMigrator(imageStore: imageStore, legacyRootDirectory: sandbox.legacyRoot)

        #expect(!migrator.needsMigration)
        #expect((try? migrator.migrate())?.isEmpty == true)
    }

    @Test("旧记录被搬到新目录，字段完整")
    func migratesRecords() throws {
        let sandbox = LegacySandbox()
        defer { sandbox.cleanUp() }

        let id = UUID()
        try sandbox.writeImage(named: "\(id.uuidString).jpg")
        try sandbox.writeManifest(entries: [(id, "2026-08-15T09:30:00Z", "happy")])

        let imageStore = ImageStore(rootDirectory: sandbox.archiveRoot)
        let migrator = MemoryMigrator(imageStore: imageStore, legacyRootDirectory: sandbox.legacyRoot)

        #expect(migrator.needsMigration)
        let migrated = try migrator.migrate()

        #expect(migrated.count == 1)
        let memory = try #require(migrated.first)

        // 关键：文件名不再是把旧路径原样搬过来，而是新规范下的 `<uuid>.jpg`
        #expect(memory.filename == "\(id.uuidString).jpg")
        #expect(memory.thumbnailFilename == "\(id.uuidString)-thumb.jpg")
        #expect(memory.emotion == .happy)
        #expect(memory.id == id)
        #expect(memory.pixelSize != nil)

        // 文件真的在归档目录里
        #expect(FileManager.default.fileExists(atPath: imageStore.imageURL(for: memory.filename).path))
        #expect(
            FileManager.default.fileExists(
                atPath: imageStore.thumbnailURL(for: try #require(memory.thumbnailFilename)).path
            )
        )
    }

    @Test("旧清单与旧图片被改名保留，而不是删除")
    func legacyFilesAreKept() throws {
        let sandbox = LegacySandbox()
        defer { sandbox.cleanUp() }

        let id = UUID()
        let legacyImage = "\(id.uuidString).jpg"
        try sandbox.writeImage(named: legacyImage)
        try sandbox.writeManifest(entries: [(id, "2026-08-15T09:30:00Z", "sad")])

        let migrator = MemoryMigrator(
            imageStore: ImageStore(rootDirectory: sandbox.archiveRoot),
            legacyRootDirectory: sandbox.legacyRoot
        )
        try migrator.migrate()

        let fileManager = FileManager.default
        // 旧清单改名保留
        #expect(fileManager.fileExists(atPath: sandbox.legacyRoot.appendingPathComponent("memories.json.migrated").path))
        // 旧图片改名保留
        #expect(fileManager.fileExists(atPath: sandbox.legacyRoot.appendingPathComponent("\(legacyImage).migrated").path))
    }

    @Test("图片丢失的记录被跳过，不阻断整批迁移")
    func missingImageIsSkipped() throws {
        let sandbox = LegacySandbox()
        defer { sandbox.cleanUp() }

        let presentID = UUID()
        let missingID = UUID()
        try sandbox.writeImage(named: "\(presentID.uuidString).jpg")
        try sandbox.writeManifest(entries: [
            (presentID, "2026-08-15T09:30:00Z", "happy"),
            (missingID, "2026-08-16T09:30:00Z", "angry"),
        ])

        let migrator = MemoryMigrator(
            imageStore: ImageStore(rootDirectory: sandbox.archiveRoot),
            legacyRootDirectory: sandbox.legacyRoot
        )
        let migrated = try migrator.migrate()

        #expect(migrated.count == 1)
        #expect(migrated.first?.id == presentID)
    }

    @Test("迁移完成后不再需要迁移（清单已改名）")
    func migrationIsIdempotent() throws {
        let sandbox = LegacySandbox()
        defer { sandbox.cleanUp() }

        let id = UUID()
        try sandbox.writeImage(named: "\(id.uuidString).jpg")
        try sandbox.writeManifest(entries: [(id, "2026-08-15T09:30:00Z", "happy")])

        let migrator = MemoryMigrator(
            imageStore: ImageStore(rootDirectory: sandbox.archiveRoot),
            legacyRootDirectory: sandbox.legacyRoot
        )

        _ = try migrator.migrate()
        #expect(!migrator.needsMigration)

        // 再跑一次是空操作，不会重复导入
        #expect(try migrator.migrate().isEmpty)
    }

    @Test("旧清单损坏时抛错，原文件保持不动")
    func corruptedLegacyManifestThrows() throws {
        let sandbox = LegacySandbox()
        defer { sandbox.cleanUp() }

        let manifest = sandbox.legacyRoot.appendingPathComponent("memories.json")
        try Data("definitely not json".utf8).write(to: manifest)

        let migrator = MemoryMigrator(
            imageStore: ImageStore(rootDirectory: sandbox.archiveRoot),
            legacyRootDirectory: sandbox.legacyRoot
        )

        #expect(throws: MemoryMigrator.MigrationError.self) {
            try migrator.migrate()
        }
        // 没被改名也没被删 —— 用户的原始数据必须还在
        #expect(FileManager.default.fileExists(atPath: manifest.path))
    }
}
