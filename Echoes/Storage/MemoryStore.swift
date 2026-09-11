//
//  MemoryStore.swift
//  Echoes
//

import Combine
import Foundation
import Observation
import UIKit

/// 归档的唯一数据源。
///
/// 重构前是 `local_IO`：一个 `ObservableObject` 单例，但**从没被任何视图订阅**
/// （视图里写的是 `local_IO.local_io.items(for:)`，读的是单例属性而不是 `@StateObject`），
/// 所以保存后界面不会刷新，必须杀进程重开才看得到。这里改用 `@Observable` +
/// 从 `Environment` 注入，添加/删除会自动驱动界面更新。
@MainActor
@Observable
final class MemoryStore {

    // MARK: 状态

    /// 全部记录，按 `capturedAt` 倒序。
    private(set) var memories: [Memory] = []

    /// 首次加载（含旧数据迁移）是否还在进行。
    private(set) var isLoading = true

    /// 启动阶段的非致命错误，供界面提示。
    private(set) var startupError: String?

    // MARK: 依赖

    let imageStore: ImageStore
    private let migrator: MemoryMigrator
    private let thumbnailCache: ThumbnailCache

    init(
        imageStore: ImageStore = ImageStore(),
        thumbnailCache: ThumbnailCache? = nil
    ) {
        self.imageStore = imageStore
        self.migrator = MemoryMigrator(imageStore: imageStore)
        self.thumbnailCache = thumbnailCache ?? ThumbnailCache(imageStore: imageStore)
    }

    // MARK: - 启动

    /// 迁移旧数据并载入归档。
    ///
    /// 迁移 + 读盘都放到主线程之外：旧归档可能有上千条记录、每张图都要重新编码，
    /// 放在 `init` 里会卡住启动。
    func bootstrap() async {
        let migrate = migrator.needsMigration
        let migrator = self.migrator
        let manifestURL = imageStore.manifestURL

        let outcome: Result<[Memory], any Error> = await Task.detached(priority: .userInitiated) {
            do {
                if migrate {
                    try migrator.migrate()
                }
                return .success(try MemoryManifest.read(from: manifestURL))
            } catch {
                return .failure(error)
            }
        }.value

        switch outcome {
        case .success(let loaded):
            memories = loaded
            startupError = nil
        case .failure(let error):
            // 迁移失败也从零开始，但要把原因显示出来 —— 旧数据没删，用户还有救。
            memories = []
            startupError = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - 增删

    /// 保存一条新记录：写图 + 写清单。
    ///
    /// 图片先落盘再更新清单，这样清单里不会出现指向不存在文件的记录。
    @discardableResult
    func add(image: UIImage, report: EmotionReport, capturedAt: Date = Date()) async throws -> Memory {
        let id = UUID()
        let imageStore = self.imageStore

        let saved = try await Task.detached(priority: .userInitiated) {
            try imageStore.saveImages(image, id: id)
        }.value

        var scores: [Emotion: Float] = [:]
        for score in report.rankedScores {
            scores[score.emotion] = score.confidence
        }

        let memory = Memory(
            id: id,
            capturedAt: capturedAt,
            filename: saved.filename,
            pixelSize: saved.pixelSize,
            emotion: report.emotion,
            confidence: report.confidence,
            scores: scores,
            thumbnailFilename: saved.thumbnailFilename
        )

        memories.insert(memory, at: 0)
        try await persist()
        return memory
    }

    /// 删除一条记录及其图片文件。
    func delete(_ memory: Memory) async throws {
        memories.removeAll { $0.id == memory.id }

        thumbnailCache.evict(memory)
        let imageStore = self.imageStore
        await Task.detached(priority: .utility) {
            imageStore.deleteImage(filename: memory.filename)
            if let thumb = memory.thumbnailFilename {
                imageStore.deleteThumbnail(filename: thumb)
            }
        }.value

        try await persist()
    }

    // MARK: - 查询

    /// 某个表情下的全部记录（已按时间倒序）。
    func items(for emotion: Emotion) -> [Memory] {
        memories.filter { $0.emotion == emotion }
    }

    func count(for emotion: Emotion) -> Int {
        memories.reduce(into: 0) { total, memory in
            if memory.emotion == emotion { total += 1 }
        }
    }

    var isEmpty: Bool { memories.isEmpty }

    // MARK: - 缓存

    /// 归档占用的磁盘空间（字节）。
    func diskUsage() async -> Int64 {
        let imageStore = self.imageStore
        return await Task.detached(priority: .utility) {
            imageStore.diskUsage
        }.value
    }

    /// 清掉缩略图缓存与磁盘上的缩略图。
    /// - Returns: 释放的字节数。
    @discardableResult
    func clearThumbnailCache() async -> Int64 {
        thumbnailCache.removeAll()
        let imageStore = self.imageStore
        return await Task.detached(priority: .utility) {
            imageStore.clearThumbnails()
        }.value
    }

    // MARK: - 磁盘读写

    private func persist() async throws {
        let snapshot = memories
        let manifestURL = imageStore.manifestURL
        let imageStore = self.imageStore
        try await Task.detached(priority: .utility) {
            try imageStore.ensureDirectories()
            try MemoryManifest.write(snapshot, to: manifestURL)
        }.value
    }
}
