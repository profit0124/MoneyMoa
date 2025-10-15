//
//  RecurrencePatternTests.swift
//  MoneyMoaTests
//
//  Created by Sooik Kim on 9/24/25.
//

import Testing
@testable import MoneyMoa
import Foundation

/// RecurrencePattern 핵심 기능 테스트
///
/// 목적: 반복 패턴 계산 및 날짜 기반 초기화가 일관적으로 동작하는지 검증
/// 시나리오:
/// 1. 월말 / 윤년 클램프 처리
/// 2. 첫 실행 포함 여부
/// 3. 밀린 발생일 일괄 계산
/// 4. 날짜 기반 이니셜라이저가 올바른 요일/일/시간을 채우는지 확인
@Suite("RecurrencePattern Core Logic Tests")
struct RecurrencePatternTests {

    // MARK: - Test Calendar (환경 독립적)

    /// 테스트용 고정 캘린더 (한국 시간대, 그레고리안 캘린더)
    private var testCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        calendar.locale = Locale(identifier: "ko_KR")
        return calendar
    }

    /// 테스트용 날짜 생성 헬퍼 (기본 12:00)
    private func createDate(year: Int, month: Int, day: Int, hour: Int = 12, minute: Int = 0, calendar: Calendar = Calendar(identifier: .gregorian)) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.timeZone = TimeZone(identifier: "Asia/Seoul")!
        return calendar.date(from: components)!
    }

    // MARK: - RecurrencePattern Date-based Init Tests

    @Test("날짜 기반 초기화 - 주간 패턴")
    func testInitFromDateWeekly() {
        let calendar = testCalendar
        let date = createDate(year: 2025, month: 1, day: 20, hour: 15, minute: 30, calendar: calendar) // 2025-01-20 (월요일)

        let pattern = RecurrencePattern(
            from: date,
            period: .weekly,
            calendar: calendar
        )

        #expect(pattern.period == .weekly)
        #expect(pattern.weekday == calendar.component(.weekday, from: date))
        #expect(pattern.hour == 15)
        #expect(pattern.minute == 30)
    }

    @Test("날짜 기반 초기화 - 월간 패턴")
    func testInitFromDateMonthly() {
        let calendar = testCalendar
        let date = createDate(year: 2025, month: 3, day: 5, hour: 8, minute: 10, calendar: calendar)

        let pattern = RecurrencePattern(
            from: date,
            period: .monthly,
            calendar: calendar
        )

        #expect(pattern.period == .monthly)
        #expect(pattern.dayOfMonth == 5)
        #expect(pattern.hour == 8)
        #expect(pattern.minute == 10)
    }

    @Test("날짜 기반 초기화 - 연간 패턴")
    func testInitFromDateYearly() {
        let calendar = testCalendar
        let date = createDate(year: 2025, month: 11, day: 12, hour: 6, minute: 45, calendar: calendar)

        let pattern = RecurrencePattern(
            from: date,
            period: .yearly,
            calendar: calendar
        )

        #expect(pattern.period == .yearly)
        #expect(pattern.yearlyMonth == 11)
        #expect(pattern.yearlyDay == 12)
        #expect(pattern.hour == 6)
        #expect(pattern.minute == 45)
    }

    @Test("날짜 기반 초기화 - 반복 없음")
    func testInitFromDateNone() {
        let calendar = testCalendar
        let date = createDate(year: 2025, month: 7, day: 1, hour: 22, minute: 5, calendar: calendar)

        let pattern = RecurrencePattern(
            from: date,
            period: .none,
            calendar: calendar
        )

        #expect(pattern.period == .none)
        #expect(pattern.hour == 22)
        #expect(pattern.minute == 5)
    }

    // MARK: - 1. 월말 클램프 테스트 (핵심 기능)

    @Test("매월 31일 → 2월 28일로 클램프 (평년)")
    func testMonthlyEndOfMonth_RegularYear() {
        let calendar = testCalendar
        let pattern = RecurrencePattern.monthly(on: 31, endOfMonthRule: .clampToEndOfMonth)
        let afterDate = createDate(year: 2025, month: 1, day: 31, calendar: calendar) // 2025년은 평년

        let nextDate = pattern.calculateNextOccurrence(
            after: afterDate,
            calendar: calendar
        )

        #expect(nextDate != nil, "다음 발생일이 계산되어야 함")

        let components = calendar.dateComponents([.year, .month, .day], from: nextDate!)
        #expect(components.year == 2025, "연도가 2025여야 함")
        #expect(components.month == 2, "월이 2월이어야 함")
        #expect(components.day == 28, "2월 31일이 없으므로 28일로 클램프되어야 함")
    }

    @Test("매월 31일 → 2월 29일로 클램프 (윤년)")
    func testMonthlyEndOfMonth_LeapYear() {
        let calendar = testCalendar
        let pattern = RecurrencePattern.monthly(on: 31, endOfMonthRule: .clampToEndOfMonth)
        let afterDate = createDate(year: 2024, month: 1, day: 31, calendar: calendar) // 2024년은 윤년

        let nextDate = pattern.calculateNextOccurrence(
            after: afterDate,
            calendar: calendar
        )

        #expect(nextDate != nil, "다음 발생일이 계산되어야 함")

        let components = calendar.dateComponents([.year, .month, .day], from: nextDate!)
        #expect(components.year == 2024, "연도가 2024여야 함")
        #expect(components.month == 2, "월이 2월이어야 함")
        #expect(components.day == 29, "윤년 2월 31일이 없으므로 29일로 클램프되어야 함")
    }

    @Test("매년 2월 29일 → 평년에는 2월 28일로 클램프")
    func testYearlyLeapDay_RegularYear() {
        let calendar = testCalendar
        let pattern = RecurrencePattern.yearly(month: 2, day: 29, endOfMonthRule: .clampToEndOfMonth)
        let afterDate = createDate(year: 2024, month: 2, day: 29, calendar: calendar) // 윤년 2월 29일

        let nextDate = pattern.calculateNextOccurrence(
            after: afterDate,
            calendar: calendar
        )

        #expect(nextDate != nil, "다음 발생일이 계산되어야 함")

        let components = calendar.dateComponents([.year, .month, .day], from: nextDate!)
        #expect(components.year == 2025, "연도가 2025여야 함")
        #expect(components.month == 2, "월이 2월이어야 함")
        #expect(components.day == 28, "평년에는 2월 29일이 없으므로 28일로 클램프되어야 함")
    }

    // MARK: - 2. 첫 실행 테스트 (lastAddedAt = nil)

    @Test("첫 실행: 매주 수요일 패턴, 월요일 baseDate")
    func testFirstExecution_Weekly() {
        let calendar = testCalendar
        let pattern = RecurrencePattern.weekly(on: 4) // 수요일 (1=일요일)
        let baseDate = createDate(year: 2025, month: 1, day: 20, calendar: calendar) // 2025-01-20 (월요일)
        let upToDate = createDate(year: 2025, month: 1, day: 25, calendar: calendar) // 토요일

        let dueOccurrences = pattern.calculateOccurrences(
            after: baseDate,
            upTo: upToDate,
            calendar: calendar
        )

        #expect(dueOccurrences.count == 1, "첫 수요일 1개만 반환되어야 함")

        let firstOccurrence = dueOccurrences[0]
        let components = calendar.dateComponents([.year, .month, .day, .weekday], from: firstOccurrence)
        #expect(components.year == 2025, "연도가 맞아야 함")
        #expect(components.month == 1, "월이 맞아야 함")
        #expect(components.day == 22, "2025-01-22 (수요일)이어야 함")
        #expect(components.weekday == 4, "수요일이어야 함")
    }

    @Test("첫 실행: 매월 15일 패턴, 10일 baseDate")
    func testFirstExecution_Monthly() {
        let calendar = testCalendar
        let pattern = RecurrencePattern.monthly(on: 15)
        let baseDate = createDate(year: 2025, month: 1, day: 10, calendar: calendar)
        let upToDate = createDate(year: 2025, month: 2, day: 20, calendar: calendar)

        let dueOccurrences = pattern.calculateOccurrences(
            after: baseDate,
            upTo: upToDate,
            calendar: calendar
        )

        #expect(dueOccurrences.count == 2, "1월 15일, 2월 15일 총 2개")

        // 첫 번째: 2025-01-15
        let first = calendar.dateComponents([.year, .month, .day], from: dueOccurrences[0])
        #expect(first.year == 2025 && first.month == 1 && first.day == 15)

        // 두 번째: 2025-02-15
        let second = calendar.dateComponents([.year, .month, .day], from: dueOccurrences[1])
        #expect(second.year == 2025 && second.month == 2 && second.day == 15)
    }

    // MARK: - 3. 밀린 발생일 계산 테스트

    @Test("밀린 발생일: 매주 금요일, 2주간 실행 안됨")
    func testDueOccurrences_Weekly() {
        let calendar = testCalendar
        let pattern = RecurrencePattern.weekly(on: 6) // 금요일
        let lastExecutedAt = createDate(year: 2025, month: 1, day: 3, calendar: calendar)
        let upToDate = createDate(year: 2025, month: 1, day: 20, calendar: calendar) // 월요일

        let dueOccurrences = pattern.calculateOccurrences(
            after: lastExecutedAt,
            upTo: upToDate,
            calendar: calendar
        )

        #expect(dueOccurrences.count == 2, "1/10, 1/17 금요일 2개가 밀려야 함")

        // 첫 번째 밀린 날: 2025-01-10 (금요일)
        let first = calendar.dateComponents([.year, .month, .day, .weekday], from: dueOccurrences[0])
        #expect(first.year == 2025 && first.month == 1 && first.day == 10 && first.weekday == 6)

        // 두 번째 밀린 날: 2025-01-17 (금요일)
        let second = calendar.dateComponents([.year, .month, .day, .weekday], from: dueOccurrences[1])
        #expect(second.year == 2025 && second.month == 1 && second.day == 17 && second.weekday == 6)
    }

    @Test("밀린 발생일: 매월 30일, 월말 클램프 포함")
    func testDueOccurrences_MonthlyWithEndOfMonth() {
        let calendar = testCalendar
        let pattern = RecurrencePattern.monthly(on: 30, endOfMonthRule: .clampToEndOfMonth)
        let lastExecutedAt = createDate(year: 2025, month: 1, day: 30, calendar: calendar)
        let upToDate = createDate(year: 2025, month: 4, day: 15, calendar: calendar)

        let dueOccurrences = pattern.calculateOccurrences(
            after: lastExecutedAt,
            upTo: upToDate,
            calendar: calendar
        )

        #expect(dueOccurrences.count == 2, "2월(클램프), 3월 총 2개")

        // 첫 번째: 2025-02-28 (2월 30일이 없으므로 클램프)
        let feb = calendar.dateComponents([.year, .month, .day], from: dueOccurrences[0])
        #expect(feb.year == 2025 && feb.month == 2 && feb.day == 28, "2월은 28일로 클램프되어야 함")

        // 두 번째: 2025-03-30
        let mar = calendar.dateComponents([.year, .month, .day], from: dueOccurrences[1])
        #expect(mar.year == 2025 && mar.month == 3 && mar.day == 30, "3월은 30일 그대로")
    }

    // MARK: - 4. 경계 조건 테스트

    @Test("반복 없음 패턴")
    func testNoRecurrence() {
        let calendar = testCalendar
        let pattern = RecurrencePattern(period: .none)
        let baseDate = createDate(year: 2025, month: 1, day: 15, calendar: calendar)

        let nextDate = pattern.calculateNextOccurrence(
            after: baseDate,
            calendar: calendar
        )

        let dueOccurrences = pattern.calculateOccurrences(
            after: baseDate,
            upTo: Date(),
            calendar: calendar
        )

        #expect(nextDate == nil, "반복 없음이면 다음 발생일 없음")
        #expect(dueOccurrences.isEmpty, "반복 없음이면 밀린 발생일 없음")
    }

    @Test("최대 개수 제한")
    func testMaxCountLimit() {
        let calendar = testCalendar
        let pattern = RecurrencePattern.weekly(on: 1) // 매주 일요일
        let baseDate = createDate(year: 2020, month: 1, day: 5, calendar: calendar) // 일요일
        let upToDate = createDate(year: 2025, month: 1, day: 1, calendar: calendar) // 5년 후

        let dueOccurrences = pattern.calculateOccurrences(
            after: baseDate,
            upTo: upToDate,
            calendar: calendar,
            maxCount: 10 // 최대 10개로 제한
        )

        #expect(dueOccurrences.count == 10, "maxCount로 제한되어야 함")
    }

    // MARK: - 5. 패턴 검증 테스트

    @Test("RecurrencePattern 유효성 검증")
    func testPatternValidation() {
        // 유효한 패턴들
        #expect(RecurrencePattern(period: .none).isValid, "none 패턴은 유효")
        #expect(RecurrencePattern.weekly(on: 1).isValid, "일요일 패턴 유효")
        #expect(RecurrencePattern.weekly(on: 7).isValid, "토요일 패턴 유효")
        #expect(RecurrencePattern.monthly(on: 1).isValid, "매월 1일 유효")
        #expect(RecurrencePattern.monthly(on: 31).isValid, "매월 31일 유효")
        #expect(RecurrencePattern.yearly(month: 1, day: 1).isValid, "매년 1월 1일 유효")
        #expect(RecurrencePattern.yearly(month: 12, day: 31).isValid, "매년 12월 31일 유효")

        // 무효한 패턴들
        #expect(!RecurrencePattern(period: .weekly, weekday: 0).isValid, "weekday 0 무효")
        #expect(!RecurrencePattern(period: .weekly, weekday: 8).isValid, "weekday 8 무효")
        #expect(!RecurrencePattern(period: .monthly, dayOfMonth: 0).isValid, "dayOfMonth 0 무효")
        #expect(!RecurrencePattern(period: .monthly, dayOfMonth: 32).isValid, "dayOfMonth 32 무효")
        #expect(!RecurrencePattern(period: .yearly, yearlyMonth: 0, yearlyDay: 1).isValid, "month 0 무효")
        #expect(!RecurrencePattern(period: .yearly, yearlyMonth: 13, yearlyDay: 1).isValid, "month 13 무효")
        #expect(!RecurrencePattern(period: .yearly, yearlyMonth: 1, yearlyDay: 0).isValid, "day 0 무효")
        #expect(!RecurrencePattern(period: .yearly, yearlyMonth: 1, yearlyDay: 32).isValid, "day 32 무효")
    }

    @Test("FormattedDescription 출력")
    func testFormattedDescription() {
        #expect(RecurrencePattern(period: .none).formattedDescription == "반복 없음")
        #expect(RecurrencePattern.weekly(on: 1).formattedDescription == "매주 일요일 09:00")
        #expect(RecurrencePattern.weekly(on: 2).formattedDescription == "매주 월요일 09:00")
        #expect(RecurrencePattern.monthly(on: 15).formattedDescription == "매월 15일 09:00")
        #expect(RecurrencePattern.yearly(month: 3, day: 15).formattedDescription == "매년 3월 15일 09:00")
    }
}
