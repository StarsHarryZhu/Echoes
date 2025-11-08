import SwiftUI
import Combine

// MARK: - Models
enum Emotion: String, CaseIterable, Identifiable, Hashable {
    case joy = "Joy", sad = "Sad", calm = "Calm", angry = "Angry",
         surprise = "Surprise", fear = "Fear", love = "Love", neutral = "Neutral"
    var id: String { rawValue }

    // 美观用：统一的图标与主色
    var icon: String {
        switch self {
        case .joy: return "sun.max.fill"
        case .sad: return "cloud.rain.fill"
        case .calm: return "leaf.fill"
        case .angry: return "flame.fill"
        case .surprise: return "sparkles"
        case .fear: return "exclamationmark.triangle.fill"
        case .love: return "heart.fill"
        case .neutral: return "circle.fill"
        }
    }
    var tint: Color {
        switch self {
        case .joy: return .yellow
        case .sad: return .blue
        case .calm: return .teal
        case .angry: return .red
        case .surprise: return .purple
        case .fear: return .orange
        case .love: return .pink
        case .neutral: return .gray
        }
    }
}

struct EmotionMemory: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let date: Date
    let cover: String?          // asset name; nil -> placeholder
    let emotion: Emotion
}

// MARK: - ViewModel (mock data)
final class EmotionsVM: ObservableObject {
    @Published var all: [EmotionMemory] = {
        let es: [Emotion] = [.joy,.sad,.calm,.angry,.surprise,.fear,.love,.neutral]
        return (0..<24).map { i in
            EmotionMemory(title: "Memory \(i+1)", date: .now, cover: nil, emotion: es[i % es.count])
        }
    }()
    func items(for e: Emotion) -> [EmotionMemory] { all.filter { $0.emotion == e } }
}

// MARK: - Views
struct EmotionsView: View {
    @StateObject private var vm = EmotionsVM()
    private let cols = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            // Home: grid of emotions (one card = one emotion)
            ScrollView {
                LazyVGrid(columns: cols, spacing: 12) {
                    ForEach(Emotion.allCases) { emo in
                        let count = vm.items(for: emo).count
                        NavigationLink(value: emo) {
                            EmotionGridItem(
                                emotion: emo,
                                count: count
                            )
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)
            }
            .navigationTitle("Emotion Album")
            .navigationDestination(for: Emotion.self) { emo in
                EmotionListView(emotion: emo, items: vm.items(for: emo))
            }
            .navigationDestination(for: EmotionMemory.self) { m in
                MemoryDetailView(memory: m)
            }
        }
    }
}

// 彩色情绪卡片（更好看）
private struct EmotionGridItem: View {
    let emotion: Emotion
    let count: Int

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // 渐变背景 + 阴影 + 细描边
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [emotion.tint.opacity(0.9), emotion.tint.opacity(0.5)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(height: 150)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(.white.opacity(0.18), lineWidth: 1)
                )
                .shadow(radius: 6, y: 3)

            // 右上角数量徽章
            HStack(spacing: 4) {
                Image(systemName: "photo.on.rectangle")
                Text("\(count)")
            }
            .font(.caption).bold()
            .padding(.horizontal, 8).padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

            // 左下角图标 + 名字
            HStack(spacing: 10) {
                Image(systemName: emotion.icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.95))
                    .shadow(radius: 2)
                Text(emotion.rawValue)
                    .font(.headline).bold()
                    .foregroundStyle(.white)
            }
            .padding(12)
        }
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

// 某情绪下的相册列表（带彩色 header）
private struct EmotionListView: View {
    let emotion: Emotion
    let items: [EmotionMemory]
    private let cols = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            // 彩色标题条
            HStack {
                Image(systemName: emotion.icon)
                Text(emotion.rawValue).bold()
                Spacer()
                Text("\(items.count) items").font(.subheadline).opacity(0.9)
            }
            .foregroundStyle(.white)
            .padding()
            .background(
                LinearGradient(colors: [emotion.tint, emotion.tint.opacity(0.6)],
                               startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal)

            LazyVGrid(columns: cols, spacing: 12) {
                ForEach(items) { m in
                    NavigationLink(value: m) {
                        cover(of: m).resizable().scaledToFill()
                            .frame(height: 150).clipped()
                            .overlay(alignment: .bottomLeading) {
                                Text(m.title)
                                    .font(.footnote).bold().foregroundStyle(.white)
                                    .padding(.horizontal, 8).padding(.vertical, 6)
                                    .background(.black.opacity(0.35), in: Capsule())
                                    .padding(8)
                            }
                            .cornerRadius(14)
                            .shadow(radius: 3, y: 2)
                    }
                }
            }
            .padding(.horizontal).padding(.top, 12)
        }
        .navigationTitle(emotion.rawValue)
    }

    private func cover(of m: EmotionMemory) -> Image {
        if let n = m.cover, UIImage(named: n) != nil { return Image(n) }
        return Image(systemName: "photo.on.rectangle.angled")
    }
}

// 详情页卡片
private struct MemoryDetailView: View {
    let memory: EmotionMemory
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(memory.emotion.tint.opacity(0.12))
                        .frame(height: 320)
                    cover.resizable().scaledToFit().frame(maxHeight: 300)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(.quaternary, lineWidth: 1)
                )
                .padding(.horizontal)

                Text(memory.title).font(.title3).bold()
                HStack(spacing: 8) {
                    Image(systemName: memory.emotion.icon)
                        .foregroundStyle(memory.emotion.tint)
                    Text(memory.emotion.rawValue)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 24)
        }
        .navigationTitle("Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
    private var cover: Image {
        if let n = memory.cover, UIImage(named: n) != nil { return Image(n) }
        return Image(systemName: "photo")
    }
}

#Preview { EmotionsView() }
