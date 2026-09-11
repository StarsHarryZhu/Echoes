//
//  ImageStore.swift
//  Echoes
//

import Combine
import Foundation
import ImageIO
import UIKit

/// 照片文件在磁盘上的读写。
///
/// 目录布局（相对于沙盒 `Documents`）：
/// ```
/// Echoes/
///   memories.json
///   Images/<uuid>.jpg          原图，长边 ≤ 2048
///   Thumbnails/<uuid>.jpg      缩略图，长边 ≤ 600
/// ```
/// 相比重构前把图片直接丢在 `Documents/` 根目录、并在 JSON 里存**绝对路径**的做法，
/// 这里只存文件名 —— 沙盒路径会变（重装、恢复备份），存绝对路径必然失效。
nonisolated final class ImageStore: @unchecked Sendable {

    /// 文件夹名。`ImageStore` 标了 `nonisolated`，所以嵌套类型不会继承
    /// 本工程的 `MainActor` 默认隔离。
    enum Namespace {
        static let folder = "Echoes"
        static let images = "Images"
        static let thumbnails = "Thumbnails"
        static let manifest = "memories.json"
    }

    /// 原图长边上限。手机前置相机全尺寸可达 12MP 以上，
    /// 归档用途不需要那么大，压缩后能显著降低磁盘与解码开销。
    static let fullImageMaxEdge: CGFloat = 2048
    /// 缩略图长边上限。
    static let thumbnailMaxEdge: CGFloat = 600

    static let fullImageQuality: CGFloat = 0.9
    static let thumbnailQuality: CGFloat = 0.8

    /// 只存根目录。不把 `FileManager` 存成属性 —— 它不是 `Sendable`，
    /// 而这个类要在后台任务里用；`FileManager.default` 每次取即可。
    private let rootDirectory: URL

    /// - Parameter rootDirectory: 归档根目录。测试时注入临时目录。
    init(rootDirectory: URL? = nil) {
        self.rootDirectory = rootDirectory ?? Self.defaultRootDirectory()
    }

    /// 默认归档根目录：`Documents/Echoes`。
    static func defaultRootDirectory() -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent(Namespace.folder, isDirectory: true)
    }

    // MARK: - 路径

    var rootURL: URL { rootDirectory }
    var imagesURL: URL { rootDirectory.appendingPathComponent(Namespace.images, isDirectory: true) }
    var thumbnailsURL: URL { rootDirectory.appendingPathComponent(Namespace.thumbnails, isDirectory: true) }
    var manifestURL: URL { rootDirectory.appendingPathComponent(Namespace.manifest) }

    /// 原图文件 URL。
    func imageURL(for filename: String) -> URL {
        imagesURL.appendingPathComponent(filename)
    }

    /// 缩略图文件 URL。
    func thumbnailURL(for filename: String) -> URL {
        thumbnailsURL.appendingPathComponent(filename)
    }

    // MARK: - 目录

    /// 建好所有需要的目录。可重复调用。
    func ensureDirectories() throws {
        for directory in [rootDirectory, imagesURL, thumbnailsURL] {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
        }
    }

    // MARK: - 写入

    /// 保存原图与缩略图。
    ///
    /// 两条路径都会用 `UIGraphicsImageRenderer` 重绘：`UIImagePickerController`
    /// 前置相机拍出的图常带 `imageOrientation`，直接 `jpegData` 会写出方向不一致的
    /// EXIF；重绘一次能把方向烘焙进像素，后续 Vision 与显示都不用再猜。
    ///
    /// - Returns: 原图文件名、缩略图文件名、原图像素尺寸。
    @discardableResult
    func saveImages(
        _ image: UIImage,
        id: UUID
    ) throws -> (filename: String, thumbnailFilename: String, pixelSize: CGSize) {
        try ensureDirectories()

        let normalized = Self.reoriented(image)
        let full = Self.downscaled(normalized, maxEdge: Self.fullImageMaxEdge)
        let thumb = Self.downscaled(normalized, maxEdge: Self.thumbnailMaxEdge)

        let filename = "\(id.uuidString).jpg"
        let thumbnailFilename = "\(id.uuidString)-thumb.jpg"

        try Self.writeJPEG(
            full,
            quality: Self.fullImageQuality,
            to: imageURL(for: filename)
        )
        try Self.writeJPEG(
            thumb,
            quality: Self.thumbnailQuality,
            to: thumbnailURL(for: thumbnailFilename)
        )

        return (filename, thumbnailFilename, full.size)
    }

    /// 只补一张缩略图（用于旧记录迁移或缩略图被清掉之后重建）。
    @discardableResult
    func writeThumbnail(
        of image: UIImage,
        filename: String
    ) throws -> String {
        try ensureDirectories()
        let normalized = Self.reoriented(image)
        let thumb = Self.downscaled(normalized, maxEdge: Self.thumbnailMaxEdge)
        try Self.writeJPEG(
            thumb,
            quality: Self.thumbnailQuality,
            to: thumbnailURL(for: filename)
        )
        return filename
    }

    // MARK: - 读取

    func loadImage(filename: String) -> UIImage? {
        UIImage(contentsOfFile: imageURL(for: filename).path)
    }

    func loadThumbnail(filename: String) -> UIImage? {
        UIImage(contentsOfFile: thumbnailURL(for: filename).path)
    }

    // MARK: - 删除

    func deleteImage(filename: String) {
        try? FileManager.default.removeItem(at: imageURL(for: filename))
    }

    func deleteThumbnail(filename: String) {
        try? FileManager.default.removeItem(at: thumbnailURL(for: filename))
    }

    /// 删掉整个缩略图目录并重建。
    /// - Returns: 释放的字节数。
    @discardableResult
    func clearThumbnails() -> Int64 {
        let freed = directorySize(at: thumbnailsURL)
        try? FileManager.default.removeItem(at: thumbnailsURL)
        try? FileManager.default.createDirectory(at: thumbnailsURL, withIntermediateDirectories: true)
        return freed
    }

    /// 归档占用的总字节数。
    var diskUsage: Int64 {
        directorySize(at: rootDirectory)
    }

    // MARK: - 内部实现

    private func directorySize(at url: URL) -> Int64 {
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(
                forKeys: [.fileSizeKey, .isRegularFileKey]
            ), values.isRegularFile == true else {
                continue
            }
            total += Int64(values.fileSize ?? 0)
        }
        return total
    }

    /// 把 `imageOrientation` 烘焙进像素。
    private static func reoriented(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }

    /// 等比缩放到长边不超过 `maxEdge`。已经够小就原样返回。
    private static func downscaled(_ image: UIImage, maxEdge: CGFloat) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        guard longest > maxEdge, longest > 0 else { return image }

        let scale = maxEdge / longest
        let target = CGSize(
            width: (image.size.width * scale).rounded(),
            height: (image.size.height * scale).rounded()
        )

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: target, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }

    private static func writeJPEG(_ image: UIImage, quality: CGFloat, to url: URL) throws {
        guard let data = image.jpegData(compressionQuality: quality) else {
            throw CocoaError(.fileWriteUnknown)
        }
        try data.write(to: url, options: .atomic)
    }
}
