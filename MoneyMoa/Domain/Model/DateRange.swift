//
//  DateRange.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/28/25.
//

import Foundation

/// 통계 그룹핑 단위
/// - daily: 일 단위 라인/포인트
/// - monthly: 월 단위 바/스택 등
public enum StatisticsGrouping: Sendable { case daily, monthly }

/// 통계 조회 범위 (반닫힘 구간 [start, end))
/// - grouping은 start/end를 기준으로 월 범위를 계산하여 자동 결정
public struct DateRange: Equatable, Sendable {
    public let start: Date    // inclusive
    public let end: Date      // exclusive
    public let grouping: StatisticsGrouping

    public init(start: Date, end: Date, calendar: Calendar = KST.calendar) {
        self.start = start
        self.end = end
        // 월 단위 길이가 1개월을 초과하면 monthly, 아니면 daily로 자동 결정
        let months = calendar.dateComponents([.month], from: calendar.startOfMonth(for: start),
                                             to: calendar.startOfMonth(for: end)).month ?? 0
        self.grouping = months > 1 ? .monthly : .daily
    }

    func inclusiveRange(cal: Calendar = KST.calendar) -> (Date, Date) {
        let endInclusive = cal.date(byAdding: .second, value: -1, to: self.end) ?? self.end
        return (self.start, endInclusive)
    }

    func months(cal: Calendar = KST.calendar) -> [YearMonth] {
        cal.yearMonths(in: self)
    }
}

/// 자주 쓰는 기간 프리셋 (KST 기준)
public enum DateRangePreset: Sendable, Equatable, Hashable {
    case thisMonth, lastMonth, threeMonths, sixMonths, thisYear
    case custom(Date, Date)

    /// 현재 시각(now)과 KST 캘린더를 기준으로 실제 DateRange로 변환
    public func resolve(now: Date = .now, calendar: Calendar = KST.calendar) -> DateRange {
        switch self {
        case .thisMonth:
            let s = calendar.startOfMonth(for: now)
            let e = calendar.endOfMonthExclusive(for: now)
            return DateRange(start: s, end: e, calendar: calendar)
        case .lastMonth:
            let e = calendar.startOfMonth(for: now)         // 이번 달 시작
            let s = calendar.date(byAdding: .month, value: -1, to: e)! // 전달 시작
            return DateRange(start: s, end: e, calendar: calendar)
        case .threeMonths:
            let e = calendar.endOfMonthExclusive(for: now)  // 이번 달 exclusive end
            let s = calendar.date(byAdding: .month, value: -3, to: e)! // 3개월 전
            return DateRange(start: s, end: e, calendar: calendar)
        case .sixMonths:
            let e = calendar.endOfMonthExclusive(for: now)
            let s = calendar.date(byAdding: .month, value: -6, to: e)!
            return DateRange(start: s, end: e, calendar: calendar)
        case .thisYear:
            let year = calendar.component(.year, from: now)
            let s = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
            let e = calendar.date(byAdding: .year, value: 1, to: s)!
            return DateRange(start: s, end: e, calendar: calendar)
        case let .custom(s, e):
            return DateRange(start: s, end: e, calendar: calendar)
        }
    }
}

// MARK: CalendarExtentions
public extension Calendar {
    /// DateRange 내에 포함되는 YearMonth 배열([start, end) 규약)
    func yearMonths(in range: DateRange) -> [YearMonth] {
           var months: [YearMonth] = []
           var cursor = startOfMonth(for: range.start)
           while cursor < range.end {
               months.append(YearMonth(date: cursor, calendar: self))
               cursor = date(byAdding: .month, value: 1, to: cursor)!
           }
           return months
       }
}
