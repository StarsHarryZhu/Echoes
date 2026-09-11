//
//  TimelineGrouping.swift
//  Echoes
//

import Foundation

/// 时间归档的分组粒度。
nonisolated enum TimelineGranularity: String, CaseIterable, Hashable, Identifiable {
    /// 按"今天 / 昨天 / 本周 / 本月 / 月份 / 年份"自动聚合。
    case automatic
    /// 每天都单独一组。
    case day
    /// 每个月一组。
    case month

    var id: String { rawValue }

    var title: String {
        switch self {
        case .automatic: return L10n.timelineGroupAutomatic
        case .day: return L10n.timelineGroupDay
        case .month: return L10n.timelineGroupMonth
        }
    }
}

/// 一条记录落在哪个时间段。
///
/// 这是**分组算法与界面之间的契约**：算法只产出结构化的桶，
/// 文案由视图层按当前语言渲染。这样分组逻辑保持纯函数、可测，
/// 换语言时也不用动它。
nonisolated enum TimelineBucket: Hashable, Sendable {
    case today
    case yesterday
    case thisWeek
    case thisMonth
    /// 今年内、但已经过去的月份。
    case month(Int)
    /// 往年。
    case year(Int)
    /// 按天粒度分组时用的具体日期。
    case exactDay(year: Int, month: Int, day: Int)
    /// 按月粒度分组。
    case calendarMonth(year: Int, month: Int)

    /// 分组身份。**不能拿文案当身份** —— 标题会随语言和粒度变化，
    /// 早期版本就是拿标题当 key，把不同分组串到了一起。
    var id: String {
        switch self {
        case .today: return "today"
        case .yesterday: return "yesterday"
        case .thisWeek: return "this-week"
        case .thisMonth: return "this-month"
        case .month(let month): return "month-\(month)"
        case .year(let year): return "year-\(year)"
        case .exactDay(let year, let month, let day): return "day-\(year)-\(month)-\(day)"
        case .calendarMonth(let year, let month): return "calendar-\(year)-\(month)"
        }
    }

    /// 标题文案，按当前界面语言。
    var title: String {
        switch self {
        case .today: return L10n.bucketToday
        case .yesterday: return L10n.bucketYesterday
        case .thisWeek: return L10n.bucketThisWeek
        case .thisMonth: return L10n.bucketThisMonth
        case .month(let month): return L10n.bucketMonth(month)
        case .year(let year): return L10n.bucketYear(year)
        case .exactDay(let year, let month, let day):
            return DateFormatters.dayLabel(year: year, month: month, day: day)
        case .calendarMonth(let year, let month):
            return DateFormatters.monthLabel(year: year, month: month)
        }
    }
}

/// 时间归档里的一个分组。
nonisolated struct TimelineSection: Identifiable, Hashable {
    let bucket: TimelineBucket
    let memories: [Memory]

    var id: String { bucket.id }
    var title: String { bucket.title }
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
    var bucketsByID: [String: TimelineBucket] = [:]
    var itemsByID: [String: [Memory]] = [:]

    for memory in memories {
        let bucket = timelineBucket(
            for: memory.capturedAt,
            granularity: granularity,
            now: now,
            calendar: calendar
        )

        if itemsByID[bucket.id] == nil {
            order.append(bucket.id)
            bucketsByID[bucket.id] = bucket
            itemsByID[bucket.id] = []
        }
        itemsByID[bucket.id]?.append(memory)
    }

    return order.compactMap { id in
        guard let bucket = bucketsByID[id], let items = itemsByID[id] else { return nil }
        return TimelineSection(bucket: bucket, memories: items)
    }
}

private nonisolated func timelineBucket(
    for date: Date,
    granularity: TimelineGranularity,
    now: Date,
    calendar: Calendar
) -> TimelineBucket {
    switch granularity {
    case .automatic:
        return autoBucket(for: date, now: now, calendar: calendar)

    case .day:
        // 用绝对日期而不是相对描述：`autoBucket` 对更早的日期会退化成月份，
        // 同月不同日会串成一组。
        return .exactDay(
            year: calendar.component(.year, from: date),
            month: calendar.component(.month, from: date),
            day: calendar.component(.day, from: date)
        )

    case .month:
        return .calendarMonth(
            year: calendar.component(.year, from: date),
            month: calendar.component(.month, from: date)
        )
    }
}

private nonisolated func autoBucket(
    for date: Date,
    now: Date,
    calendar: Calendar
) -> TimelineBucket {
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
    guard year == currentYear else {
        return .year(year)
    }
    // 同一年但已经过去的月份 → 按月分，比笼统的"今年"更有用。
    return .month(calendar.component(.month, from: date))
}
