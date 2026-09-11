//
//  StorageTests.swift
//  EchoesTests
//

import Foundation
import Testing
import UIKit

@testable import Echoes

/// 每个测试用独立的临时目录，互不干扰；测试结束删掉。
private struct TempDirectory {
    let url: URL

    init() {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent("EchoesTests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func cleanUp() {
        try? FileManager.default.removeItem(at: url)
    }
}

/// 造一张指定尺寸的纯色图。
private func makeImage(width: CGFloat, height: CGFloat, orientation: UIImage.Orientation = .up) -> UIImage {
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = 1
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format)
    let image = renderer.image { context in
        UIColor.systemTeal.setFill()
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    }
    guard orientation != .up else { return image }
    // 用同样的像素重新构造一张带指定方向标记的图。
    return UIImage(cgImage: image.cgImage!, scale: 1, orientation: orientation)
}

@Suite("ImageStore")
struct ImageStoreTests {

    @Test("保存后会建好目录，并写出原图与缩略图")
    func savesImagesAndDirectories() throws {
        let temp = TempDirectory()
        defer { temp.cleanUp() }

        let store = ImageStore(rootDirectory: temp.url)
        let id = UUID()
        let result = try store.saveImages(makeImage(width: 800, height: 600), id: id)

        let fileManager = FileManager.default
        #expect(fileManager.fileExists(atPath: store.imageURL(for: result.filename).path))
        #expect(fileManager.fileExists(atPath: store.thumbnailURL(for: result.thumbnailFilename).path))
        #expect(fileManager.fileExists(atPath: store.imagesURL.path))
        #expect(fileManager.fileExists(atPath: store.thumbnailsURL.path))
    }

    @Test("原图与缩略图文件名不同，避免互相覆盖")
    func fullAndThumbNamesDiffer() throws {
        let temp = TempDirectory()
        defer { temp.cleanUp() }

        let store = ImageStore(rootDirectory: temp.url)
        let result = try store.saveImages(makeImage(width: 400, height: 400), id: UUID())

        #expect(result.filename != result.thumbnailFilename)
    }

    @Test("超过上限的长边会被缩到 2048，且保持宽高比")
    func downscalesOversizedImage() throws {
        let temp = TempDirectory()
        defer { temp.cleanUp() }

        let store = ImageStore(rootDirectory: temp.url)
        let result = try store.saveImages(makeImage(width: 4000, height: 3000), id: UUID())

        #expect(max(result.pixelSize.width, result.pixelSize.height) == ImageStore.fullImageMaxEdge)
        // 4000x3000 → 2048x1536，宽高比不变
        let originalRatio = 4000.0 / 3000.0
        let scaledRatio = result.pixelSize.width / result.pixelSize.height
        #expect(abs(originalRatio - scaledRatio) < 0.001)
    }

    @Test("未超过上限的图保持原尺寸，不会被放大")
    func doesNotUpscale() throws {
        let temp = TempDirectory()
        defer { temp.cleanUp() }

        let store = ImageStore(rootDirectory: temp.url)
        let result = try store.saveImages(makeImage(width: 640, height: 480), id: UUID())

        #expect(result.pixelSize == CGSize(width: 640, height: 480))
    }

    @Test("缩略图长边不超过 600")
    func thumbnailIsSmall() throws {
        let temp = TempDirectory()
        defer { temp.cleanUp() }

        let store = ImageStore(rootDirectory: temp.url)
        let result = try store.saveImages(makeImage(width: 3000, height: 3000), id: UUID())
        let thumbnail = try #require(store.loadThumbnail(filename: result.thumbnailFilename))

        #expect(max(thumbnail.size.width, thumbnail.size.height) <= ImageStore.thumbnailMaxEdge)
    }

    /// 这是关键修复点：前置相机拍出的图带 `imageOrientation`，像素本身没转正。
    /// 保存时必须把方向烘焙进像素，否则详情页显示会是躺倒的。
    @Test("带方向的图在保存时被转正", arguments: [
        UIImage.Orientation.leftMirrored,
        .right,
        .down,
    ])
    func bakesOrientationIntoPixels(orientation: UIImage.Orientation) throws {
        let temp = TempDirectory()
        defer { temp.cleanUp() }

        let store = ImageStore(rootDirectory: temp.url)
        let source = makeImage(width: 640, height: 480, orientation: orientation)
        #expect(source.imageOrientation == orientation, "构造的测试图方向不对")

        let result = try store.saveImages(source, id: UUID())
        let saved = try #require(store.loadImage(filename: result.filename))

        #expect(saved.imageOrientation == .up, "保存后方向应该已经烘焙进像素")
    }

    @Test("删除会同时移除原图与缩略图")
    func deleteRemovesBothFiles() throws {
        let temp = TempDirectory()
        defer { temp.cleanUp() }

        let store = ImageStore(rootDirectory: temp.url)
        let result = try store.saveImages(makeImage(width: 300, height: 300), id: UUID())

        store.deleteImage(filename: result.filename)
        store.deleteThumbnail(filename: result.thumbnailFilename)

        let fileManager = FileManager.default
        #expect(!fileManager.fileExists(atPath: store.imageURL(for: result.filename).path))
        #expect(!fileManager.fileExists(atPath: store.thumbnailURL(for: result.thumbnailFilename).path))
    }

    @Test("清除缩略图不影响原图，并返回释放的字节数")
    func clearThumbnailsKeepsOriginals() throws {
        let temp = TempDirectory()
        defer { temp.cleanUp() }

        let store = ImageStore(rootDirectory: temp.url)
        let result = try store.saveImages(makeImage(width: 1200, height: 900), id: UUID())

        let freed = store.clearThumbnails()

        #expect(freed > 0)
        #expect(FileManager.default.fileExists(atPath: store.imageURL(for: result.filename).path))
        #expect(!FileManager.default.fileExists(atPath: store.thumbnailURL(for: result.thumbnailFilename).path))
    }

    @Test("磁盘占用会统计目录里的文件")
    func diskUsage() throws {
        let temp = TempDirectory()
        defer { temp.cleanUp() }

        let store = ImageStore(rootDirectory: temp.url)
        #expect(store.diskUsage == 0)

        try store.saveImages(makeImage(width: 1000, height: 1000), id: UUID())
        #expect(store.diskUsage > 0)
    }

    @Test("读取不存在的文件返回 nil，不崩")
    func loadingMissingFileReturnsNil() {
        let temp = TempDirectory()
        defer { temp.cleanUp() }

        let store = ImageStore(rootDirectory: temp.url)
        #expect(store.loadImage(filename: "nope.jpg") == nil)
        #expect(store.loadThumbnail(filename: "nope.jpg") == nil)
    }
}
