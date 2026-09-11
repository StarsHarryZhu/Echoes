//
//  L10n.swift
//  Echoes
//
//  All user-facing copy. English lives here as the fallback; Simplified Chinese
//  comes from `Localizable.xcstrings`. Adding a language means adding one
//  `<lang>.lproj` — no code changes.
//

import Foundation

/// Lookup table for user-facing strings.
///
/// Keys are stable identifiers (`settings.cache.clear`), not the English text,
/// so changing the English wording never breaks an existing translation.
///
/// `L10n` is nonisolated on purpose: string lookup happens in `LocalizedError`
/// implementations on background actors too.
nonisolated enum L10n {

    /// Look up `key`, falling back to the English text baked into `fallback`.
    ///
    /// The fallback means a missing catalog entry shows sensible English rather
    /// than a raw key like `settings.cache.clear`.
    static func string(_ key: String, _ fallback: String) -> String {
        L10nBundleCache.bundle.localizedString(forKey: key, value: fallback, table: nil)
    }

    /// Single item noun, e.g. `"1"` or `"5"`.
    static func count(_ value: Int) -> String {
        String.localizedStringWithFormat(string("common.count", "%d"), value)
    }

    // MARK: - Common

    static var ok: String { string("common.ok", "OK") }
    static var cancel: String { string("common.cancel", "Cancel") }
    static var delete: String { string("common.delete", "Delete") }
    static var retake: String { string("common.retake", "Retake") }
    static var save: String { string("common.save", "Save") }
    static var saving: String { string("common.saving", "Saving…") }
    static var done: String { string("common.done", "Done") }
    static var settings: String { string("common.settings", "Settings") }
    static var somethingWentWrong: String { string("common.error.title", "Something went wrong") }

    // MARK: - App

    static var appName: String { AppInfo.name }
    static var appTagline: String { string("app.tagline", "Capture emotions. Keep memories.") }

    // MARK: - Root / tabs

    static var tabEmotions: String { string("tab.emotions", "Emotions") }
    static var tabTimeline: String { string("tab.timeline", "Timeline") }
    static var tabEmotionsHint: String { string("tab.emotions.hint", "Browse by emotion") }
    static var tabTimelineHint: String { string("tab.timeline.hint", "Browse by time") }
    static var shutterLabel: String { string("shutter.label", "Take a photo") }
    static var shutterHint: String { string("shutter.hint", "Capture this moment’s expression") }
    static var shutterAnalyzing: String { string("shutter.analyzing", "Reading your expression…") }

    // MARK: - Emotion album

    static var emotionAlbumEmptyTitle: String { string("emotionAlbum.empty.title", "No photos yet") }
    static var emotionAlbumEmptyMessage: String {
        string("emotionAlbum.empty.message", "Tap the round button below to capture how you feel right now.")
    }
    static var emotionAlbumCountLabelFormat: String {
        string("emotionAlbum.card.accessibility", "%1$@, %2$d photos")
    }

    static func emotionAlbumCountLabel(_ emotion: Emotion, count: Int) -> String {
        String.localizedStringWithFormat(emotionAlbumCountLabelFormat, emotion.displayName, count)
    }

    static func emotionListEmptyTitle(_ emotion: Emotion) -> String {
        String.localizedStringWithFormat(
            string("emotionList.empty.title", "No “%@” yet"),
            emotion.displayName
        )
    }

    static var emotionListEmptyMessage: String {
        string("emotionList.empty.message", "Photos you take with this expression will land here.")
    }

    // MARK: - Timeline

    static var timelineEmptyTitle: String { string("timeline.empty.title", "No records yet") }
    static var timelineEmptyMessage: String {
        string("timeline.empty.message", "Tap the round button below to capture this moment’s expression.")
    }
    static var timelineGroupAutomatic: String { string("timeline.group.automatic", "Auto") }
    static var timelineGroupDay: String { string("timeline.group.day", "By day") }
    static var timelineGroupMonth: String { string("timeline.group.month", "By month") }
    static var timelineGroupLabel: String { string("timeline.group.label", "Grouping") }
    static var timelineBadgeLabel: String { string("timeline.badge", "Thumbnail") }
    static var timelineDeleteConfirmTitle: String { string("timeline.delete.title", "Delete this record?") }
    static var timelineDeleteConfirmMessage: String {
        string("timeline.delete.message", "The photo and its record will be removed. This can’t be undone.")
    }

    // MARK: - Time buckets

    static var bucketToday: String { string("bucket.today", "Today") }
    static var bucketYesterday: String { string("bucket.yesterday", "Yesterday") }
    static var bucketThisWeek: String { string("bucket.thisWeek", "This week") }
    static var bucketThisMonth: String { string("bucket.thisMonth", "This month") }
    /// 月份标题，例如 `June` / `6月`。
    ///
    /// 数字直接在 Swift 侧拼成字符串，**不走 `%d`** ——
    /// `String.localizedStringWithFormat` 会按 locale 做数字分组，
    /// 中文下 `2025` 会变成 `2,025`。年份同理。
    static func bucketMonth(_ month: Int) -> String {
        "\(month)\(string("bucket.month", ""))"
    }
    /// 年份标题，例如 `2025` / `2025年`。
    static func bucketYear(_ year: Int) -> String {
        "\(year)\(string("bucket.year", ""))"
    }

    // MARK: - Memory detail

    static var memoryPhotoMissing: String { string("memory.photoMissing", "Photo is missing") }
    static var memoryNotFound: String { string("memory.notFound", "This record no longer exists") }
    static var memoryDeleteButton: String { string("memory.delete", "Delete this record") }
    static var memoryShare: String { string("memory.share", "Share") }
    static var memoryEvidence: String { string("memory.evidence", "How we decided") }
    static var memoryConfidence: String { string("memory.confidence", "Confidence") }
    static var memoryConfidenceFormat: String { string("memory.confidence.format", "Confidence %@") }

    static func memoryConfidence(_ value: Float) -> String {
        String.localizedStringWithFormat(memoryConfidenceFormat, percent(value))
    }

    static func memoryAccessibilityLabel(date: String, emotion: String) -> String {
        String.localizedStringWithFormat(
            string("memory.accessibility", "%1$@, %2$@"),
            date,
            emotion
        )
    }

    static func memoryScoreAccessibility(emotion: String, confidence: String) -> String {
        String.localizedStringWithFormat(
            string("memory.score.accessibility", "%1$@ %2$@"),
            emotion,
            confidence
        )
    }

    // MARK: - Capture review

    static var reviewTitle: String { string("review.title", "How’s this one?") }
    static var reviewLowConfidence: String {
        string("review.lowConfidence", "We’re not very sure about this one — the light may be dim, or your face wasn’t facing the camera. You can still save it.")
    }
    static var reviewDegradedTitle: String { string("review.degraded.title", "This may be inaccurate") }
    static var reviewDegradedFallback: String {
        string("review.degraded.fallback", "We couldn’t locate a face, so this was judged from the whole photo.")
    }

    static var reviewSamplePhoto: String {
        string("review.samplePhoto", "No front camera in this environment — this is a bundled sample photo, not a real capture.")
    }

    // MARK: - Startup / store errors

    static var startupFailedTitle: String { string("startup.failed.title", "Couldn’t load your archive") }
    static func startupCorrupted(_ reason: String) -> String {
        String.localizedStringWithFormat(
            string("startup.corrupted", "The archive file is damaged. A backup was kept and we started with an empty archive: %@"),
            reason
        )
    }
    static func saveFailed(_ reason: String) -> String {
        String.localizedStringWithFormat(string("capture.saveFailed", "Couldn’t save: %@"), reason)
    }

    // MARK: - Analysis errors

    static var analysisNoPixels: String {
        string("analysis.error.noPixels", "This photo has no readable pixel data. Try another one.")
    }
    static var analysisNoFace: String {
        string("analysis.error.noFace", "We couldn’t find a face. Please face the front camera and keep your whole face in frame, then try again.")
    }
    static var analysisFaceTooSmall: String {
        string("analysis.error.faceTooSmall", "The face in the photo is too small to judge accurately. Move a little closer and take another one.")
    }
    static func analysisModelUnavailable(_ reason: String) -> String {
        String.localizedStringWithFormat(
            string("analysis.error.modelUnavailable", "Couldn’t load the expression model: %@"),
            reason
        )
    }
    static func analysisInferenceFailed(_ reason: String) -> String {
        String.localizedStringWithFormat(
            string("analysis.error.inference", "Expression recognition failed: %@"),
            reason
        )
    }
    static var analysisNoResults: String {
        string("analysis.error.noResults", "The model didn’t return any classification.")
    }
    static var analysisNoKnownLabels: String {
        string("analysis.error.noKnownLabels", "The model’s output contained no recognisable expression labels.")
    }

    // MARK: - Camera errors

    static var cameraUnavailable: String { string("camera.error.unavailable", "This device has no available camera.") }
    static var cameraFrontUnavailable: String { string("camera.error.frontUnavailable", "We couldn’t find the front camera.") }
    static var cameraNoPresenter: String {
        string("camera.error.noPresenter", "Can’t present the camera right now. Please try again in a moment.")
    }
    static var cameraNoImage: String { string("camera.error.noImage", "The camera didn’t return a photo.") }

    // MARK: - Migration

    static func migrationUnreadable(_ reason: String) -> String {
        String.localizedStringWithFormat(
            string("migration.error.unreadable", "Couldn’t read the old archive file: %@"),
            reason
        )
    }
    static func manifestCorrupted(_ reason: String) -> String {
        String.localizedStringWithFormat(
            string("manifest.error.corrupted", "The archive file is damaged: %@"),
            reason
        )
    }

    // MARK: - Date formatting

    static var dateToday: String { bucketToday }
    static var dateYesterday: String { bucketYesterday }
    static var dateThisWeek: String { bucketThisWeek }
    static var dateThisMonth: String { bucketThisMonth }

    // MARK: - Settings

    static var settingsTitle: String { string("settings.title", "Settings") }
    static var settingsSectionLanguage: String { string("settings.section.language", "Language") }
    static var settingsLanguageRow: String { string("settings.language", "App language") }
    static var settingsLanguageFooter: String {
        string("settings.language.footer", "Defaults to English. Switching applies immediately.")
    }
    static var languageSystem: String { string("settings.language.system", "Follow system") }

    static var settingsSectionTimeline: String { string("settings.section.timeline", "Timeline") }
    static var settingsTimelineGrouping: String { string("settings.timeline.grouping", "Grouping") }
    static var settingsTimelineFooter: String {
        string("settings.timeline.footer", "How photos are grouped on the Timeline tab.")
    }

    static var settingsSectionAnalysis: String { string("settings.section.analysis", "Expression recognition") }
    static var settingsFaceFallback: String {
        string("settings.analysis.fallback", "Fall back to whole-photo analysis when no face is found")
    }
    static var settingsFaceFallbackFooter: String {
        string(
            "settings.analysis.fallback.footer",
            "When on, you still get a result even if no face is detected (less accurate — it’s marked “may be inaccurate”). When off, we ask you to retake until a full face is captured."
        )
    }
    static var settingsMayBeInaccurate: String { string("settings.analysis.mayBeInaccurate", "may be inaccurate") }

    static var settingsSectionStorage: String { string("settings.section.storage", "Storage") }
    static var settingsArchivedPhotos: String { string("settings.storage.count", "Archived photos") }
    static var settingsClearCache: String { string("settings.storage.clear", "Clear thumbnail cache") }
    static var settingsStorageFooter: String {
        string("settings.storage.footer", "Thumbnails are rebuilt on demand. Your original photos are untouched.")
    }
    static func settingsCacheFreed(_ size: String) -> String {
        String.localizedStringWithFormat(string("settings.storage.freed", "Freed %@."), size)
    }
    static var settingsCacheNothing: String { string("settings.storage.nothing", "Nothing to clean up.") }

    static var settingsSectionAbout: String { string("settings.section.about", "About") }
    static var settingsAboutApp: String { string("settings.about.app", "About Echoes") }
    static var settingsTeam: String { string("settings.about.team", "The team") }
    static var settingsFeedback: String { string("settings.about.feedback", "Feedback & suggestions") }
    static var settingsRate: String { string("settings.about.rate", "Rate us") }

    // MARK: - About

    static var aboutSectionVersion: String { string("about.section.version", "Version") }
    static var aboutVersion: String { string("about.version", "Version") }
    static var aboutBuild: String { string("about.build", "Build") }
    static var aboutWhyTitle: String { string("about.why.title", "Why we built Echoes") }

    // MARK: - Creators

    static var creatorsSectionTeam: String { string("creators.section.team", "Team") }
    static var creatorsSectionIdea: String { string("creators.section.idea", "Our thinking") }

    // MARK: - Feedback

    static var feedbackTitle: String { string("feedback.title", "Feedback & suggestions") }
    static var feedbackSectionSubject: String { string("feedback.section.subject", "Subject") }
    static var feedbackSubjectPlaceholder: String { string("feedback.subject.placeholder", "One-line summary") }
    static var feedbackSectionMessage: String { string("feedback.section.message", "Details") }
    static var feedbackDiagnostics: String { string("feedback.diagnostics", "Include device and version info") }
    static var feedbackDiagnosticsFooter: String {
        string("feedback.diagnostics.footer", "Helps us reproduce issues. Contains no photos or expression records.")
    }
    static var feedbackSend: String { string("feedback.send", "Send feedback") }
    static var feedbackCopy: String { string("feedback.copy", "Copy feedback") }
    static var feedbackCopied: String { string("feedback.copied", "Copied to the clipboard.") }
    static var feedbackDefaultSubject: String { string("feedback.defaultSubject", "Echoes feedback") }
    static var feedbackNoMailClient: String {
        string(
            "feedback.noMailClient",
            "This device has no mail account set up. We copied your feedback to the clipboard so you can paste it anywhere."
        )
    }
    static var feedbackMailOpened: String {
        string("feedback.mailOpened", "Your mail app is open — just hit send.")
    }
    static var feedbackMailFailed: String {
        string("feedback.mailFailed", "The mail app couldn’t be opened. Your feedback was copied to the clipboard.")
    }
    static var feedbackInvalidContent: String {
        string("feedback.invalidContent", "The feedback contained invalid characters. It was copied to the clipboard.")
    }
    static var feedbackDiagnosticsBody: String { string("feedback.diagnostics.body", "Diagnostics") }

    // MARK: - Rate

    static var rateCopy: String { string("rate.copy", "If you like Echoes, a 5-star rating really helps! ✨") }
    static var rateInApp: String { string("rate.inApp", "Rate in the app") }
    static var rateInAppFooter: String {
        string("rate.inApp.footer", "The system decides whether to show the rating prompt. It’s normal if it doesn’t appear.")
    }
    static var rateAppStore: String { string("rate.appStore", "Review on the App Store") }
}
