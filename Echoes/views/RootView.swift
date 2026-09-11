//
//  RootView.swift
//  Echoes
//

import SwiftUI

/// 两个归档维度的切换状态。
enum RootSection: String, CaseIterable, Hashable, Identifiable {
    case emotions
    case timeline

    var id: String { rawValue }

    var title: String {
        switch self {
        case .emotions: return "Emotions"
        case .timeline: return "Timeline"
        }
    }

    var symbol: String {
        switch self {
        case .emotions: return "face.smiling"
        case .timeline: return "clock.arrow.circlepath"
        }
    }
}

/// 导航目的地。两个归档共用一条 `NavigationStack` 路径。
enum RootRoute: Hashable {
    case emotion(Emotion)
    case memory(Memory)
}

/// 应用根界面。
///
/// 布局对应需求：
/// - 导航栏**左侧**：按表情归档
/// - 导航栏**右侧**：按时间归档
/// - 底部中间：大圆拍照键（沿用原先 tabview 那种中间悬浮键的观感）
///
/// 重构前这里是个 `TabView`，为了做出"中间按钮"的视觉效果硬塞了一个
/// 空 `Text("")` 当第二页、再靠 `onChange` 把选中项弹回去 —— 既拿不到真正的
/// 无 Tab 布局，也让导航栏里同时存在标题和齿轮两套东西。
struct RootView: View {

    @Environment(MemoryStore.self) private var store
    @Environment(CaptureCoordinator.self) private var capture

    @State private var section: RootSection = Self.initialSection
    @State private var path: [RootRoute] = []
    @State private var isShowingSettings = false

    /// 初始归档页。
    ///
    /// DEBUG 下可以用 `-uiStartSection timeline` 直接打开时间归档 ——
    /// `simctl` 没法模拟点击，这是在没有 UI 测试的情况下检查另一个归档布局的
    /// 唯一办法（也给将来的 UI 测试留了入口）。Release 里恒定从表情归档开始。
    private static var initialSection: RootSection {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-uiStartSection"),
           arguments.index(after: index) < arguments.endIndex,
           let requested = RootSection(rawValue: arguments[arguments.index(after: index)]) {
            return requested
        }
        #endif
        return .emotions
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            NavigationStack(path: $path) {
                content
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            sectionButton(.emotions)
                        }
                        ToolbarItem(placement: .principal) {
                            Text(AppInfo.name)
                                .appText(20, weight: .bold)
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            sectionButton(.timeline)
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            settingsButton
                        }
                    }
                    .navigationDestination(for: RootRoute.self) { route in
                        switch route {
                        case .emotion(let emotion):
                            EmotionListView(emotion: emotion) { memory in
                                path.append(.memory(memory))
                            }
                        case .memory(let memory):
                            MemoryDetailView(memory: memory)
                        }
                    }
            }

            shutter
        }
        .fullScreenCover(isPresented: $isShowingSettings) {
            NavigationStack { SettingsView() }
        }
        .sheet(isPresented: isReviewing) {
            if case .reviewing(let report) = capture.phase, let image = capture.pendingImage {
                CaptureReviewView(image: image, report: report)
                    .environment(capture)
                    .environment(store)
            }
        }
        .alert(
            "出错了",
            isPresented: isShowingFailure,
            presenting: failureMessage
        ) { _ in
            Button("好", role: .cancel) { capture.clearFailure() }
        } message: { message in
            Text(message)
        }
    }

    // MARK: - 弹窗绑定

    private var isReviewing: Binding<Bool> {
        Binding(
            get: {
                if case .reviewing = capture.phase { return true }
                return false
            },
            set: { newValue in
                // 用户下滑关掉预览页 = 放弃这次拍照。但保存流程本身会把 phase
                // 从 .reviewing 切到 .saving（同样是 false），那种情况下不能清状态。
                if !newValue, !capture.hasCommittedReview {
                    capture.discardPendingMemory()
                }
            }
        )
    }

    private var isShowingFailure: Binding<Bool> {
        Binding(
            get: {
                if case .failed = capture.phase { return true }
                return false
            },
            set: { newValue in
                if !newValue { capture.clearFailure() }
            }
        )
    }

    private var failureMessage: String? {
        if case .failed(let message) = capture.phase { return message }
        return nil
    }

    // MARK: - 内容

    @ViewBuilder
    private var content: some View {
        switch section {
        case .emotions:
            EmotionAlbumView { emotion in
                path.append(.emotion(emotion))
            }
        case .timeline:
            TimelineView { memory in
                path.append(.memory(memory))
            }
        }
    }

    // MARK: - 导航栏按钮

    /// 归档维度切换按钮。
    ///
    /// 只放图标不放文字：导航栏里挤了三个控件，带文字的版本在窄屏上会被截断
    /// （实测 iPhone 17 Pro 上「Emotions」已经显示不下）。语义交给无障碍标签。
    private func sectionButton(_ target: RootSection) -> some View {
        Button {
            guard section != target else { return }
            section = target
            // 切归档时回到列表根，否则会停在上一个归档的详情页上。
            path.removeAll()
        } label: {
            Image(systemName: target.symbol)
                .imageScale(.large)
                .fontWeight(section == target ? .bold : .regular)
                .symbolVariant(section == target ? .fill : .none)
                .foregroundStyle(section == target ? Color.primary : Color.secondary)
                .contentShape(Rectangle())
                .frame(minWidth: 32, minHeight: 32)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(target.title)
        .accessibilityHint(target == .emotions ? "按表情查看归档" : "按时间查看归档")
        .accessibilityAddTraits(section == target ? [.isSelected] : [])
    }

    private var settingsButton: some View {
        Button {
            isShowingSettings = true
        } label: {
            Image(systemName: "gearshape")
                .imageScale(.large)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("设置")
    }

    // MARK: - 快门

    private var shutter: some View {
        ShutterButton(isBusy: capture.phase.isBusy) {
            Task { await capture.startCapture() }
        }
        .padding(.bottom, 12)
    }
}

#Preview {
    let store = MemoryStore()
    return RootView()
        .environment(store)
        .environment(CaptureCoordinator.makeDefault(store: store))
}
