//
//  TimelineGroupingTests.swift
//  EchoesTests
//

import Foundation
import Testing

@testable import Echoes

@Suite("时间归档分组")
struct TimelineGroupingTests {

    /// 固定时区，避免测试机时区不同导致结果漂移。
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        calendar.locale = Locale(identifier: "zh_Hans_CN")
        // 周一作为一周起点，符合国内习惯，也让"本周"边界可预测。
        calendar.firstWeekday = 2
        return calendar
    }()

    private static func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        return calendar.date(from: components)!
    }

    /// 2026-09-10 是周四。
    private static let now = date(2026, 9, 10)

    private static func makeMemory(_ capturedAt: Date, id: UUID = UUID()) -> Memory {
        Memory(
            id: id,
            capturedAt: capturedAt,
            filename: "\(id.uuidString).jpg",
            emotion: .happy,
            confidence: 0.5
        )
    }

    // MARK: - 基本行为

    @Test("空归档不产生任何分组")
    func emptyInput() {
        #expect(groupTimeline([], granularity: .automatic, now: Self.now, calendar: Self.calendar).isEmpty)
        #expect(groupTimeline([], granularity: .day, now: Self.now, calendar: Self.calendar).isEmpty)
        #expect(groupTimeline([], granularity: .month, now: Self.now, calendar: Self.calendar).isEmpty)
    }

    @Test("分组顺序沿用输入顺序（倒序）")
    func preservesInputOrder() {
        let today = Self.makeMemory(Self.date(2026, 9, 10, 18))
        let yesterday = Self.makeMemory(Self.date(2026, 9, 9, 18))
        let lastYear = Self.makeMemory(Self.date(2025, 3, 1))

        let sections = groupTimeline(
            [today, yesterday, lastYear],
            granularity: .automatic,
            now: Self.now,
            calendar: Self.calendar
        )

        #expect(sections.map(\.bucket) == [.today, .yesterday, .year(2025)])
    }

    // MARK: - 自动粒度

    @Test("自动粒度把相近时间归成相对描述")
    func automaticLabels() {
        let today = Self.makeMemory(Self.date(2026, 9, 10, 8))
        let yesterday = Self.makeMemory(Self.date(2026, 9, 9, 8))
        let thisWeek = Self.makeMemory(Self.date(2026, 9, 8, 8))   // 周一，同周
        let thisMonth = Self.makeMemory(Self.date(2026, 9, 1, 8))   // 同月不同周
        let thisYear = Self.makeMemory(Self.date(2026, 6, 1, 8))
        let older = Self.makeMemory(Self.date(2025, 11, 1, 8))

        let sections = groupTimeline(
            [today, yesterday, thisWeek, thisMonth, thisYear, older],
            granularity: .automatic,
            now: Self.now,
            calendar: Self.calendar
        )

        #expect(sections.map(\.bucket) == [
            .today, .yesterday, .thisWeek, .thisMonth, .month(6), .year(2025),
        ])
    }

    @Test("同一天的多条记录落进同一组")
    func sameDayMerges() {
        let morning = Self.makeMemory(Self.date(2026, 9, 10, 8))
        let evening = Self.makeMemory(Self.date(2026, 9, 10, 20))

        let sections = groupTimeline(
            [evening, morning],
            granularity: .automatic,
            now: Self.now,
            calendar: Self.calendar
        )

        #expect(sections.count == 1)
        #expect(sections.first?.memories.count == 2)
    }

    @Test("自动粒度下同月不同日不会被拆开")
    func sameMonthStaysTogether() {
        let day1 = Self.makeMemory(Self.date(2026, 9, 1))
        let day2 = Self.makeMemory(Self.date(2026, 9, 2))
        let day3 = Self.makeMemory(Self.date(2026, 9, 3))

        let sections = groupTimeline(
            [day3, day2, day1],
            granularity: .automatic,
            now: Self.now,
            calendar: Self.calendar
        )

        #expect(sections.count == 1)
        #expect(sections.first?.bucket == .thisMonth)
        #expect(sections.first?.memories.count == 3)
    }

    // MARK: - 按天

    @Test("按天粒度每天一组，跨月同一天不会被合并")
    func dayGranularity() {
        let a = Self.makeMemory(Self.date(2026, 9, 10))
        let b = Self.makeMemory(Self.date(2026, 9, 9))
        let c = Self.makeMemory(Self.date(2026, 9, 9, 20))
        let d = Self.makeMemory(Self.date(2025, 9, 9))   // 同月日、不同年

        let sections = groupTimeline(
            [a, c, b, d],
            granularity: .day,
            now: Self.now,
            calendar: Self.calendar
        )

        // 2026-09-10 / 2026-09-09 / 2025-09-09 三组
        #expect(sections.count == 3)
        #expect(sections[0].memories.count == 1)
        #expect(sections[1].memories.count == 2)
        #expect(sections[2].memories.count == 1)
    }

    // MARK: - 按月

    @Test("按月粒度每月一组")
    func monthGranularity() {
        let a = Self.makeMemory(Self.date(2026, 9, 10))
        let b = Self.makeMemory(Self.date(2026, 9, 1))
        let c = Self.makeMemory(Self.date(2026, 8, 15))
        let d = Self.makeMemory(Self.date(2025, 8, 15))

        let sections = groupTimeline(
            [a, b, c, d],
            granularity: .month,
            now: Self.now,
            calendar: Self.calendar
        )

        #expect(sections.map(\.bucket) == [
            .calendarMonth(year: 2026, month: 9),
            .calendarMonth(year: 2026, month: 8),
            .calendarMonth(year: 2025, month: 8),
        ])
        #expect(sections[0].memories.count == 2)
    }

    // MARK: - 边界

    @Test("跨年边界：同年按月分，往年按年分")
    func yearBoundary() {
        let newYear = Self.makeMemory(Self.date(2026, 1, 1))
        let lastYear = Self.makeMemory(Self.date(2025, 12, 31))

        let sections = groupTimeline(
            [newYear, lastYear],
            granularity: .automatic,
            now: Self.now,
            calendar: Self.calendar
        )

        // 2026 年内但已经过去的月份 → 按月；往年 → 按年。
        #expect(sections.map(\.bucket) == [.month(1), .year(2025)])
        #expect(sections.map(\.id) == ["month-1", "year-2025"])
    }

    @Test("周一 00:00 属于新的一周")
    func weekBoundary() {
        // 2026-09-10 是周四，firstWeekday = 周一 → 本周从 09-07（周一）开始。
        let monday = Self.makeMemory(Self.date(2026, 9, 7, 0))
        let lastSunday = Self.makeMemory(Self.date(2026, 9, 6, 23))

        let sections = groupTimeline(
            [monday, lastSunday],
            granularity: .automatic,
            now: Self.now,
            calendar: Self.calendar
        )

        #expect(sections.map(\.bucket) == [.thisWeek, .thisMonth])
    }

    /// 分组的身份是 `TimelineBucket`，不是文案 —— 文案会随语言变。
    @Test("分组 id 唯一")
    func sectionIDsAreUnique() {
        let memories = [
            Self.makeMemory(Self.date(2026, 9, 10)),
            Self.makeMemory(Self.date(2026, 9, 9)),
            Self.makeMemory(Self.date(2026, 8, 1)),
            Self.makeMemory(Self.date(2025, 1, 1)),
        ]

        let sections = groupTimeline(
            memories,
            granularity: .automatic,
            now: Self.now,
            calendar: Self.calendar
        )

        #expect(Set(sections.map(\.id)).count == sections.count)
    }

    @Test("不丢记录：所有分组的记录数之和等于输入")
    func noRecordLost() {
        let memories = (0..<40).map { offset in
            Self.makeMemory(Self.now.addingTimeInterval(Double(-offset) * 86_400 * 3))
        }

        for granularity in TimelineGranularity.allCases {
            let sections = groupTimeline(
                memories,
                granularity: granularity,
                now: Self.now,
                calendar: Self.calendar
            )
            let total = sections.reduce(0) { $0 + $1.memories.count }
            #expect(total == memories.count, "粒度 \(granularity.rawValue) 下记录数对不上")
        }
    }
}
