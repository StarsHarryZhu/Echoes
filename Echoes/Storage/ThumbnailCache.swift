//
//  ThumbnailCache.swift
//  Echoes
//

import Foundation
import UIKit

/// 缩略图内存缓存。
///
/// 重构前 `cover_image(of:)` 每次渲染都调 `UIImage(contentsOfFile:)` 重新解码，
/// 滚动时主线程会反复卡顿；而且它用的是 `UIImage(named:)`（只查资源目录，不查沙盒），
/// 所以归档里的照片**永远显示不出**来 —— 每次都落到占位图分支。
///
/// 这里按文件名缓存解码好的 `UIImage`，并在缩略图缺失时回退到原图。
@MainActor
final class ThumbnailCache {

    static let shared = ThumbnailCache()

    /// 只收 500 张 / 64MB，超出的自动淘汰。
    private let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 500
        cache.totalCostLimit = 64 * 1024 * 1024
        return cache
    }()

    private let imageStore: ImageStore

    init(imageStore: ImageStore = ImageStore()) {
        self.imageStore = imageStore
    }

    /// 取缩略图。先查内存缓存，再读磁盘（缩略图 → 原图）。
    func thumbnail(for memory: Memory) -> UIImage? {
        let key = memory.thumbnailFilename ?? memory.filename
        if let cached = cache.object(forKey: key as NSString) {
            return cached
        }

        let image: UIImage?
        if let name = memory.thumbnailFilename {
            image = imageStore.loadThumbnail(filename: name)
        } else {
            // 旧记录没有缩略图，直接用原图顶上。
            image = imageStore.loadImage(filename: memory.filename)
        }
        guard let image else { return nil }

        let cost = Int(image.size.width * image.size.height * 4)
        cache.setObject(image, forKey: key as NSString, cost: cost)
        return image
    }

    /// 删除记录后清掉对应缓存，避免文件名复用（同一 UUID）时读到旧图。
    func evict(_ memory: Memory) {
        cache.removeObject(forKey: (memory.thumbnailFilename ?? memory.filename) as NSString)
    }

    /// 「清除缓存」后调用。
    func removeAll() {
        cache.removeAllObjects()
    }
}
