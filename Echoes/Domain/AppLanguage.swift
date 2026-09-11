//
//  AppLanguage.swift
//  Echoes
//

import Foundation
import SwiftUI

/// 界面语言。
///
/// 默认英文；可以跟随系统，也可以在设置里手动指定。
nonisolated enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    /// 跟随系统语言（系统不是中文时用英文）。
    case system
    case english = "en"
    case simplifiedChinese = "zh-Hans"

    var id: String { rawValue }

    /// 在设置里显示的名字。**用该语言自己的写法**，这样即使界面已经是英文，
    /// 中文用户也能认出「简体中文」。
    var displayName: String {
        switch self {
        case .system: return L10n.languageSystem
        case .english: return "English"
        case .simplifiedChinese: return "简体中文"
        }
    }

    /// 实际生效的本地化代码（`.system` 会解析成具体语言）。
    var resolvedCode: String {
        switch self {
        case .system: return AppLanguage.systemPreferredCode
        case .english: return "en"
        case .simplifiedChinese: return "zh-Hans"
        }
    }

    /// 系统当前语言里是否有简体中文。
    static var systemPreferredCode: String {
        let preferred = Locale.preferredLanguages.first ?? "en"
        return preferred.hasPrefix("zh") ? "zh-Hans" : "en"
    }
}

/// 语言设置的读写与"当前生效的字符串表"。
///
/// 运行时不重启切换语言靠的是**自己定位对应的 `.lproj` bundle**，
/// 而不是改 `AppleLanguages` —— 后者要重启才生效。
///
/// 视图侧由 `EchoesApp` 监听 `.appLanguageDidChange` 并重建视图树。
///
/// 整体是非隔离的：`L10n` 会在后台 actor 的 `LocalizedError` 实现里查字符串，
/// 而 `DateFormatters` 也要读当前语言。读写的是 `UserDefaults` 与文件系统，
/// 都是线程安全的，所以没必要把它关进某个 actor —— 那样反而处处要 `await`。
nonisolated enum LanguageManager {

    /// 语言变化通知。`EchoesApp` 收到后换掉根视图的 `id` 强制重建。
    static let didChangeNotification = Notification.Name("appLanguageDidChange")

    private static let storageKey = "app.language"

    static var current: AppLanguage {
        get {
            guard let raw = UserDefaults.standard.string(forKey: storageKey),
                  let language = AppLanguage(rawValue: raw) else {
                return .system
            }
            return language
        }
        set {
            guard newValue != current else { return }
            // 切换会驱动界面重建，必须在主线程上做。
            // 读可以在任意线程（`L10n` 要这么用），写不行。
            precondition(Thread.isMainThread, "切换界面语言必须在主线程上进行")
            UserDefaults.standard.set(newValue.rawValue, forKey: storageKey)
            L10nBundleCache.invalidate()
            DateFormatters.resetCache()
            NotificationCenter.default.post(name: didChangeNotification, object: nil)
        }
    }

    /// 当前生效的本地化代码，供 `\\.environment(\\.locale, …)` 使用。
    static var resolvedCode: String { current.resolvedCode }
}

/// 查找字符串用的 `.lproj` bundle。
///
/// 必须是非隔离的：`L10n` 会在后台 actor 的 `LocalizedError` 实现里被调用。
/// 缓存的数据全部来自 `UserDefaults` 与文件系统，本身线程安全，
/// 所以用 `nonisolated(unsafe)` 显式承诺这里的读写是安全的 ——
/// 唯一会变的是语言切换时整体替换，而那次替换发生在主线程、
/// 且紧跟着会重建整棵视图树。
nonisolated enum L10nBundleCache {

    /// 语言变化时调用。
    static func invalidate() {
        cached = nil
    }

    static var bundle: Bundle {
        if let cached { return cached }

        let code = LanguageManager.current.resolvedCode
        let resolved: Bundle
        if let path = Bundle.main.path(forResource: code, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            resolved = bundle
        } else {
            // 还没有对应的本地化目录时退回主 bundle。
            // `.xcstrings` 编出来的表就在主 bundle 里，所以英文（源语言）依然可用。
            resolved = .main
        }
        cached = resolved
        return resolved
    }

    nonisolated(unsafe) private static var cached: Bundle?
}

// MARK: - 视图读取

/// 把当前语言作为环境值下发。
///
/// 视图本身不需要读它 —— `L10n` 直接查表。它的作用是让**语言一变，
/// 依赖它的视图就重新求值**，这样不用重启也能刷新文案。
private struct AppLanguageKey: EnvironmentKey {
    static let defaultValue = AppLanguage.system
}

extension EnvironmentValues {
    var appLanguage: AppLanguage {
        get { self[AppLanguageKey.self] }
        set { self[AppLanguageKey.self] = newValue }
    }
}
