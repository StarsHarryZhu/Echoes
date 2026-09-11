//
//  Formatters.swift
//  Echoes
//
//  所有对外展示的格式化都走这里，保证：
//  1. 跟随界面语言（而不是系统语言）；
//  2. 不每次渲染都新建 `DateFormatter`（那是很贵的操作）。
//

import Foundation

/// 百分比展示。Confidence 存的是 0...1。
nonisolated func percent(_ value: Float) -> String {
    let clamped = min(max(value, 0), 1)
    return "\(Int((clamped * 100).rounded()))%"
}

/// 字节数展示。
nonisolated func formattedByteCount(_ bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useKB, .useMB, .useGB]
    formatter.countStyle = .file
    return formatter.string(fromByteCount: bytes)
}

/// 按当前界面语言构造并缓存 `DateFormatter`。
///
/// 缓存按「语言代码 + 规格」做键：换语言时规格没变但语言变了，
/// 所以键里必须带上语言，否则会一直用到上一种语言的格式。
nonisolated enum DateFormatters {

    private nonisolated(unsafe) static var cache: [String: DateFormatter] = [:]

    private static func formatter(
        _ key: String,
        configure: (DateFormatter) -> Void
    ) -> DateFormatter {
        let cacheKey = "\(LanguageManager.current.resolvedCode)|\(key)"
        if let cached = cache[cacheKey] {
            return cached
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: LanguageManager.current.resolvedCode)
        configure(formatter)
        cache[cacheKey] = formatter
        return formatter
    }

    /// 语言切换后清掉缓存。
    static func resetCache() {
        cache.removeAll()
    }

    /// 列表里的短日期：`26/09/11`（固定格式，中英一致）。
    static var short: DateFormatter {
        formatter("short") { $0.dateFormat = "yy/MM/dd" }
    }

    /// 按语言习惯的中等篇幅日期，例如 `Sep 11, 2026` / `2026年9月11日`。
    static var mediumDate: DateFormatter {
        formatter("mediumDate") { $0.dateStyle = .medium }
    }

    /// 完整日期 + 时间。
    static var full: DateFormatter {
        formatter("full") {
            $0.dateStyle = .long
            $0.timeStyle = .short
        }
    }

    /// 只显示时刻：`20:31`。
    static var time: DateFormatter {
        formatter("time") { $0.dateFormat = "HH:mm" }
    }

    /// 分组标题里的"年月"，例如 `August 2026` / `2026年8月`。
    static func monthLabel(year: Int, month: Int) -> String {
        guard let date = makeDate(year: year, month: month, day: 15) else {
            return "\(year)-\(month)"
        }
        return formatter("monthLabel") { $0.setLocalizedDateFormatFromTemplate("yMMMM") }
            .string(from: date)
    }

    /// 分组标题里的具体某天，例如 `Sep 11, 2026` / `2026年9月11日`。
    static func dayLabel(year: Int, month: Int, day: Int) -> String {
        guard let date = makeDate(year: year, month: month, day: day) else {
            return "\(year)-\(month)-\(day)"
        }
        return mediumDate.string(from: date)
    }

    /// 固定公历（用户日历设置不该影响归档分组）。
    private static func makeDate(year: Int, month: Int, day: Int) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        return Calendar(identifier: .gregorian).date(from: components)
    }
}
