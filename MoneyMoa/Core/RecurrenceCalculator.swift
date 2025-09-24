//
//  RecurrenceCalculator.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/24/25.
//

import Foundation

// MARK: - RecurrenceCalculator

public enum RecurrenceCalculator {

    /// 오늘을 기준으로 lastExecutedAt 이후부터 부족한 모든 발생일들을 계산
    /// - Parameters:
    ///   - pattern: 반복 패턴
    ///   - lastExecutedAt: 마지막 실행일 (nil이면 아직 실행 안됨)
    ///   - baseDate: 템플릿 기준일 (생성일 또는 설정일)
    ///   - upToDate: 계산 기준일 (기본: 오늘)
    ///   - calendar: 계산에 사용할 캘린더
    ///   - maxCount: 과도 생성 방지 상한
    /// - Returns: 실행해야 할 날짜들의 배열 (오름차순)
    static func calculateDueOccurrences(
        pattern: RecurrencePattern,
        lastExecutedAt: Date?,
        baseDate: Date,
        upToDate: Date = Date(),
        calendar: Calendar,
        maxCount: Int = 50
    ) -> [Date] {

        guard pattern.period != .none else { return [] }

        var result: [Date] = []

        // lastExecutedAt이 있으면 그 이후부터, 없으면 baseDate부터 시작
        let startDate: Date
        if let lastExecutedAt = lastExecutedAt {
            startDate = lastExecutedAt
        } else {
            // 첫 실행인 경우 baseDate에서 첫 발생일을 찾기
            let firstOccurrence = findFirstOccurrenceDate(
                pattern: pattern,
                baseDate: baseDate,
                calendar: calendar
            )
            if firstOccurrence <= upToDate {
                result.append(firstOccurrence)
            }
            startDate = firstOccurrence
        }

        var currentDate = startDate

        while result.count < maxCount {
            guard
                let nextDate = calculateNextOccurrence(
                    pattern: pattern,
                    after: currentDate,
                    calendar: calendar
                )
            else { break }

            if nextDate <= upToDate {
                result.append(nextDate)
                currentDate = nextDate
            } else {
                break
            }
        }

        return result
    }

    /// 다음 단일 발생일 계산
    /// - Parameters:
    ///   - pattern: 반복 패턴
    ///   - after: 기준 날짜 (이 날짜 이후의 다음 발생일)
    ///   - calendar: 계산에 사용할 캘린더
    /// - Returns: 다음 발생일
    static func calculateNextOccurrence(
        pattern: RecurrencePattern,
        after date: Date,
        calendar: Calendar
    ) -> Date? {

        switch pattern.period {
        case .none:
            return nil

        case .weekly:
            guard let targetWeekday = pattern.weekday else { return nil }
            return findNextWeekdayOccurrence(
                targetWeekday: targetWeekday,
                after: date,
                calendar: calendar
            )

        case .monthly:
            guard let targetDay = pattern.dayOfMonth else { return nil }
            return findNextMonthlyOccurrence(
                targetDay: targetDay,
                after: date,
                calendar: calendar,
                endOfMonthRule: pattern.endOfMonthRule
            )

        case .yearly:
            guard let targetMonth = pattern.yearlyMonth,
                let targetDay = pattern.yearlyDay
            else { return nil }
            return findNextYearlyOccurrence(
                targetMonth: targetMonth,
                targetDay: targetDay,
                after: date,
                calendar: calendar,
                endOfMonthRule: pattern.endOfMonthRule
            )
        }
    }

    // MARK: - Private Helper Methods

    /// 첫 번째 발생일 계산 (baseDate 기준)
    private static func findFirstOccurrenceDate(
        pattern: RecurrencePattern,
        baseDate: Date,
        calendar: Calendar
    ) -> Date {
        switch pattern.period {
        case .none:
            return baseDate

        case .weekly:
            return findFirstWeeklyOccurrence(
                weekday: pattern.weekday ?? 1,
                baseDate: baseDate,
                calendar: calendar
            )

        case .monthly:
            return findFirstMonthlyOccurrence(
                dayOfMonth: pattern.dayOfMonth ?? 1,
                baseDate: baseDate,
                calendar: calendar,
                endOfMonthRule: pattern.endOfMonthRule
            )

        case .yearly:
            return findFirstYearlyOccurrence(
                month: pattern.yearlyMonth ?? 1,
                day: pattern.yearlyDay ?? 1,
                baseDate: baseDate,
                calendar: calendar,
                endOfMonthRule: pattern.endOfMonthRule
            )
        }
    }

    /// 첫 번째 주간 발생일 찾기
    private static func findFirstWeeklyOccurrence(
        weekday: Int,
        baseDate: Date,
        calendar: Calendar
    ) -> Date {
        let baseDateComponents = calendar.dateComponents(
            [.weekday],
            from: baseDate
        )
        let currentWeekday = baseDateComponents.weekday ?? 1

        let daysToAdd = (weekday - currentWeekday + 7) % 7
        if daysToAdd == 0 {
            return baseDate  // 같은 요일이면 baseDate가 첫 발생일
        }
        return calendar.date(byAdding: .day, value: daysToAdd, to: baseDate)
            ?? baseDate
    }

    /// 첫 번째 월간 발생일 찾기
    private static func findFirstMonthlyOccurrence(
        dayOfMonth: Int,
        baseDate: Date,
        calendar: Calendar,
        endOfMonthRule: EndOfMonthRule
    ) -> Date {
        var components = calendar.dateComponents(
            [.year, .month],
            from: baseDate
        )

        // 현재 월에서 시도
        if let candidate = tryCreateDateInMonth(
            components: &components,
            targetDay: dayOfMonth,
            calendar: calendar
        ), candidate >= baseDate {
            return candidate
        }

        // 다음 달에서 시도
        components.month! += 1
        return tryCreateDateInMonth(
            components: &components,
            targetDay: dayOfMonth,
            calendar: calendar
        ) ?? baseDate
    }

    /// 첫 번째 연간 발생일 찾기
    private static func findFirstYearlyOccurrence(
        month: Int,
        day: Int,
        baseDate: Date,
        calendar: Calendar,
        endOfMonthRule: EndOfMonthRule
    ) -> Date {
        var components = calendar.dateComponents([.year], from: baseDate)
        components.month = month

        // 현재 년도에서 시도
        if let candidate = tryCreateDateInMonth(
            components: &components,
            targetDay: day,
            calendar: calendar
        ), candidate >= baseDate {
            return candidate
        }

        // 다음 해에서 시도
        components.year! += 1
        return tryCreateDateInMonth(
            components: &components,
            targetDay: day,
            calendar: calendar
        ) ?? baseDate
    }

    /// 특정 월에서 날짜 생성 시도 (월말 조정 포함)
    private static func tryCreateDateInMonth(
        components: inout DateComponents,
        targetDay: Int,
        calendar: Calendar
    ) -> Date? {
        guard let tempDate = calendar.date(from: components) else { return nil }

        let range = calendar.range(of: .day, in: .month, for: tempDate)
        let lastDayOfMonth = range?.upperBound.advanced(by: -1) ?? 28

        // 월말 조정
        components.day = min(targetDay, lastDayOfMonth)
        return calendar.date(from: components)
    }

    /// 다음 주간 발생일 찾기
    private static func findNextWeekdayOccurrence(
        targetWeekday: Int,
        after date: Date,
        calendar: Calendar
    ) -> Date? {

        let nextWeek =
            calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        let components = calendar.dateComponents(
            [.yearForWeekOfYear, .weekOfYear],
            from: nextWeek
        )

        var targetComponents = DateComponents()
        targetComponents.yearForWeekOfYear = components.yearForWeekOfYear
        targetComponents.weekOfYear = components.weekOfYear
        targetComponents.weekday = targetWeekday

        return calendar.date(from: targetComponents)
    }

    /// 다음 월간 발생일 찾기
    private static func findNextMonthlyOccurrence(
        targetDay: Int,
        after date: Date,
        calendar: Calendar,
        endOfMonthRule: EndOfMonthRule
    ) -> Date? {

        let nextMonth =
            calendar.date(byAdding: .month, value: 1, to: date) ?? date
        var components = calendar.dateComponents(
            [.year, .month],
            from: nextMonth
        )

        // 목표 월의 마지막 날 확인
        let tempDate = calendar.date(from: components) ?? nextMonth
        let range = calendar.range(of: .day, in: .month, for: tempDate)
        let lastDayOfMonth = range?.upperBound.advanced(by: -1) ?? 28

        // EndOfMonth 처리
        let adjustedDay: Int
        if targetDay <= lastDayOfMonth {
            adjustedDay = targetDay
        } else {
            switch endOfMonthRule {
            case .clampToEndOfMonth, .skip:
                adjustedDay = lastDayOfMonth
            }
        }

        components.day = adjustedDay
        return calendar.date(from: components)
    }

    /// 다음 연간 발생일 찾기
    private static func findNextYearlyOccurrence(
        targetMonth: Int,
        targetDay: Int,
        after date: Date,
        calendar: Calendar,
        endOfMonthRule: EndOfMonthRule
    ) -> Date? {

        let nextYear =
            calendar.date(byAdding: .year, value: 1, to: date) ?? date
        var components = calendar.dateComponents([.year], from: nextYear)
        components.month = targetMonth

        // 목표 월의 마지막 날 확인
        let tempDate = calendar.date(from: components) ?? nextYear
        let range = calendar.range(of: .day, in: .month, for: tempDate)
        let lastDayOfMonth = range?.upperBound.advanced(by: -1) ?? 28

        // EndOfMonth 처리
        let adjustedDay: Int
        if targetDay <= lastDayOfMonth {
            adjustedDay = targetDay
        } else {
            switch endOfMonthRule {
            case .clampToEndOfMonth, .skip:
                adjustedDay = lastDayOfMonth
            }
        }

        components.day = adjustedDay
        return calendar.date(from: components)
    }

    /// 월말 처리 (31일 → 28/29일 조정 등)
    private static func adjustForEndOfMonth(
        date: Date,
        targetDay: Int,
        calendar: Calendar,
        endOfMonthRule: EndOfMonthRule
    ) -> Date {

        let range = calendar.range(of: .day, in: .month, for: date)
        let lastDayOfMonth = range?.upperBound.advanced(by: -1) ?? 28

        if targetDay <= lastDayOfMonth {
            // 목표 날짜가 해당 월에 존재함
            return date
        } else {
            // 목표 날짜가 해당 월에 없음 (예: 2월 30일)
            switch endOfMonthRule {
            case .clampToEndOfMonth:
                // 말일로 조정
                var components = calendar.dateComponents(
                    [.year, .month],
                    from: date
                )
                components.day = lastDayOfMonth
                return calendar.date(from: components) ?? date

            case .skip:
                // 건너뛰기 - 이 구현에서는 skip하지 않고 clamp로 처리
                // (요구사항: "skip 하면 안되는 계산")
                var components = calendar.dateComponents(
                    [.year, .month],
                    from: date
                )
                components.day = lastDayOfMonth
                return calendar.date(from: components) ?? date
            }
        }
    }
}
