//
//  MemoryDetailView.swift
//  Echoes
//

import SwiftUI

/// 一条归档记录的详情。
struct MemoryDetailView: View {

    @Environment(MemoryStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let memory: Memory

    @State private var isConfirmingDelete = false
    @State private var isSharing = false

    /// 记录可能已经被删掉（在别处删或同步延迟），所以从 store 里重新取一次更稳。
    private var current: Memory {
        store.memories.first { $0.id == memory.id } ?? memory
    }

    private var scores: [EmotionReport.Score] {
        let source = current.scores ?? [current.emotion: current.confidence]
        return Emotion.allCases
            .map { EmotionReport.Score(emotion: $0, confidence: source[$0] ?? 0) }
            .sorted { $0.confidence > $1.confidence }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                MemoryFullImage(memory: current)
                    .padding(.horizontal)

                header

                EmotionScoreBars(scores: scores, highlight: current.emotion)
                    .padding(.horizontal)

                deleteButton
            }
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Image(systemName: current.emotion.symbol)
                        .foregroundStyle(current.emotion.tint)
                    Text(current.emotion.displayName)
                        .appText(18, weight: .semibold)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isSharing = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("分享")
            }
        }
        .sheet(isPresented: $isSharing) {
            if let image = ThumbnailCache.shared.thumbnail(for: current)
                ?? ImageStore().loadImage(filename: current.filename) {
                ShareSheet(items: [image])
            }
        }
        .confirmationDialog(
            "删除这条记录？",
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible
        ) {
            Button("删除", role: .destructive) {
                Task {
                    try? await store.delete(current)
                    dismiss()
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("照片和记录都会被删掉，无法恢复。")
        }
    }

    // MARK: - 片段

    private var header: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: current.emotion.symbol)
                    .foregroundStyle(current.emotion.tint)
                Text(current.emotion.displayName)
                    .appText(22, weight: .bold)
                Text(percent(current.confidence))
                    .appText(14)
                    .foregroundStyle(.secondary)
            }

            Text(DateFormatters.full.string(from: current.capturedAt))
                .appText(14)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            isConfirmingDelete = true
        } label: {
            Label("删除这条记录", systemImage: "trash")
                .appText(16, weight: .semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    Color.red.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .foregroundStyle(.red)
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
}

/// `UIActivityViewController` 的 SwiftUI 包装。
struct ShareSheet: UIViewControllerRepresentable {

    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
