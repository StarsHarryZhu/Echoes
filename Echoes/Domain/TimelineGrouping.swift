//
//  TimelineGrouping.swift
//  Echoes
//

import Foundation

/// 时间归档的分组粒度。
nonisolated enum TimelineGranularity: String, CaseIterable, Hashable, Identifiable {
    /// 按"今天 / 昨天 / 本周 / 本月 / 年月 / 年"自动聚合。
    case automatic
    /// 每天都单独一组。
    case day
    /// 每个月一组。
    case month

    var id: String { rawValue }

    var title: String {
        switch self {
        case .automatic: return "自动"
        case .day: return "按天"
        case .month: return "按月"
        }
    }
}

/// 时间归档里的一个分组。
nonisolated struct TimelineSection: Identifiable, Hashable {
    let id: String
    let title: String
    let memories: [Memory]
}

/// 自动粒度下一个记录所属的时间段。
///
/// 每个 case 对应一个**独立的桶**。这是重构过的一处关键点：
/// 一开始我直接用分组标题当 key，结果「2026年6月」和「2026年8月」会因为标题
/// 生成规则不同而互相串组 —— 标题是给人看的，不能当身份用。
private nonisolated enum AutoBucket {
    case today
    case yesterday
    case thisWeek
    case thisMonth
    case thisYear(month: Int)
    case older(year: Int)

    var id: String {
        switch self {
        case .today: return "today"
        case .yesterday: return "yesterday"
        case .thisWeek: return "this-week"
        case .thisMonth: return "this-month"
        case .thisYear(let month): return "year-month-\(month)"
        case .older(let year): return "year-\(year)"
        }
    }

    var title: String {
        switch self {
        case .today: return "今天"
        case .yesterday: return "昨天"
        case .thisWeek: return "本周"
        case .thisMonth: return "本月"
        case .thisYear(let month): return "\(month)月"
        case .older(let year): return "\(year)年"
        }
    }
}

/// 把归档按时间分组。
///
/// - Parameters:
///   - memories: 已按时间倒序排列的记录。分组的先后顺序沿用这个顺序。
///   - granularity: 分组粒度。
///   - now: "现在"。测试时注入固定值。
///   - calendar: 日历。测试时注入固定时区/地区。
nonisolated func groupTimeline(
    _ memories: [Memory],
    granularity: TimelineGranularity,
    now: Date = Date(),
    calendar: Calendar = .current
) -> [TimelineSection] {
    guard !memories.isEmpty else { return [] }

    var order: [String] = []
    var titles: [String: String] = [:]
    var buckets: [String: [Memory]] = [:]

    for memory in memories {
        let key: String
        let title: String
        switch granularity {
        case .automatic:
            let bucket = autoBucket(for: memory.capturedAt, now: now, calendar: calendar)
            key = bucket.id
            title = bucket.title
        case .day:
            // 用绝对日期而不是相对描述：`relativeDayLabel` 对更早的日期会退化成
            // "2026年6月"，同月不同日会串成一组。
            key = "day-\(DateFormatters.short.string(from: memory.capturedAt))"
            title = relativeDayLabel(for: memory.capturedAt, now: now, calendar: calendar)
        case .month:
            key = "month-\(DateFormatters.month(memory.capturedAt))"
            title = DateFormatters.month(memory.capturedAt)
        }

        if buckets[key] == nil {
            order.append(key)
            titles[key] = title
            buckets[key] = []
        }
        buckets[key]?.append(memory)
    }

    return order.compactMap { key in
        guard let items = buckets[key], let title = titles[key] else { return nil }
        return TimelineSection(id: key, title: title, memories: items)
    }
}

private nonisolated func autoBucket(
    for date: Date,
    now: Date,
    calendar: Calendar
) -> AutoBucket {
    if calendar.isDate(date, inSameDayAs: now) {
        return .today
    }
    if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
       calendar.isDate(date, inSameDayAs: yesterday) {
        return .yesterday
    }
    if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
        return .thisWeek
    }
    if calendar.isDate(date, equalTo: now, toGranularity: .month) {
        return .thisMonth
    }

    let year = calendar.component(.year, from: date)
    let currentYear = calendar.component(.year, from: now)
    guard year != currentYear else {
        // 同一年但已经过去的月份 → 按月分。
        return .thisYear(month: calendar.component(.month, from: date))
    }
    return .older(year: year)
}
