//
//  SettingsView.swift
//  Echoes
//

import SwiftUI

/// 设置页。
///
/// 重构前这里有三类问题：
/// 1. `settings` 结构体的每个 setter 都把值**写死成常量**（`set { UserDefaults…set(true, …) }`），
///    所以开关拨了也存不住；
/// 2. 「录制模式」「性能设置」「Personal Information」这些行点了完全没反应；
/// 3. 「清除缓存」永远显示 `0.00MB`，也不做任何事。
///
/// 现在只留真正能用的设置项。原来那些为了将来预留的死行已移除 ——
/// 没有实现的功能不该出现在界面上。
struct SettingsView: View {

    @Environment(MemoryStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @AppStorage(AppPreferenceKey.timelineGranularity)
    private var granularityRaw: String = TimelineGranularity.automatic.rawValue

    /// 语言是全局状态，不用 `@AppStorage` —— 它要同时更新字符串表缓存
    /// 并广播通知让视图树重建。
    @State private var language: AppLanguage = LanguageManager.current

    /// 默认开。关掉后，检测不到人脸就让用户重拍而不是硬给一个结果。
    @AppStorage(AppPreferenceKey.faceDetectionFallback)
    private var faceDetectionFallback: Bool = true

    @State private var diskUsage: Int64?
    @State private var isClearing = false
    @State private var clearResult: String?

    private enum Subpage: Hashable {
        case about
        case creators
        case feedback
        case rate
    }

    private var granularity: Binding<TimelineGranularity> {
        Binding(
            get: { TimelineGranularity(rawValue: granularityRaw) ?? .automatic },
            set: { granularityRaw = $0.rawValue }
        )
    }

    var body: some View {
        List {
            languageSection
            timelineSection
            analysisSection
            storageSection
            aboutSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle(L10n.settingsTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(L10n.done) { dismiss() }
                    .fontWeight(.semibold)
            }
        }
        .navigationDestination(for: Subpage.self) { page in
            switch page {
            case .about: AboutUsView()
            case .creators: CreatorsView()
            case .feedback: FeedbackView()
            case .rate: RateUsView()
            }
        }
        .task { await refreshDiskUsage() }
    }

    // MARK: - 分区

    private var languageSection: some View {
        Section {
            Picker(L10n.settingsLanguageRow, selection: $language) {
                ForEach(AppLanguage.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }
        } header: {
            Text(L10n.settingsSectionLanguage)
        } footer: {
            Text(L10n.settingsLanguageFooter)
        }
        .onChange(of: language) { _, newValue in
            // 写入会广播通知，EchoesApp 换掉根视图 id 重建整棵树。
            LanguageManager.current = newValue
            // 日期格式也跟着语言走，缓存要清掉。
            DateFormatters.resetCache()
        }
    }

    private var timelineSection: some View {
        Section {
            Picker(L10n.settingsTimelineGrouping, selection: granularity) {
                ForEach(TimelineGranularity.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
        } header: {
            Text(L10n.settingsSectionTimeline)
        } footer: {
            Text(L10n.settingsTimelineFooter)
        }
    }

    private var analysisSection: some View {
        Section {
            Toggle(L10n.settingsFaceFallback, isOn: $faceDetectionFallback)
        } header: {
            Text(L10n.settingsSectionAnalysis)
        } footer: {
            Text(L10n.settingsFaceFallbackFooter)
        }
    }

    private var storageSection: some View {
        Section {
            LabeledContent {
                Text("\(store.memories.count)")
                    .foregroundStyle(.secondary)
            } label: {
                Label(L10n.settingsArchivedPhotos, systemImage: "photo.stack")
            }

            Button {
                Task { await clearCache() }
            } label: {
                HStack {
                    Label(L10n.settingsClearCache, systemImage: "trash")
                    Spacer()
                    if isClearing {
                        ProgressView().controlSize(.small)
                    } else {
                        Text(diskUsage.map(formattedByteCount) ?? "—")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .disabled(isClearing)
        } header: {
            Text(L10n.settingsSectionStorage)
        } footer: {
            if let clearResult {
                Text(clearResult)
            } else {
                Text(L10n.settingsStorageFooter)
            }
        }
    }

    private var aboutSection: some View {
        Section {
            NavigationLink(value: Subpage.about) {
                Label(L10n.settingsAboutApp, systemImage: "info.circle")
            }
            NavigationLink(value: Subpage.creators) {
                Label(L10n.settingsTeam, systemImage: "person.2")
            }
            NavigationLink(value: Subpage.feedback) {
                Label(L10n.settingsFeedback, systemImage: "envelope")
            }
            NavigationLink(value: Subpage.rate) {
                Label(L10n.settingsRate, systemImage: "star")
            }
        } header: {
            Text(L10n.settingsSectionAbout)
        }
    }

    // MARK: - 动作

    private func refreshDiskUsage() async {
        diskUsage = await store.diskUsage()
    }

    private func clearCache() async {
        isClearing = true
        defer { isClearing = false }

        let freed = await store.clearThumbnailCache()
        await refreshDiskUsage()

        clearResult = freed > 0
            ? L10n.settingsCacheFreed(formattedByteCount(freed))
            : L10n.settingsCacheNothing
    }
}

#Preview {
    let store = MemoryStore()
    return NavigationStack {
        SettingsView().environment(store)
    }
}
