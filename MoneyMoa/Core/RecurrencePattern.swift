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
    let endOfMonthRule: EndOfMonthRule

    init(
        period: RecurrencePeriod,
        dayOfMonth: Int? = nil,
        weekday: Int? = nil,
        yearlyMonth: Int? = nil,
        yearlyDay: Int? = nil,
        endOfMonthRule: EndOfMonthRule = .clampToEndOfMonth
    ) {
        self.period = period
        self.dayOfMonth = dayOfMonth
        self.weekday = weekday
        self.yearlyMonth = yearlyMonth
        self.yearlyDay = yearlyDay
        self.endOfMonthRule = endOfMonthRule
    }

    // MARK: - Factory Methods

    static func weekly(on weekday: Int) -> RecurrencePattern {
        return RecurrencePattern(
            period: .weekly,
            weekday: weekday
        )
    }

    static func monthly(on day: Int, endOfMonthRule: EndOfMonthRule = .clampToEndOfMonth) -> RecurrencePattern {
        return RecurrencePattern(
            period: .monthly,
            dayOfMonth: day,
            endOfMonthRule: endOfMonthRule
        )
    }

    static func yearly(month: Int, day: Int, endOfMonthRule: EndOfMonthRule = .clampToEndOfMonth) -> RecurrencePattern {
        return RecurrencePattern(
            period: .yearly,
            yearlyMonth: month,
            yearlyDay: day,
            endOfMonthRule: endOfMonthRule
        )
    }

    // MARK: - Validation

    var isValid: Bool {
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
        switch period {
        case .none:
            return "반복 없음"
        case .weekly:
            guard let weekday = weekday else { return "매주" }
            let weekdays = Calendar.current.weekdaySymbols
            return "매주 \(weekdays[weekday - 1])"
        case .monthly:
            guard let day = dayOfMonth else { return "매월" }
            return "매월 \(day)일"
        case .yearly:
            guard let month = yearlyMonth, let day = yearlyDay else { return "매년" }
            return "매년 \(month)월 \(day)일"
        }
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
