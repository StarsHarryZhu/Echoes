//
//  TimelineView.swift
//  Echoes
//

import SwiftUI

/// 按时间归档。
///
/// 重构前这里是 `MemoriesView`，内容只有一行 `Text("MemoriesView")` —— 完全没实现。
struct TimelineView: View {

    @Environment(MemoryStore.self) private var store

    /// 点击某条记录时由父视图决定怎么导航。
    let onSelect: (Memory) -> Void

    @AppStorage(AppPreferenceKey.timelineGranularity) private var granularityRaw: String = TimelineGranularity.automatic.rawValue
    @State private var pendingDeletion: Memory?

    private var granularity: TimelineGranularity {
        TimelineGranularity(rawValue: granularityRaw) ?? .automatic
    }

    private var sections: [TimelineSection] {
        groupTimeline(store.memories, granularity: granularity)
    }

    var body: some View {
        Group {
            if store.isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = store.startupError {
                StartupErrorView(message: error)
            } else if store.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .background(Color(.systemGroupedBackground))
        .confirmationDialog(
            L10n.timelineDeleteConfirmTitle,
            isPresented: Binding(
                get: { pendingDeletion != nil },
                set: { if !$0 { pendingDeletion = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(L10n.delete, role: .destructive) {
                if let memory = pendingDeletion {
                    Task { try? await store.delete(memory) }
                }
                pendingDeletion = nil
            }
            Button(L10n.cancel, role: .cancel) { pendingDeletion = nil }
        } message: {
            Text(L10n.timelineDeleteConfirmMessage)
        }
    }

    // MARK: - 列表

    private var list: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18, pinnedViews: [.sectionHeaders]) {
                granularityPicker

                ForEach(sections) { section in
                    Section {
                        VStack(spacing: 10) {
                            ForEach(section.memories) { memory in
                                Button {
                                    onSelect(memory)
                                } label: {
                                    TimelineRow(memory: memory)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(L10n.delete, systemImage: "trash", role: .destructive) {
                                        pendingDeletion = memory
                                    }
                                }
                            }
                        }
                    } header: {
                        sectionHeader(section)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }

    private var granularityPicker: some View {
        Picker(L10n.timelineGroupLabel, selection: $granularityRaw) {
            ForEach(TimelineGranularity.allCases) { option in
                Text(option.title).tag(option.rawValue)
            }
        }
        .pickerStyle(.segmented)
    }

    private func sectionHeader(_ section: TimelineSection) -> some View {
        HStack {
            Text(section.title)
                .appText(15, weight: .semibold)
            Text("\(section.memories.count)")
                .appText(13)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 1)
                .background(Color(.tertiarySystemFill), in: Capsule())
            Spacer()
        }
        .padding(.vertical, 6)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - 空状态

    private var emptyState: some View {
        ContentUnavailableView {
            Label(L10n.timelineEmptyTitle, systemImage: "camera")
        } description: {
            Text(L10n.timelineEmptyMessage)
        }
    }
}

/// 时间线里的一行。
private struct TimelineRow: View {

    let memory: Memory

    var body: some View {
        HStack(spacing: 12) {
            MemoryThumbnail(memory: memory)
                .frame(width: 62, height: 62)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Image(systemName: memory.emotion.symbol)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(memory.emotion.tint)
                    Text(memory.emotion.displayName)
                        .appText(16, weight: .semibold)
                }

                Text(DateFormatters.full.string(from: memory.capturedAt))
                    .appText(12)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 6) {
                Text(percent(memory.confidence))
                    .appText(13)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// 启动阶段出错的提示。归档清单损坏时用。
struct StartupErrorView: View {

    let message: String

    var body: some View {
        ContentUnavailableView {
            Label(L10n.startupFailedTitle, systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        }
    }
}
