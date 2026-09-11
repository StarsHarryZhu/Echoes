//
//  RootView.swift
//  Echoes
//

import SwiftUI

/// 两个归档维度。同时是底部 tab 栏的两个 tab。
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
        case .emotions: return "face.smiling.inverse"
        case .timeline: return "clock.arrow.circlepath"
        }
    }

    var accessibilityHint: String {
        switch self {
        case .emotions: return "按表情查看归档"
        case .timeline: return "按时间查看归档"
        }
    }
}

/// 导航目的地。
enum RootRoute: Hashable {
    case emotion(Emotion)
    case memory(Memory)
}

/// 应用根界面。
///
/// 布局对应需求：
/// - 底部 tab 栏**左侧**：按表情归档
/// - 底部 tab 栏**右侧**：按时间归档
/// - 底部**中间**：大圆拍照键，悬浮在 tab 栏之上
///
/// 重构前这里是个三页 `TabView`，中间那页塞了个空 `Text("")`、再靠 `onChange`
/// 把选中项弹回去，只为做出"中间悬浮按钮"的视觉效果。现在 tab 数量与"两个归档"
/// 一致，不需要假的中间页。
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
            TabView(selection: $section) {
                Tab(RootSection.emotions.title, systemImage: RootSection.emotions.symbol, value: .emotions) {
                    browser
                }
                Tab(RootSection.timeline.title, systemImage: RootSection.timeline.symbol, value: .timeline) {
                    browser
                }
            }
            // 点击 tab 当前项时回到列表根，而不是什么都不做。
            .onChange(of: section) { _, _ in path.removeAll() }

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

    /// 一个归档页 —— 自带导航栈与标题栏。
    ///
    /// 每个 tab 各建一个 `NavigationStack`：这样两个归档各自维护自己的导航位置，
    /// 来回切 tab 时不会丢掉对方进到哪一层（用一条共享 path 的话，
    /// 在表情归档里点进某个表情，切到时间归档会对不上）。
    ///
    /// 注意 `.toolbar` / `.navigationDestination` 是挂在**外层**的。
    /// 第一版把它们挂在 `content`（一个按 tab 分支的 `switch`）上，
    /// 结果切到时间归档时导航栏和 tab 栏整个消失 —— 那是另一棵视图树，
    /// 修饰符不会跟过去。
    private var browser: some View {
        NavigationStack(path: $path) {
            content
                .navigationTitle(AppInfo.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
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
    }

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

    // MARK: - 导航栏

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

    /// 底部中间的大圆拍照键，悬浮在 tab 栏上方。
    ///
    /// ZStack 里的底部对齐会被安全区顶到 tab 栏之上，再加一点间距就是最终位置。
    private var shutter: some View {
        ShutterButton(isBusy: capture.phase.isBusy) {
            Task { await capture.startCapture() }
        }
        .padding(.bottom, 8)
    }
}

#Preview {
    let store = MemoryStore()
    return RootView()
        .environment(store)
        .environment(CaptureCoordinator.makeDefault(store: store))
}
