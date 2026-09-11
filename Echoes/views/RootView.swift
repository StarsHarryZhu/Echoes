//
//  RootView.swift
//  Echoes
//

import SwiftUI

/// 两个归档维度，也就是 tab 栏里除中间空位以外的两项。
///
/// 相机是底部中间的悬浮按钮，**不是 tab** —— 与重构前的做法一致：
/// tab 栏三页，中间那页留空只为给悬浮按钮让出位置。
enum RootSection: String, CaseIterable, Hashable, Identifiable {
    case emotions
    case timeline

    var id: String { rawValue }

    var title: String {
        switch self {
        case .emotions: return L10n.tabEmotions
        case .timeline: return L10n.tabTimeline
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
        case .emotions: return L10n.tabEmotionsHint
        case .timeline: return L10n.tabTimelineHint
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
/// 布局与重构前一致：
/// - 底部 tab 栏**左侧**：按表情归档
/// - 底部 tab 栏**中间**：空占位页（只为给悬浮按钮让位置）
/// - 底部 tab 栏**右侧**：按时间归档
/// - 底部**中间**：圆形拍照键，悬浮在 tab 栏之上
struct RootView: View {

    @Environment(MemoryStore.self) private var store

    /// 直接用构造参数注入，不走 `@Environment`。
    /// 手势闭包里访问它不需要可变捕获，省掉一层隔离相关的麻烦。
    let capture: CaptureCoordinator

    /// TabView 的选中项。用 Int 而不是枚举，是为了原样保留
    /// 「中间那个空占位 tab」的写法（它的 tag 是 1）。
    @State private var selectedTab: Int = Self.initialTab
    /// 最近一次选中的归档。相机是悬浮按钮不是 tab，所以它不参与 tab 选中态。
    @State private var lastBrowsingSection: RootSection = Self.initialSection
    @State private var path: [RootRoute] = []
    @State private var isShowingSettings = Self.opensSettingsAtLaunch

    // MARK: Tab 下标（与重构前一致：0 表情、1 空占位、2 时间）
    private static let emotionsTag = 0
    private static let placeholderTag = 1
    private static let timelineTag = 2

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

    /// 初始选中的 tab 下标。
    private static var initialTab: Int {
        initialSection == .timeline ? timelineTag : emotionsTag
    }

    /// DEBUG 下 `-uiShowSettings` 直接打开设置页，方便在没有点击能力的环境里截图。
    private static var opensSettingsAtLaunch: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains("-uiShowSettings")
        #else
        return false
        #endif
    }

    var body: some View {
        // 恢复重构前的结构：三页 TabView（中间那页是空的占位 tab）+
        // 底部中间悬浮的圆形拍照键压在 tab 栏正中。
        //
        // 「完全按原样」是明确的选择 —— 包括圆钮会盖住 tab 栏中间那部分。
        // 中间那页本来就是空的、且永远选不中（见下面的 `onChange`），
        // 所以遮挡落在空处，不影响任何 tab 的可用性。
        ZStack {
            TabView(selection: $selectedTab) {
                tab(for: .emotions, tag: Self.emotionsTag) {
                    EmotionAlbumView { emotion in
                        path.append(.emotion(emotion))
                    }
                }

                // 空的占位 tab，只为给中间的悬浮按钮让出位置。
                Text("")
                    .tabItem { Label("", systemImage: "") }
                    .tag(Self.placeholderTag)

                tab(for: .timeline, tag: Self.timelineTag) {
                    TimelineView { memory in
                        path.append(.memory(memory))
                    }
                }
            }
            .onChange(of: selectedTab) { old, new in
                if new == Self.placeholderTag {
                    selectedTab = old
                    return
                }
                lastBrowsingSection = (new == Self.timelineTag) ? .timeline : .emotions
                // 切归档时回到列表根，而不是停在上一个归档的详情页上。
                path.removeAll()
            }

            // 中间悬浮相机按钮
            VStack {
                Spacer()
                CameraButton(isBusy: capture.phase.isBusy) {
                    Task { await capture.startCapture() }
                }
                .padding(.bottom, 25)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .fullScreenCover(isPresented: $isShowingSettings) {
            NavigationStack { SettingsView() }
        }
        .alert(
            L10n.somethingWentWrong,
            isPresented: isShowingFailure,
            presenting: failureMessage
        ) { _ in
            Button(L10n.ok, role: .cancel) { capture.clearFailure() }
        } message: { message in
            Text(message)
        }
        .sheet(isPresented: isReviewing) {
            if case .reviewing(let report) = capture.phase, let image = capture.pendingImage {
                CaptureReviewView(image: image, report: report)
                    .environment(capture)
                    .environment(store)
            }
        }
    }

    /// 一个归档 tab：自带导航栈、标题栏与设置入口。
    private func tab<Content: View>(
        for section: RootSection,
        tag: Int,
        @ViewBuilder content: () -> Content
    ) -> some View {
        NavigationStack(path: $path) {
            content()
                .navigationTitle(L10n.appName)
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
        .tabItem {
            Label(section.title, systemImage: section.symbol)
        }
        .tag(tag)
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
        .accessibilityLabel(L10n.settings)
    }

    // MARK: - 快门

}

#Preview {
    let store = MemoryStore()
    return RootView(capture: CaptureCoordinator.makeDefault(store: store))
        .environment(store)
}
