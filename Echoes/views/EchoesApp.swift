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
                    await Self.seedSampleDataIfRequested(store: store)
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

    /// 用启动参数预置几条示例记录，便于在模拟器（没有相机）上验证归档界面。
    ///
    ///     xcrun simctl launch <device> com.Echoesone.Echoes -uiSeedSampleData
    ///
    /// 只在 DEBUG 编译里存在，Release 包里没有这段代码。
    private static func seedSampleDataIfRequested(store: MemoryStore) async {
        guard ProcessInfo.processInfo.arguments.contains("-uiSeedSampleData") else { return }
        guard store.memories.isEmpty else { return }

        // 每条都跑完整识别管线，产出的记录与真机拍照完全同构；
        // 时间刻意跨越"今天 / 昨天 / 本周 / 本月 / 更早"，好验证时间归档的分组。
        let emotions: [Emotion] = [.happy, .neutral, .surprise, .sad, .angry]
        let hoursAgo: [Int] = [1, 30, 6 * 24, 20 * 24, 130 * 24]
        for (index, expected) in emotions.enumerated() {
            let name = AppInfo.SampleImage.names[index % AppInfo.SampleImage.names.count]
            guard let image = UIImage(named: name) else { continue }

            let report: EmotionReport
            if let analyzed = try? await EmotionAnalyzer.shared.analyze(image: image) {
                report = analyzed
            } else {
                // 采样图里没人脸时造一条最小可用的报告，保证界面有数据可渲染。
                report = EmotionReport(
                    emotion: expected,
                    confidence: 0.5,
                    rankedScores: Emotion.allCases.map {
                        EmotionReport.Score(emotion: $0, confidence: $0 == expected ? 0.5 : 0.5 / 6)
                    },
                    faceBox: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5)
                )
            }

            let capturedAt = Calendar.current.date(
                byAdding: .hour,
                value: -(hoursAgo[index % hoursAgo.count]),
                to: Date()
            ) ?? Date()
            _ = try? await store.add(image: image, report: report, capturedAt: capturedAt)
        }
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
