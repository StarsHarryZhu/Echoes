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
            timelineSection
            analysisSection
            storageSection
            aboutSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("完成") { dismiss() }
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

    private var timelineSection: some View {
        Section {
            Picker("时间归档分组", selection: granularity) {
                ForEach(TimelineGranularity.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
        } header: {
            Text("时间归档")
        } footer: {
            Text("决定「Timeline」页里照片的分组方式。")
        }
    }

    private var analysisSection: some View {
        Section {
            Toggle("检测不到人脸时退回整图识别", isOn: $faceDetectionFallback)
        } header: {
            Text("表情识别")
        } footer: {
            Text(
                "开着的时候，即使没检测到人脸也会给一个表情判定（准确率较低，结果会标注「可能不准」）。"
                + "关掉之后会提示你重拍，要求必须拍到完整人脸。"
            )
        }
    }

    private var storageSection: some View {
        Section {
            LabeledContent {
                Text("\(store.memories.count)")
                    .foregroundStyle(.secondary)
            } label: {
                Label("已归档照片", systemImage: "photo.stack")
            }

            Button {
                Task { await clearCache() }
            } label: {
                HStack {
                    Label("清除缩略图缓存", systemImage: "trash")
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
            Text("存储")
        } footer: {
            if let clearResult {
                Text(clearResult)
            } else {
                Text("缩略图会按需重建，原图不受影响。")
            }
        }
    }

    private var aboutSection: some View {
        Section {
            NavigationLink(value: Subpage.about) {
                Label("关于 Echoes", systemImage: "info.circle")
            }
            NavigationLink(value: Subpage.creators) {
                Label("开发团队", systemImage: "person.2")
            }
            NavigationLink(value: Subpage.feedback) {
                Label("反馈与建议", systemImage: "envelope")
            }
            NavigationLink(value: Subpage.rate) {
                Label("给我们评分", systemImage: "star")
            }
        } header: {
            Text("关于")
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
            ? "已释放 \(formattedByteCount(freed))。"
            : "没有可清理的缓存。"
    }
}

#Preview {
    let store = MemoryStore()
    return NavigationStack {
        SettingsView().environment(store)
    }
}
