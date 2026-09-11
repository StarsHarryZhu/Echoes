//
//  Formatters.swift
//  Echoes
//

import Foundation

/// 百分比展示。Confidence 存的是 0...1。
nonisolated func percent(_ value: Float) -> String {
    let clamped = min(max(value, 0), 1)
    return "\(Int((clamped * 100).rounded()))%"
}

/// 项目里到处新建 `DateFormatter` 很浪费，集中在这里。
nonisolated enum DateFormatters {
    /// 列表里的短日期：26/09/11
    static let short: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy/MM/dd"
        return formatter
    }()

    /// 详情页的完整日期：2026年9月11日 20:31
    static let full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter
    }()

    /// 时间线上的时刻：20:31
    static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    /// 分组标题：2026年9月
    static func month(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: date)
    }

    /// 分组标题：2026年
    static func year(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年"
        return formatter.string(from: date)
    }
}

/// 相对日期描述：今天 / 昨天 / 本周 …
nonisolated func relativeDayLabel(
    for date: Date,
    now: Date = Date(),
    calendar: Calendar = .current
) -> String {
    if calendar.isDate(date, inSameDayAs: now) { return "今天" }
    if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
       calendar.isDate(date, inSameDayAs: yesterday) {
        return "昨天"
    }
    if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
        return "本周"
    }
    if calendar.isDate(date, equalTo: now, toGranularity: .month) {
        return "本月"
    }
    if calendar.isDate(date, equalTo: now, toGranularity: .year) {
        return DateFormatters.month(date)
    }
    return DateFormatters.year(date)
}

/// 字节数展示。
nonisolated func formattedByteCount(_ bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useKB, .useMB, .useGB]
    formatter.countStyle = .file
    return formatter.string(fromByteCount: bytes)
}
