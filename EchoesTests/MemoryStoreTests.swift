//
//  MemoryStoreTests.swift
//  EchoesTests
//

import Foundation
import Testing
import UIKit

@testable import Echoes

private func makeTempRoot() -> URL {
    FileManager.default.temporaryDirectory
        .appendingPathComponent("EchoesStoreTests-\(UUID().uuidString)", isDirectory: true)
}

private func makeImage(width: CGFloat = 400, height: CGFloat = 300) -> UIImage {
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = 1
    return UIGraphicsImageRenderer(
        size: CGSize(width: width, height: height),
        format: format
    ).image { context in
        UIColor.systemIndigo.setFill()
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    }
}

private func makeReport(emotion: Emotion = .happy, confidence: Float = 0.8) -> EmotionReport {
    var scores: [EmotionReport.Score] = []
    for item in Emotion.allCases {
        scores.append(
            EmotionReport.Score(
                emotion: item,
                confidence: item == emotion ? confidence : (1 - confidence) / Float(Emotion.allCases.count - 1)
            )
        )
    }
    scores.sort { $0.confidence > $1.confidence }
    return EmotionReport(
        emotion: emotion,
        confidence: confidence,
        rankedScores: scores,
        faceBox: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5)
    )
}

@Suite("MemoryManifest 读写")
struct MemoryManifestTests {

    @Test("文件不存在时返回空数组（首次运行）")
    func missingFileIsEmpty() throws {
        let root = makeTempRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let url = root.appendingPathComponent("memories.json")
        #expect(try MemoryManifest.read(from: url).isEmpty)
    }

    @Test("写入后能读回来，并按时间倒序")
    func roundTripSortsDescending() throws {
        let root = makeTempRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let url = root.appendingPathComponent("memories.json")
        let old = Memory(capturedAt: Date(timeIntervalSince1970: 1000), filename: "a.jpg", emotion: .sad, confidence: 0.3)
        let new = Memory(capturedAt: Date(timeIntervalSince1970: 2000), filename: "b.jpg", emotion: .happy, confidence: 0.9)

        try MemoryManifest.write([old, new], to: url)
        let loaded = try MemoryManifest.read(from: url)

        #expect(loaded.map(\.filename) == ["b.jpg", "a.jpg"])
    }

    @Test("清单损坏时抛错，并把原文件备份一份")
    func corruptedManifestIsBackedUp() throws {
        let root = makeTempRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let url = root.appendingPathComponent("memories.json")
        let broken = "{ this is not valid json"
        try Data(broken.utf8).write(to: url)

        #expect(throws: MemoryManifest.ManifestError.self) {
            try MemoryManifest.read(from: url)
        }

        // 原文件保留
        #expect(FileManager.default.fileExists(atPath: url.path))

        // 备份文件出现，且内容与损坏的原文件一致
        let siblings = try FileManager.default.contentsOfDirectory(atPath: root.path)
        let backups = siblings.filter { $0.hasPrefix("memories.corrupt-") }
        #expect(backups.count == 1, "应该正好生成一个备份，实际：\(siblings)")

        let backupURL = root.appendingPathComponent(try #require(backups.first))
        #expect(try String(contentsOf: backupURL, encoding: .utf8) == broken)
    }

    /// 重构前的实现是 `catch { all = [] }` —— 用户的归档就这么没了。这条测试守住不再回退。
    @Test("损坏的清单不会被静默清空成空文件")
    func doesNotSilentlyWipe() throws {
        let root = makeTempRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let url = root.appendingPathComponent("memories.json")
        try Data("[]".utf8).write(to: url)
        // 先写一个合法空数组，确认读得出来
        #expect(try MemoryManifest.read(from: url).isEmpty)

        try Data("garbage".utf8).write(to: url)
        #expect(throws: (any Error).self) { try MemoryManifest.read(from: url) }

        // 原文件内容没有被覆盖
        #expect(try String(contentsOf: url, encoding: .utf8) == "garbage")
    }
}

@Suite("MemoryStore")
@MainActor
struct MemoryStoreTests {

    @Test("新增记录后能查到，图片与清单都落盘")
    func addPersistsEverything() async throws {
        let root = makeTempRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let imageStore = ImageStore(rootDirectory: root)
        let store = MemoryStore(imageStore: imageStore)

        let memory = try await store.add(image: makeImage(), report: makeReport(emotion: .surprise))

        #expect(store.memories.count == 1)
        #expect(memory.emotion == .surprise)
        #expect(FileManager.default.fileExists(atPath: imageStore.imageURL(for: memory.filename).path))
        #expect(FileManager.default.fileExists(atPath: imageStore.manifestURL.path))
    }

    @Test("新增的记录会被排到最前面")
    func addInsertsAtFront() async throws {
        let root = makeTempRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let store = MemoryStore(imageStore: ImageStore(rootDirectory: root))

        let first = try await store.add(image: makeImage(), report: makeReport(emotion: .happy))
        let second = try await store.add(image: makeImage(), report: makeReport(emotion: .sad))

        #expect(store.memories.map(\.id) == [second.id, first.id])
    }

    @Test("按表情筛选计数正确")
    func countsPerEmotion() async throws {
        let root = makeTempRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let store = MemoryStore(imageStore: ImageStore(rootDirectory: root))
        _ = try await store.add(image: makeImage(), report: makeReport(emotion: .happy))
        _ = try await store.add(image: makeImage(), report: makeReport(emotion: .happy))
        _ = try await store.add(image: makeImage(), report: makeReport(emotion: .angry))

        #expect(store.count(for: .happy) == 2)
        #expect(store.count(for: .angry) == 1)
        #expect(store.count(for: .fear) == 0)
        #expect(store.items(for: .happy).count == 2)
    }

    @Test("概率分布被完整保留下来")
    func scoresArePersisted() async throws {
        let root = makeTempRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let store = MemoryStore(imageStore: ImageStore(rootDirectory: root))
        let memory = try await store.add(image: makeImage(), report: makeReport(emotion: .fear, confidence: 0.61))

        #expect(memory.scores?.count == Emotion.allCases.count)
        #expect(memory.scores?[.fear] == 0.61)
    }

    @Test("删除会同时移除记录与图片文件")
    func deleteRemovesRecordAndFile() async throws {
        let root = makeTempRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let imageStore = ImageStore(rootDirectory: root)
        let store = MemoryStore(imageStore: imageStore)
        let memory = try await store.add(image: makeImage(), report: makeReport())

        let imageURL = imageStore.imageURL(for: memory.filename)
        let thumbURL = imageStore.thumbnailURL(for: try #require(memory.thumbnailFilename))
        #expect(FileManager.default.fileExists(atPath: imageURL.path))

        try await store.delete(memory)

        #expect(store.memories.isEmpty)
        #expect(!FileManager.default.fileExists(atPath: imageURL.path))
        #expect(!FileManager.default.fileExists(atPath: thumbURL.path))
    }

    @Test("重开后数据还在（走 bootstrap 从磁盘读回）")
    func survivesRelaunch() async throws {
        let root = makeTempRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let imageStore = ImageStore(rootDirectory: root)
        let first = MemoryStore(imageStore: imageStore)
        let memory = try await first.add(image: makeImage(), report: makeReport(emotion: .disgust))

        // 模拟杀进程重开：新建一个 store，走同一条启动路径。
        let second = MemoryStore(imageStore: imageStore)
        await second.bootstrap()

        #expect(second.memories.count == 1)
        #expect(second.memories.first?.id == memory.id)
        #expect(second.memories.first?.emotion == .disgust)
    }

    @Test("bootstrap 之后不再是 loading 状态")
    func bootstrapFinishes() async {
        let root = makeTempRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let store = MemoryStore(imageStore: ImageStore(rootDirectory: root))
        #expect(store.isLoading)

        await store.bootstrap()

        #expect(!store.isLoading)
        #expect(store.startupError == nil)
    }

    @Test("清单损坏时以空归档启动，但把原因留在 startupError 里")
    func corruptedManifestSurfacesError() async throws {
        let root = makeTempRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let imageStore = ImageStore(rootDirectory: root)
        try imageStore.ensureDirectories()
        try Data("not json at all".utf8).write(to: imageStore.manifestURL)

        let store = MemoryStore(imageStore: imageStore)
        await store.bootstrap()

        #expect(store.memories.isEmpty)
        #expect(store.startupError != nil, "损坏必须被报出来，不能静默当作空归档")
    }

    @Test("清除缓存会释放字节数且保留记录")
    func clearCacheKeepsRecords() async throws {
        let root = makeTempRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let store = MemoryStore(imageStore: ImageStore(rootDirectory: root))
        _ = try await store.add(image: makeImage(width: 1500, height: 1500), report: makeReport())

        let freed = await store.clearThumbnailCache()

        #expect(freed > 0)
        #expect(store.memories.count == 1)
    }

    @Test("磁盘占用随记录增加")
    func diskUsageGrows() async throws {
        let root = makeTempRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let store = MemoryStore(imageStore: ImageStore(rootDirectory: root))
        let before = await store.diskUsage()
        _ = try await store.add(image: makeImage(width: 1200, height: 1200), report: makeReport())
        let after = await store.diskUsage()

        #expect(after > before)
    }
}
