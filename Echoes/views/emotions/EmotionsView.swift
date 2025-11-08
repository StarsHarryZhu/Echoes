//
//  EmotionsView.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/7.
//

import SwiftUI
import Combine

// MARK: - Models
enum Emotion: String, CaseIterable, Identifiable, Hashable {
    case joy = "Joy", sad = "Sad", calm = "Calm", angry = "Angry",
         surprise = "Surprise", fear = "Fear", love = "Love", neutral = "Neutral"
    var id: String { rawValue }

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
    let cover: String?
    let emotion: Emotion
}

// MARK: - ViewModel (mock data)
final class EmotionsVM: ObservableObject {
    @Published var all: [EmotionMemory] = {
        let es: [Emotion] = [.joy,.sad,.calm,.angry,.surprise,.fear,.love,.neutral]
        return (0..<24).map { i in
            // 造一些不同日期
            EmotionMemory(title: "Memory \(i+1)",
                          date: .now.addingTimeInterval(Double(-i * 86_400)),
                          cover: nil,
                          emotion: es[i % es.count])
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
            ScrollView {
                LazyVGrid(columns: cols, spacing: 12) {
                    ForEach(Emotion.allCases) { emo in
                        let count = vm.items(for: emo).count
                        NavigationLink(value: emo) {
                            EmotionGridItem(emotion: emo, count: count)   // 右上角仅数字徽章（白色）
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

// MARK: - Emotion Card
private struct EmotionGridItem: View {
    let emotion: Emotion
    let count: Int

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(LinearGradient(colors: [emotion.tint.opacity(0.9), emotion.tint.opacity(0.5)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(height: 150)
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(.white.opacity(0.18), lineWidth: 1))
                .shadow(radius: 6, y: 3)

            // 白色数字徽章
            Text("\(count)")
                .font(.caption).bold()
                .foregroundColor(.white)
                .padding(.horizontal, 8).padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

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
    }
}

// MARK: - Emotion Album Grid（标题显示日期：yyMMdd）
private struct EmotionListView: View {
    let emotion: Emotion
    let items: [EmotionMemory]
    private let cols = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            // 彩色 Header
            HStack {
                Image(systemName: emotion.icon)
                Text(emotion.rawValue).bold()
                Spacer()
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
                        thumb(of: m).resizable().scaledToFill()
                            .frame(height: 150).clipped()
                            .overlay(alignment: .bottomLeading) {
                                // 显示日期：yyMMdd（例：251108）
                                Text(formattedDate(m.date))
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

    private func thumb(of m: EmotionMemory) -> Image {
        if let n = m.cover, UIImage(named: n) != nil { return Image(n) }
        return Image(systemName: "photo.on.rectangle.angled")
    }
    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyMMdd"
        return f.string(from: date)
    }
}

// MARK: - Detail
private struct MemoryDetailView: View {
    let memory: EmotionMemory
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(memory.emotion.tint.opacity(0.12))
                        .frame(height: 320)
                    coverImage.resizable().scaledToFit().frame(maxHeight: 300)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(.quaternary, lineWidth: 1)
                )
                .padding(.horizontal)

                Text(formattedDate(memory.date)).font(.title3).bold()
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

    // ✅ 改名为 coverImage，避免与 thumb(of:) 冲突
    private var coverImage: Image {
        if let n = memory.cover, UIImage(named: n) != nil { return Image(n) }
        return Image(systemName: "photo")
    }
    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyMMdd"
        return f.string(from: date)
    }
}

#Preview { EmotionsView() }
