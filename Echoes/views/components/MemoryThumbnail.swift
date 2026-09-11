//
//  MemoryThumbnail.swift
//  Echoes
//

import SwiftUI

/// 归档列表里的照片缩略图。
///
/// 走 `ThumbnailCache` 取图（内存缓存 + 磁盘缩略图），
/// 图片缺失时显示占位图标而不是空白。
struct MemoryThumbnail: View {

    let memory: Memory

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
            }
        }
        .clipped()
        .task(id: memory.id) {
            // 缓存命中时这是同步返回，不会闪。
            image = ThumbnailCache.shared.thumbnail(for: memory)
        }
    }

    private var placeholder: some View {
        ZStack {
            Rectangle().fill(memory.emotion.tint.opacity(0.15))
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 22))
                .foregroundStyle(.secondary)
        }
    }
}

/// 照片缺失时的整幅占位图，用于详情页。
struct MemoryFullImage: View {

    let memory: Memory

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(memory.emotion.tint.opacity(0.12))
                    VStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 32))
                        Text("照片已丢失")
                            .appText(14)
                    }
                    .foregroundStyle(.secondary)
                }
                .frame(height: 320)
            }
        }
        .task(id: memory.id) {
            image = ThumbnailCache.shared.thumbnail(for: memory)
                ?? ImageStore().loadImage(filename: memory.filename)
        }
    }
}
