//
//  RecurrencePattern.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/24/25.
//

import Foundation

// MARK: - EndOfMonthRule

public enum EndOfMonthRule: String, Codable, CaseIterable, Sendable {
    case clampToEndOfMonth   // 해당 월에 날짜가 없으면 말일로 클램프
    case skip                // 해당 월에 날짜가 없으면 건너뜀(고급 정책, 필요 시)

    var displayName: String {
        switch self {
        case .clampToEndOfMonth:
            return "말일로 조정"
        case .skip:
            return "건너뛰기"
        }
    }
}

// MARK: - RecurrencePattern

public struct RecurrencePattern: Codable, Sendable, Hashable {
    let period: RecurrencePeriod
    let dayOfMonth: Int?                        // monthly: 1-31
    let weekday: Int?                          // weekly: 1-7 (1=일요일)
    let yearlyMonth: Int?                      // yearly: month (1-12)
    let yearlyDay: Int?                        // yearly: day (1-31)
    let hour: Int                              // 0-23 (기본값: 9시)
    let minute: Int                            // 0-59 (기본값: 0분)
    let endOfMonthRule: EndOfMonthRule

    public init(
        period: RecurrencePeriod = RecurrencePeriod.none,
        dayOfMonth: Int? = nil,
        weekday: Int? = nil,
        yearlyMonth: Int? = nil,
        yearlyDay: Int? = nil,
        hour: Int = 9,
        minute: Int = 0,
        endOfMonthRule: EndOfMonthRule = .clampToEndOfMonth
    ) {
        self.period = period
        self.dayOfMonth = dayOfMonth
        self.weekday = weekday
        self.yearlyMonth = yearlyMonth
        self.yearlyDay = yearlyDay
        self.hour = hour
        self.minute = minute
        self.endOfMonthRule = endOfMonthRule
    }

    // MARK: - Factory Methods

    static func weekly(on weekday: Int, hour: Int = 9, minute: Int = 0) -> RecurrencePattern {
        return RecurrencePattern(
            period: .weekly,
            weekday: weekday,
            hour: hour,
            minute: minute
        )
    }

    static func monthly(on day: Int, hour: Int = 9, minute: Int = 0, endOfMonthRule: EndOfMonthRule = .clampToEndOfMonth) -> RecurrencePattern {
        return RecurrencePattern(
            period: .monthly,
            dayOfMonth: day,
            hour: hour,
            minute: minute,
            endOfMonthRule: endOfMonthRule
        )
    }

    static func yearly(month: Int, day: Int, hour: Int = 9, minute: Int = 0, endOfMonthRule: EndOfMonthRule = .clampToEndOfMonth) -> RecurrencePattern {
        return RecurrencePattern(
            period: .yearly,
            yearlyMonth: month,
            yearlyDay: day,
            hour: hour,
            minute: minute,
            endOfMonthRule: endOfMonthRule
        )
    }

    // MARK: - Date-based Factory

    public init(
        from date: Date,
        period: RecurrencePeriod,
        calendar: Calendar
    ) {
        let components = calendar.dateComponents([.weekday, .day, .month, .hour, .minute], from: date)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0

        switch period {
        case .none:
            self = RecurrencePattern(
                period: .none,
                hour: hour,
                minute: minute
            )
        case .weekly:
            let weekday = components.weekday ?? calendar.component(.weekday, from: date)
            self = RecurrencePattern.weekly(
                on: weekday,
                hour: hour,
                minute: minute
            )
        case .monthly:
            let day = components.day ?? calendar.component(.day, from: date)
            self = RecurrencePattern.monthly(
                on: day,
                hour: hour,
                minute: minute
            )
        case .yearly:
            let month = components.month ?? calendar.component(.month, from: date)
            let day = components.day ?? calendar.component(.day, from: date)
            self = RecurrencePattern.yearly(
                month: month,
                day: day,
                hour: hour,
                minute: minute
            )
        }
    }

    // MARK: - Validation

    var isValid: Bool {
        // 시간 검증
        guard (0...23).contains(hour) && (0...59).contains(minute) else { return false }

        switch period {
        case .none:
            return true
        case .weekly:
            return weekday != nil && (1...7).contains(weekday!)
        case .monthly:
            return dayOfMonth != nil && (1...31).contains(dayOfMonth!)
        case .yearly:
            guard let month = yearlyMonth, let day = yearlyDay else { return false }
            return (1...12).contains(month) && (1...31).contains(day)
        }
    }

    // MARK: - Display

    var formattedDescription: String {
        let timeString = String(format: "%02d:%02d", hour, minute)

        switch period {
        case .none:
            return "반복 없음"
        case .weekly:
            guard let weekday = weekday else { return "매주 \(timeString)" }
            let weekdays = Calendar.current.weekdaySymbols
            return "매주 \(weekdays[weekday - 1]) \(timeString)"
        case .monthly:
            guard let day = dayOfMonth else { return "매월 \(timeString)" }
            return "매월 \(day)일 \(timeString)"
        case .yearly:
            guard let month = yearlyMonth, let day = yearlyDay else { return "매년 \(timeString)" }
            return "매년 \(month)월 \(day)일 \(timeString)"
        }
    }
}

// MARK: - RecurrencePattern + Calculation

extension RecurrencePattern {

    /// 다음 발생일 계산
    /// - Parameters:
    ///   - date: 기준 날짜 (이 날짜 초과, 기본: 현재 시간)
    ///   - calendar: 계산에 사용할 캘린더
    /// - Returns: date 초과하는 가장 가까운 발생일
    public func calculateNextOccurrence(
        after date: Date = Date(),
        calendar: Calendar = .current
    ) -> Date? {
        switch period {
        case .none:
            return nil

        case .weekly:
            guard let targetWeekday = weekday else { return nil }
            return findNextWeekdayOccurrence(
                targetWeekday: targetWeekday,
                after: date,
                calendar: calendar
            )

        case .monthly:
            guard let targetDay = dayOfMonth else { return nil }
            return findNextMonthlyOccurrence(
                targetDay: targetDay,
                after: date,
                calendar: calendar
            )

        case .yearly:
            guard let targetMonth = yearlyMonth,
                let targetDay = yearlyDay
            else { return nil }
            return findNextYearlyOccurrence(
                targetMonth: targetMonth,
                targetDay: targetDay,
                after: date,
                calendar: calendar
            )
        }
    }

    /// 특정 기간 내의 모든 발생일 계산
    /// - Parameters:
    ///   - startDate: 시작 날짜 (이 날짜 초과)
    ///   - endDate: 종료 날짜 (이 날짜 이하, 기본: 현재 시간)
    ///   - calendar: 계산에 사용할 캘린더
    ///   - maxCount: 과도 생성 방지 상한
    /// - Returns: (startDate, endDate] 범위의 발생일 배열 (오름차순)
    /// - 용도: 거래 내역 생성
    public func calculateOccurrences(
        after startDate: Date,
        upTo endDate: Date = Date(),
        calendar: Calendar = .current,
        maxCount: Int = 50
    ) -> [Date] {
        guard period != .none else { return [] }

        var result: [Date] = []
        var currentDate = startDate

        while result.count < maxCount {
            guard let nextDate = calculateNextOccurrence(
                after: currentDate,
                calendar: calendar
            ) else { break }

            if nextDate <= endDate {
                result.append(nextDate)
                currentDate = nextDate
            } else {
                break
            }
        }

        return result
    }

    // MARK: - Private Helper Methods

    /// DateComponents에 시간 적용
    private func applyTime(to components: inout DateComponents) {
        components.hour = hour
        components.minute = minute
        components.second = 0
    }

    /// 특정 월에서 날짜 생성 시도 (월말 조정 포함)
    private func tryCreateDateInMonth(
        components: inout DateComponents,
        targetDay: Int,
        calendar: Calendar
    ) -> Date? {
        guard let tempDate = calendar.date(from: components) else { return nil }

        let range = calendar.range(of: .day, in: .month, for: tempDate)
        let lastDayOfMonth = range?.upperBound.advanced(by: -1) ?? 28

        // 월말 조정
        components.day = min(targetDay, lastDayOfMonth)
        applyTime(to: &components)
        return calendar.date(from: components)
    }

    /// 다음 주간 발생일 찾기 (after 초과)
    private func findNextWeekdayOccurrence(
        targetWeekday: Int,
        after date: Date,
        calendar: Calendar
    ) -> Date? {
        let components = calendar.dateComponents([.year, .month, .day, .weekday], from: date)
        let currentWeekday = components.weekday ?? 1

        let daysToAdd = (targetWeekday - currentWeekday + 7) % 7

        var targetComponents = DateComponents()
        targetComponents.year = components.year
        targetComponents.month = components.month
        targetComponents.day = (components.day ?? 1) + daysToAdd
        applyTime(to: &targetComponents)

        if let candidate = calendar.date(from: targetComponents), candidate > date {
            return candidate
        }

        targetComponents.day = (targetComponents.day ?? (components.day ?? 1)) + 7
        return calendar.date(from: targetComponents)
    }

    /// 다음 월간 발생일 찾기 (after 초과)
    private func findNextMonthlyOccurrence(
        targetDay: Int,
        after date: Date,
        calendar: Calendar
    ) -> Date? {
        let currentMonthComponents = calendar.dateComponents([.year, .month], from: date)

        var sameMonthComponents = currentMonthComponents
        if let candidate = tryCreateDateInMonth(
            components: &sameMonthComponents,
            targetDay: targetDay,
            calendar: calendar
        ), candidate > date {
            return candidate
        }

        var nextMonthComponents = currentMonthComponents
        nextMonthComponents.month = (nextMonthComponents.month ?? 1) + 1
        return tryCreateDateInMonth(
            components: &nextMonthComponents,
            targetDay: targetDay,
            calendar: calendar
        )
    }

    /// 다음 연간 발생일 찾기 (after 초과)
    private func findNextYearlyOccurrence(
        targetMonth: Int,
        targetDay: Int,
        after date: Date,
        calendar: Calendar
    ) -> Date? {
        var currentYearComponents = calendar.dateComponents([.year], from: date)
        currentYearComponents.month = targetMonth

        var sameYearComponents = currentYearComponents
        if let candidate = tryCreateDateInMonth(
            components: &sameYearComponents,
            targetDay: targetDay,
            calendar: calendar
        ), candidate > date {
            return candidate
        }

        var nextYearComponents = currentYearComponents
        nextYearComponents.year = (nextYearComponents.year ?? calendar.component(.year, from: date)) + 1
        return tryCreateDateInMonth(
            components: &nextYearComponents,
            targetDay: targetDay,
            calendar: calendar
        )
    }
}

// MARK: - TemplateExecutionState

public struct TemplateExecutionState: Codable, Sendable, Hashable {
    public let lastExecutedAt: Date?    // 마지막 실행일 (nil = 아직 실행 안됨)
    public let executionCount: Int      // 총 실행 횟수

    public init(lastExecutedAt: Date? = nil, executionCount: Int = 0) {
        self.lastExecutedAt = lastExecutedAt
        self.executionCount = executionCount
    }

    // 실행 후 상태 업데이트
    public func recordExecution(at date: Date) -> TemplateExecutionState {
        return TemplateExecutionState(
            lastExecutedAt: date,
            executionCount: executionCount + 1
        )
    }
}
