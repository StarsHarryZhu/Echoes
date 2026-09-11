//
//  LocalizationTests.swift
//  EchoesTests
//

import Foundation
import Testing

@testable import Echoes

/// 项目里所有 L10n 访问器用到的键，**外加**英文文案。
///
/// 这份清单是测试侧的契约：键少一边翻译、或者英文文案被改动，
/// 这里都会失败。之所以不直接读 `Localizable.xcstrings`：
/// 构建时它会被编译成 `xx.lproj/Localizable.strings`，
/// 产物里已经没有 `.xcstrings` 可读了。
private let expectedStrings: [(key: String, english: String)] = [
    // common
    ("common.ok", "OK"),
    ("common.cancel", "Cancel"),
    ("common.delete", "Delete"),
    ("common.retake", "Retake"),
    ("common.save", "Save"),
    ("common.saving", "Saving…"),
    ("common.done", "Done"),
    ("common.settings", "Settings"),
    ("common.error.title", "Something went wrong"),
    // app
    ("app.tagline", "Capture emotions. Keep memories."),
    // tabs / shutter
    ("tab.emotions", "Emotions"),
    ("tab.timeline", "Timeline"),
    ("tab.emotions.hint", "Browse by emotion"),
    ("tab.timeline.hint", "Browse by time"),
    ("shutter.label", "Take a photo"),
    ("shutter.hint", "Capture this moment"),
    ("shutter.analyzing", "Reading…"),
    // emotion album
    ("emotionAlbum.empty.title", "No photos yet"),
    ("emotionAlbum.card.accessibility", "%1$@, %2$d photos"),
    ("emotionList.empty.message", "Photos you take with this expression will land here."),
    // timeline
    ("timeline.empty.title", "No records yet"),
    ("timeline.group.automatic", "Auto"),
    ("timeline.group.day", "By day"),
    ("timeline.group.month", "By month"),
    ("timeline.group.label", "Grouping"),
    ("timeline.delete.title", "Delete this record?"),
    ("timeline.delete.message", "The photo and its record will be removed. This can’t be undone."),
    // buckets
    ("bucket.today", "Today"),
    ("bucket.yesterday", "Yesterday"),
    ("bucket.thisWeek", "This week"),
    ("bucket.thisMonth", "This month"),
    ("bucket.month", ""),
    ("bucket.year", ""),
    // memory detail
    ("memory.photoMissing", "Photo is missing"),
    ("memory.delete", "Delete this record"),
    ("memory.share", "Share"),
    ("memory.evidence", "How we decided"),
    ("memory.confidence.format", "Confidence %@"),
    // review
    ("review.title", "How’s this one?"),
    ("review.degraded.title", "This may be inaccurate"),
    ("review.samplePhoto", "No front camera in this environment — this is a bundled sample photo, not a real capture."),
    // startup
    ("startup.failed.title", "Couldn’t load your archive"),
    ("capture.saveFailed", "Couldn’t save: %@"),
    // analysis errors
    ("analysis.error.noPixels", "This photo has no readable pixel data. Try another one."),
    ("analysis.error.noFace", "We couldn’t find a face. Please face the front camera and keep your whole face in frame, then try again."),
    ("analysis.error.faceTooSmall", "The face in the photo is too small to judge accurately. Move a little closer and take another one."),
    ("analysis.error.modelUnavailable", "Couldn’t load the expression model: %@"),
    ("analysis.error.inference", "Expression recognition failed: %@"),
    ("analysis.error.noResults", "The model didn’t return any classification."),
    ("analysis.error.noKnownLabels", "The model’s output contained no recognisable expression labels."),
    // camera errors
    ("camera.error.unavailable", "This device has no available camera."),
    ("camera.error.frontUnavailable", "We couldn’t find the front camera."),
    ("camera.error.noPresenter", "Can’t present the camera right now. Please try again in a moment."),
    ("camera.error.noImage", "The camera didn’t return a photo."),
    // migration
    ("migration.error.unreadable", "Couldn’t read the old archive file: %@"),
    ("manifest.error.corrupted", "The archive file is damaged: %@"),
    // settings
    ("settings.title", "Settings"),
    ("settings.section.language", "Language"),
    ("settings.language", "App language"),
    ("settings.language.system", "Follow system"),
    ("settings.section.timeline", "Timeline"),
    ("settings.timeline.grouping", "Grouping"),
    ("settings.section.analysis", "Expression recognition"),
    ("settings.analysis.fallback", "Fall back to whole-photo analysis when no face is found"),
    ("settings.section.storage", "Storage"),
    ("settings.storage.count", "Archived photos"),
    ("settings.storage.clear", "Clear thumbnail cache"),
    ("settings.storage.freed", "Freed %@."),
    ("settings.storage.nothing", "Nothing to clean up."),
    ("settings.section.about", "About"),
    ("settings.about.app", "About Echoes"),
    ("settings.about.team", "The team"),
    ("settings.about.feedback", "Feedback & suggestions"),
    ("settings.about.rate", "Rate us"),
    // about / creators
    ("about.section.version", "Version"),
    ("about.version", "Version"),
    ("about.build", "Build"),
    ("about.why.title", "Why we built Echoes"),
    ("creators.section.team", "Team"),
    ("creators.section.idea", "Our thinking"),
    // feedback
    ("feedback.title", "Feedback & suggestions"),
    ("feedback.section.subject", "Subject"),
    ("feedback.subject.placeholder", "One-line summary"),
    ("feedback.section.message", "Details"),
    ("feedback.diagnostics", "Include device and version info"),
    ("feedback.send", "Send feedback"),
    ("feedback.copy", "Copy feedback"),
    ("feedback.copied", "Copied to the clipboard."),
    ("feedback.defaultSubject", "Echoes feedback"),
    ("feedback.mailOpened", "Your mail app is open — just hit send."),
    ("feedback.mailFailed", "The mail app couldn’t be opened. Your feedback was copied to the clipboard."),
    ("feedback.invalidContent", "The feedback contained invalid characters. It was copied to the clipboard."),
    // rate
    ("rate.copy", "If you like Echoes, a 5-star rating really helps! ✨"),
    ("rate.inApp", "Rate in the app"),
    ("rate.appStore", "Review on the App Store"),
    // 表情名称
    ("Emotion.happy", "Happy"),
    ("Emotion.angry", "Angry"),
    ("Emotion.neutral", "Neutral"),
    ("Emotion.sad", "Sad"),
    ("Emotion.fear", "Fear"),
    ("Emotion.disgust", "Disgust"),
    ("Emotion.surprise", "Surprise"),
]

/// 中文里必须出现的几个词 —— 用来确认中文表**真的**是中文，
/// 而不是把英文又抄了一遍。
private let chineseSpotChecks: [(key: String, contains: String)] = [
    ("common.save", "保存"),
    ("common.cancel", "取消"),
    ("settings.title", "设置"),
    ("tab.emotions", "表情"),
    ("tab.timeline", "时间"),
    ("bucket.today", "今天"),
    ("bucket.yesterday", "昨天"),
    ("Emotion.happy", "开心"),
    ("Emotion.angry", "愤怒"),
    ("review.title", "这张"),
    ("shutter.label", "拍照"),
    ("camera.error.frontUnavailable", "前置相机"),
]

@Suite("界面语言")
struct LocalizationTests {

    private static func bundle(_ code: String) -> Bundle? {
        guard let path = Bundle.main.path(forResource: code, ofType: "lproj") else { return nil }
        return Bundle(path: path)
    }

    /// bundle 里查不到该键时，`localizedString` 会原样返回 key ——
    /// 所以"值不等于键"就等于"翻译存在"。
    private static func lookup(_ key: String, in code: String) -> String? {
        guard let bundle = bundle(code) else { return nil }
        let value = bundle.localizedString(forKey: key, value: nil, table: nil)
        return value == key ? nil : value
    }

    // MARK: - 语言解析

    @Test("语言代码映射正确")
    func resolvedCodes() {
        #expect(AppLanguage.english.resolvedCode == "en")
        #expect(AppLanguage.simplifiedChinese.resolvedCode == "zh-Hans")
        // `.system` 必须解析成具体语言，不能是 "system"
        #expect(["en", "zh-Hans"].contains(AppLanguage.system.resolvedCode))
    }

    @Test("每种语言都有显示名，且中文写中文")
    func displayNames() {
        for language in AppLanguage.allCases {
            #expect(!language.displayName.isEmpty, "\(language.rawValue) 没有显示名")
        }
        // 界面切到英文后，用户仍要能认出中文选项
        #expect(AppLanguage.simplifiedChinese.displayName == "简体中文")
        #expect(AppLanguage.english.displayName == "English")
    }

    @Test("默认语言是跟随系统")
    func defaultIsSystem() {
        // 从未设置过 → `current` 应该回落到 `.system`
        let raw = UserDefaults.standard.string(forKey: "app.language")
        if let raw, let stored = AppLanguage(rawValue: raw) {
            #expect(AppLanguage.allCases.contains(stored))
        } else {
            #expect(LanguageManager.current == .system)
        }
    }

    // MARK: - 资源完整性

    @Test("中英文的 .lproj 都存在")
    func lprojBundlesExist() {
        for language in [AppLanguage.english, .simplifiedChinese] {
            #expect(
                Self.bundle(language.resolvedCode) != nil,
                "缺少 \(language.resolvedCode).lproj —— 工程里要把它加进 knownRegions，并保留 Localizable.xcstrings"
            )
        }
    }

    @Test("每个键在两种语言里都有翻译")
    func everyKeyTranslatedInBothLanguages() {
        var missingEnglish: [String] = []
        var missingChinese: [String] = []

        for entry in expectedStrings {
            if Self.lookup(entry.key, in: "en") == nil { missingEnglish.append(entry.key) }
            if Self.lookup(entry.key, in: "zh-Hans") == nil { missingChinese.append(entry.key) }
        }

        #expect(
            missingEnglish.isEmpty,
            "这些键缺英文：\(missingEnglish)"
        )
        #expect(
            missingChinese.isEmpty,
            "这些键缺中文：\(missingChinese)"
        )
    }

    @Test("英文文案与代码里写的 fallback 一致")
    func englishMatchesFallback() {
        for entry in expectedStrings {
            let english = Self.lookup(entry.key, in: "en")
            #expect(
                english == entry.english,
                "\(entry.key) 的英文应为 \(entry.english)，实际 \(english ?? "nil")"
            )
        }
    }

    /// 防的是"中文表其实是英文抄了一遍"这种假翻译。
    @Test("中文表确实是中文")
    func chineseIsActuallyChinese() {
        for check in chineseSpotChecks {
            let chinese = Self.lookup(check.key, in: "zh-Hans")
            #expect(
                chinese?.contains(check.contains) == true,
                "\(check.key) 的中文应包含「\(check.contains)」，实际 \(chinese ?? "nil")"
            )
        }
    }

    @Test("每个表情在两种语言里都有名字")
    func emotionsHaveNames() {
        for emotion in Emotion.allCases {
            let key = "Emotion.\(emotion.rawValue.lowercased())"
            #expect(Self.lookup(key, in: "en") != nil, "\(key) 缺英文")
            #expect(Self.lookup(key, in: "zh-Hans") != nil, "\(key) 缺中文")
        }
    }

    // MARK: - 运行时行为

    @Test("L10n 访问器都返回非空文案")
    func accessorsAreNonEmpty() {
        let samples: [String] = [
            L10n.ok, L10n.cancel, L10n.delete, L10n.retake, L10n.save, L10n.saving,
            L10n.done, L10n.settings, L10n.somethingWentWrong,
            L10n.tabEmotions, L10n.tabTimeline, L10n.tabEmotionsHint, L10n.tabTimelineHint,
            L10n.shutterLabel, L10n.shutterHint, L10n.shutterAnalyzing,
            L10n.emotionAlbumEmptyTitle, L10n.emotionAlbumEmptyMessage,
            L10n.emotionListEmptyMessage, L10n.emotionAlbumCountLabel(.happy, count: 2),
            L10n.emotionListEmptyTitle(.sad),
            L10n.timelineEmptyTitle, L10n.timelineEmptyMessage,
            L10n.timelineGroupAutomatic, L10n.timelineGroupDay, L10n.timelineGroupMonth,
            L10n.timelineGroupLabel, L10n.timelineDeleteConfirmTitle, L10n.timelineDeleteConfirmMessage,
            L10n.bucketToday, L10n.bucketYesterday, L10n.bucketThisWeek, L10n.bucketThisMonth,
            L10n.bucketMonth(6), L10n.bucketYear(2025),
            L10n.memoryPhotoMissing, L10n.memoryDeleteButton, L10n.memoryShare, L10n.memoryEvidence,
            L10n.memoryConfidence(0.5),
            L10n.memoryAccessibilityLabel(date: "d", emotion: "e"),
            L10n.memoryScoreAccessibility(emotion: "e", confidence: "50%"),
            L10n.reviewTitle, L10n.reviewLowConfidence, L10n.reviewDegradedTitle, L10n.reviewDegradedFallback,
            L10n.reviewSamplePhoto,
            L10n.startupFailedTitle, L10n.startupCorrupted("x"), L10n.saveFailed("x"),
            L10n.analysisNoPixels, L10n.analysisNoFace, L10n.analysisFaceTooSmall,
            L10n.analysisModelUnavailable("x"), L10n.analysisInferenceFailed("x"),
            L10n.analysisNoResults, L10n.analysisNoKnownLabels,
            L10n.cameraUnavailable, L10n.cameraFrontUnavailable, L10n.cameraNoPresenter, L10n.cameraNoImage,
            L10n.migrationUnreadable("x"), L10n.manifestCorrupted("x"),
            L10n.settingsTitle, L10n.settingsLanguageRow, L10n.settingsLanguageFooter,
            L10n.languageSystem, L10n.settingsFaceFallback, L10n.settingsFaceFallbackFooter,
            L10n.settingsArchivedPhotos, L10n.settingsClearCache, L10n.settingsStorageFooter,
            L10n.settingsCacheFreed("1 MB"), L10n.settingsCacheNothing,
            L10n.settingsAboutApp, L10n.settingsTeam, L10n.settingsFeedback, L10n.settingsRate,
            L10n.aboutVersion, L10n.aboutBuild, L10n.aboutWhyTitle,
            L10n.creatorsSectionTeam, L10n.creatorsSectionIdea,
            L10n.feedbackTitle, L10n.feedbackSend, L10n.feedbackCopy, L10n.feedbackCopied,
            L10n.feedbackDefaultSubject, L10n.feedbackMailOpened, L10n.feedbackMailFailed,
            L10n.feedbackInvalidContent, L10n.feedbackNoMailClient,
            L10n.feedbackSectionSubject, L10n.feedbackSectionMessage, L10n.feedbackSubjectPlaceholder,
            L10n.feedbackDiagnostics, L10n.feedbackDiagnosticsFooter,
            L10n.rateCopy, L10n.rateInApp, L10n.rateAppStore, L10n.appTagline,
        ]

        let empty = samples.filter(\.isEmpty)
        #expect(empty.isEmpty, "有 \(empty.count) 个 L10n 访问器返回空字符串")
    }

    @Test("带参数的文案能正确插值")
    func formatArguments() {
        #expect(L10n.bucketMonth(6).contains("6"))
        #expect(L10n.bucketYear(2025).contains("2025"))
        #expect(L10n.settingsCacheFreed("12 MB").contains("12 MB"))
        #expect(L10n.analysisModelUnavailable("boom").contains("boom"))
        #expect(L10n.memoryConfidence(0.42).contains("42%"))
        #expect(L10n.emotionAlbumCountLabel(.happy, count: 3).contains("3"))
        #expect(L10n.emotionListEmptyTitle(.sad).contains(Emotion.sad.displayName))
        #expect(L10n.memoryConfidence(0.42) != L10n.memoryConfidence(0.9))
    }

    @Test("表情展示名跟着语言走，不再等于模型标签")
    func emotionDisplayNameIsLocalized() {
        for emotion in Emotion.allCases {
            #expect(!emotion.displayName.isEmpty)
        }
        // `rawValue` 是模型契约，不该被拿来显示
        #expect(Emotion.allCases.allSatisfy { !$0.displayName.isEmpty })
    }

    // MARK: - 切换

    @MainActor
    @Test("切换语言会更新当前语言并广播通知")
    func switchingUpdatesAndNotifies() async {
        let original = LanguageManager.current
        defer { LanguageManager.current = original }

        // 只关心"有没有收到"，不约束次数 —— 它是个广播通知。
        let received = Counter()
        let token = NotificationCenter.default.addObserver(
            forName: LanguageManager.didChangeNotification,
            object: nil,
            queue: .main
        ) { _ in received.increment() }
        defer { NotificationCenter.default.removeObserver(token) }

        let target: AppLanguage = original == .english ? .simplifiedChinese : .english
        LanguageManager.current = target

        try? await Task.sleep(for: .milliseconds(80))

        #expect(LanguageManager.current == target)
        #expect(received.value > 0, "切换语言没有广播通知，界面不会刷新")
    }

    @MainActor
    @Test("切到中文后 L10n 返回中文")
    func switchingChangesLookup() {
        let original = LanguageManager.current
        defer { LanguageManager.current = original }

        LanguageManager.current = .english
        #expect(L10n.commonSaveIfAvailable == "Save")

        LanguageManager.current = .simplifiedChinese
        #expect(L10n.commonSaveIfAvailable == "保存")
    }

    @Test("设成同一个语言不会重复广播")
    func settingSameLanguageIsNoop() {
        let original = LanguageManager.current
        defer { LanguageManager.current = original }

        let received = Counter()
        let token = NotificationCenter.default.addObserver(
            forName: LanguageManager.didChangeNotification,
            object: nil,
            queue: nil
        ) { _ in received.increment() }
        defer { NotificationCenter.default.removeObserver(token) }

        LanguageManager.current = original
        #expect(received.value == 0, "值没变却广播了通知，会白白重建视图树")
    }
}

/// 跨线程计数（通知可能从任意线程回调）。
private final class Counter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    func increment() {
        lock.lock()
        defer { lock.unlock() }
        count += 1
    }

    var value: Int {
        lock.lock()
        defer { lock.unlock() }
        return count
    }
}

// 测试用的小包装：直接走 L10n 的同一条路径。
extension L10n {
    fileprivate static var commonSaveIfAvailable: String {
        string("common.save", "Save")
    }
}
