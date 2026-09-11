//
//  EchoesApp.swift
//  Echoes
//

import SwiftUI
import UIKit

@main
struct EchoesApp: App {

    /// 归档仓库。整个应用只建一个，从 Environment 注入给各视图。
    @State private var store = MemoryStore()

    /// 拍照流程编排。依赖 store，所以在 init 里组装。
    @State private var capture: CaptureCoordinator

    /// 当前界面语言。变化时靠它重建整棵视图树 ——
    /// SwiftUI 不会因为字符串表变了就重新求值那些已经算过的 `Text`。
    @State private var language: AppLanguage = LanguageManager.current

    init() {
        let store = MemoryStore()
        _store = State(wrappedValue: store)
        _capture = State(wrappedValue: CaptureCoordinator.makeDefault(store: store))
        Self.configureNavigationBarAppearance()
    }

    var body: some Scene {
        WindowGroup {
            RootView(capture: capture)
                .environment(store)
                .environment(\.appLanguage, language)
                // 日期、数字等系统格式化也跟着界面语言走。
                .environment(\.locale, Locale(identifier: language.resolvedCode))
                // 语言一变就整体重建，不用重启应用 —— 这是「默认英文 + 可切换」
                // 能做到即时生效的关键。
                .id(language)
                .onReceive(
                    NotificationCenter.default.publisher(for: LanguageManager.didChangeNotification)
                ) { _ in
                    language = LanguageManager.current
                }
                .task {
                    // 迁移旧数据 + 读取归档清单。放在这里而不是 `init`，
                    // 是为了不阻塞首帧渲染。
                    await store.bootstrap()
                    #if DEBUG
                    await Self.runCaptureIfRequested(capture: capture)
                    #endif
                }
        }
    }

    #if DEBUG
    /// `-uiCaptureOnce` 启动后自动走一次拍照流程，效果等同于点一下相机键。
    ///
    /// `simctl` 没法模拟点击，这是在没有 UI 测试的情况下验证
    /// 「拍照 → 识别 → 预览」这条链路的唯一办法。
    private static func runCaptureIfRequested(capture: CaptureCoordinator) async {
        guard ProcessInfo.processInfo.arguments.contains("-uiCaptureOnce") else { return }
        // 稍等一下，让根视图先完成布局，否则预览页可能来不及呈现。
        try? await Task.sleep(for: .milliseconds(600))
        await capture.startCapture()
    }

    #endif

    /// 导航栏与标签栏统一用应用的 SmileySans 字体。
    ///
    /// 重构前这里配的是 `UITabBarAppearance` —— 那时中间那个"悬浮按钮"其实
    /// 寄生在一个 `TabView` 上。现在没有 TabView 了，改配导航栏。
    private static func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()

        let large = AppFont.navigationFont(size: 34, weight: .bold)
        let inline = AppFont.navigationFont(size: 17, weight: .semibold)

        appearance.largeTitleTextAttributes = [.font: large]
        appearance.titleTextAttributes = [.font: inline]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}
