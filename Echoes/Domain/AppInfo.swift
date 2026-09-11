//
//  AppInfo.swift
//  Echoes
//

import Foundation

/// 全应用共享的静态常量。
///
/// 收敛了重构前散落在 `Constants.swift` 各处的 `tabview_words` / `tabview_images` /
/// `camera_button` / `text_info` / `camera_info` 等小结构体。
nonisolated enum AppInfo {

    /// 应用展示名。
    static let name = "Echoes"

    /// 标语。
    static let tagline = "Capture emotions. Keep memories."

    // MARK: 字体

    /// 随包字体 `SmileySans.otf` 的 PostScript 名。
    /// 通过 `Info.plist` 的 `UIAppFonts` 注册。
    static let fontName = "SmileySans-Oblique"

    // MARK: App Store

    /// TODO: 上架前替换为真实的 App Store ID。
    /// 目前是占位符，`RateUsView` 的「Open App Store」按钮在替换前会打不开页面。
    static let appStoreID = "0000000000"

    /// 反馈邮箱。
    static let feedbackEmail = "feedback@echoes.app"

    // MARK: 资源

    /// DEBUG 下模拟器没有相机时用来跑通识别管线的采样图。
    nonisolated enum SampleImage {
        static let names = ["sample1", "sample2", "sample3", "sample4"]
        /// 若某张图缺失，回退到这张。
        static let fallback = "sample1"
    }
}

/// `UserDefaults` 的键。集中放一处，避免字符串散落各处拼错。
nonisolated enum AppPreferenceKey {
    /// 时间归档的分组粒度。
    static let timelineGranularity = "timeline.granularity"
    /// 检测不到人脸时，是否退回"整图识别"。
    static let faceDetectionFallback = "analysis.faceDetectionFallback"
}

/// 关于页使用的长文案。放这里而不是散在 `Constants.swift` 里，
/// 便于将来整体替换为 String Catalog。
nonisolated enum AppCopy {

    static let creatorsIntro = """
    Echoes is built by a small team who believe photos are more than pixels — they're emotions and \
    stories. We design calm, human-centered tools that help you capture feelings and revisit \
    memories with care.
    """

    static let rateUs = "If you like Echoes, a 5-star rating really helps! ✨"
}
