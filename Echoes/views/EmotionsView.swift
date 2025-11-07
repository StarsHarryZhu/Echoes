//
//  EmotionsView.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/7.
//

import SwiftUI

// MARK: - Emotion 类型
enum Emotion: String, CaseIterable, Identifiable {
    case joy = "Joy"
    case sad = "Sad"
    case calm = "Calm"
    case fear = "Fear"
    case anger = "Anger"
    case surprise = "Surprise"
    var id: String { rawValue }

    var icon: String {
        switch self {
        case .joy: return "face.smiling"
        case .sad: return "face.dashed"
        case .calm: return "wind"
        case .fear: return "exclamationmark.triangle"
        case .anger: return "flame"
        case .surprise: return "sparkles"
        }
    }

    // 你可以在这里放每个情绪的主色
    var tint: Color {
        switch self {
        case .joy: return .yellow
        case .sad: return .blue
        case .calm: return .teal
        case .fear: return .orange
        case .anger: return .red
        case .surprise: return .purple
        }
    }
}

// MARK: - 相册与照片占位模型
struct EmotionAlbum: Identifiable {
    let id = UUID()
    let emotion: Emotion
    let title: String
    let count: Int
    // 占位封面（真实项目中可用最近一张或多张合成）
    let coverSymbol: String
}

struct PhotoItem: Identifiable, Hashable {
    let id = UUID()
    let symbol: String   // 占位，后续换成真实图片/PHAsset 本地标识
}

// MARK: - 伪数据（后续替换为真实数据源）
struct EmotionDataSource {
    static let albums: [EmotionAlbum] = [
        .init(emotion: .joy, title: "Sunny Weekend", count: 24, coverSymbol: "sun.max"),
        .init(emotion: .sad, title: "Rainy Night", count: 11, coverSymbol: "cloud.rain"),
        .init(emotion: .calm, title: "Quiet Morning", count: 18, coverSymbol: "leaf"),
        .init(emotion: .fear, title: "Dark Alley", count: 5, coverSymbol: "moon.zzz"),
        .init(emotion: .anger, title: "Traffic Jam", count: 9, coverSymbol: "car.fill"),
        .init(emotion: .surprise, title: "Birthday Party", count: 30, coverSymbol: "gift")
    ]

    static func photos(for emotion: Emotion) -> [PhotoItem] {
        // 仅为示例：返回 20 张占位图标
        let base: [String] = ["photo","photo.fill","camera","person","figure.walk","mappin","heart","bolt","leaf","sparkles"]
        return (0..<20).map { _ in PhotoItem(symbol: base.randomElement()!) }
    }
}

// MARK: - EmotionsView（分类入口）
struct EmotionsView: View {
    @State private var selectedEmotion: Emotion = .joy
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                // 情绪选择器
                Picker("Emotion", selection: $selectedEmotion) {
                    ForEach(Emotion.allCases) { emo in
                        Label(emo.rawValue, systemImage: emo.icon).tag(emo)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // 当前情绪下的相册网格
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(EmotionDataSource.albums.filter { $0.emotion == selectedEmotion }) { album in
                            NavigationLink {
                                EmotionDetailView(emotion: album.emotion, title: album.title)
                            } label: {
                                EmotionAlbumCard(album: album)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                }
            }
            .navigationTitle("Emotions")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        // 预留操作：导入照片、智能分组、编辑情绪等
                        Button("Import Photos", systemImage: "square.and.arrow.down") { /* TODO */ }
                        Button("Smart Grouping", systemImage: "wand.and.stars") { /* TODO */ }
                        Button("Manage Emotions", systemImage: "slider.horizontal.3") { /* TODO */ }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
}

// MARK: - 相册卡片
struct EmotionAlbumCard: View {
    let album: EmotionAlbum

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(album.emotion.tint.opacity(0.15))
                    .frame(height: 120)
                    .overlay {
                        Image(systemName: album.coverSymbol)
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundStyle(album.emotion.tint)
                    }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(.quaternary, lineWidth: 1)
            )
            Text(album.title)
                .font(.headline)
                .lineLimit(1)
            HStack(spacing: 6) {
                Image(systemName: album.emotion.icon)
                Text(album.emotion.rawValue)
                Text("· \(album.count)")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

// MARK: - 情绪详情（照片网格）
struct EmotionDetailView: View {
    let emotion: Emotion
    let title: String
    private let columns = [GridItem(.adaptive(minimum: 90), spacing: 8)]

    var photos: [PhotoItem] {
        EmotionDataSource.photos(for: emotion)
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(photos) { item in
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(emotion.tint.opacity(0.12))
                            .frame(height: 90)
                        Image(systemName: item.symbol)
                            .imageScale(.large)
                            .foregroundStyle(emotion.tint)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(.quaternary, lineWidth: 1)
                    )
                }
            }
            .padding(12)
        }
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Select", systemImage: "checkmark.circle") { /* TODO: 选择模式 */ }
            }
        }
    }
}

#Preview {
    EmotionsView()
}

