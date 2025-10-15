//
//  TemplatePatternFormViewModelTests.swift
//  MoneyMoaTests
//
//  Created by Sooik Kim on 10/15/25.
//

import Testing
import Foundation
@testable import MoneyMoa

struct TemplatePatternFormViewModelTests {

    // MARK: - 초기화 테스트

    @Test("초기화 시 기본값 확인")
    func testInitialState() async throws {
        // Given & When
        let viewModel = TemplatePatternFormViewModel()

        // Then
        #expect(viewModel.memo == "")
        #expect(viewModel.recurrencePattern.period == .none)
        #expect(viewModel.isValid)
        #expect(viewModel.patternDescription == "일회성 템플릿")
    }

    @Test("초기화 시 커스텀 값 설정")
    func testInitWithCustomValues() async throws {
        // Given
        let customMemo = "테스트 메모"
        let customPattern = RecurrencePattern.weekly(on: 3, hour: 14, minute: 30)

        // When
        let viewModel = TemplatePatternFormViewModel(
            memo: customMemo,
            recurrencePattern: customPattern
        )

        // Then
        #expect(viewModel.memo == customMemo)
        #expect(viewModel.recurrencePattern.period == .weekly)
        #expect(viewModel.recurrencePattern.weekday == 3)
        #expect(viewModel.recurrencePattern.hour == 14)
        #expect(viewModel.recurrencePattern.minute == 30)
    }

    // MARK: - RecurrencePeriod 전환 테스트

    @Test("none에서 weekly로 전환 시 현재 요일과 시간 보존")
    func testSwitchFromNoneToWeekly() async throws {
        // Given
        let initialPattern = RecurrencePattern(period: .none, hour: 10, minute: 30)
        let viewModel = TemplatePatternFormViewModel(recurrencePattern: initialPattern)

        // When
        viewModel.send(.selectRecurrencePeriod(.weekly))

        // Then
        #expect(viewModel.recurrencePattern.period == .weekly)
        #expect(viewModel.recurrencePattern.weekday != nil)
        #expect(viewModel.recurrencePattern.hour == 10) // 시간 보존
        #expect(viewModel.recurrencePattern.minute == 30) // 분 보존
    }

    @Test("none에서 monthly로 전환 시 현재 일과 시간 보존")
    func testSwitchFromNoneToMonthly() async throws {
        // Given
        let initialPattern = RecurrencePattern(period: .none, hour: 15, minute: 45)
        let viewModel = TemplatePatternFormViewModel(recurrencePattern: initialPattern)

        // When
        viewModel.send(.selectRecurrencePeriod(.monthly))

        // Then
        #expect(viewModel.recurrencePattern.period == .monthly)
        #expect(viewModel.recurrencePattern.dayOfMonth != nil)
        #expect(viewModel.recurrencePattern.hour == 15) // 시간 보존
        #expect(viewModel.recurrencePattern.minute == 45) // 분 보존
    }

    @Test("none에서 yearly로 전환 시 현재 월·일과 시간 보존")
    func testSwitchFromNoneToYearly() async throws {
        // Given
        let initialPattern = RecurrencePattern(period: .none, hour: 9, minute: 0)
        let viewModel = TemplatePatternFormViewModel(recurrencePattern: initialPattern)

        // When
        viewModel.send(.selectRecurrencePeriod(.yearly))

        // Then
        #expect(viewModel.recurrencePattern.period == .yearly)
        #expect(viewModel.recurrencePattern.yearlyMonth != nil)
        #expect(viewModel.recurrencePattern.yearlyDay != nil)
        #expect(viewModel.recurrencePattern.hour == 9) // 시간 보존
        #expect(viewModel.recurrencePattern.minute == 0) // 분 보존
    }

    // MARK: - 상세 설정 액션 테스트

    @Test("weekly 패턴에서 요일 변경")
    func testSelectWeekday() async throws {
        // Given
        let viewModel = TemplatePatternFormViewModel(
            recurrencePattern: RecurrencePattern.weekly(on: 2, hour: 10, minute: 0)
        )

        // When
        viewModel.send(.selectWeekday(5)) // 금요일로 변경

        // Then
        #expect(viewModel.recurrencePattern.period == .weekly)
        #expect(viewModel.recurrencePattern.weekday == 5)
        #expect(viewModel.recurrencePattern.hour == 10) // 시간 보존
        #expect(viewModel.recurrencePattern.minute == 0) // 분 보존
    }

    @Test("monthly 패턴에서 일 변경")
    func testSelectDayOfMonth() async throws {
        // Given
        let viewModel = TemplatePatternFormViewModel(
            recurrencePattern: RecurrencePattern.monthly(on: 1, hour: 12, minute: 30)
        )

        // When
        viewModel.send(.selectDayOfMonth(15)) // 15일로 변경

        // Then
        #expect(viewModel.recurrencePattern.period == .monthly)
        #expect(viewModel.recurrencePattern.dayOfMonth == 15)
        #expect(viewModel.recurrencePattern.hour == 12) // 시간 보존
        #expect(viewModel.recurrencePattern.minute == 30) // 분 보존
    }

    @Test("yearly 패턴에서 월 변경")
    func testSelectYearlyMonth() async throws {
        // Given
        let viewModel = TemplatePatternFormViewModel(
            recurrencePattern: RecurrencePattern.yearly(month: 1, day: 1, hour: 9, minute: 0)
        )

        // When
        viewModel.send(.selectYearlyMonth(12)) // 12월로 변경

        // Then
        #expect(viewModel.recurrencePattern.period == .yearly)
        #expect(viewModel.recurrencePattern.yearlyMonth == 12)
        #expect(viewModel.recurrencePattern.yearlyDay == 1) // 일 보존
        #expect(viewModel.recurrencePattern.hour == 9) // 시간 보존
        #expect(viewModel.recurrencePattern.minute == 0) // 분 보존
    }

    @Test("yearly 패턴에서 일 변경")
    func testSelectYearlyDay() async throws {
        // Given
        let viewModel = TemplatePatternFormViewModel(
            recurrencePattern: RecurrencePattern.yearly(month: 6, day: 1, hour: 14, minute: 0)
        )

        // When
        viewModel.send(.selectYearlyDay(25)) // 25일로 변경

        // Then
        #expect(viewModel.recurrencePattern.period == .yearly)
        #expect(viewModel.recurrencePattern.yearlyMonth == 6) // 월 보존
        #expect(viewModel.recurrencePattern.yearlyDay == 25)
        #expect(viewModel.recurrencePattern.hour == 14) // 시간 보존
        #expect(viewModel.recurrencePattern.minute == 0) // 분 보존
    }

    // MARK: - 시간 설정 테스트

    @Test("none 패턴에서 시간 변경")
    func testSetHourInNonePeriod() async throws {
        // Given
        let viewModel = TemplatePatternFormViewModel(
            recurrencePattern: RecurrencePattern(period: .none, hour: 9, minute: 30)
        )

        // When
        viewModel.send(.setHour(15))

        // Then
        #expect(viewModel.recurrencePattern.period == .none)
        #expect(viewModel.recurrencePattern.hour == 15)
        #expect(viewModel.recurrencePattern.minute == 30) // 분 보존
    }

    @Test("weekly 패턴에서 분 변경")
    func testSetMinuteInWeeklyPeriod() async throws {
        // Given
        let viewModel = TemplatePatternFormViewModel(
            recurrencePattern: RecurrencePattern.weekly(on: 3, hour: 10, minute: 0)
        )

        // When
        viewModel.send(.setMinute(45))

        // Then
        #expect(viewModel.recurrencePattern.period == .weekly)
        #expect(viewModel.recurrencePattern.weekday == 3) // 요일 보존
        #expect(viewModel.recurrencePattern.hour == 10) // 시 보존
        #expect(viewModel.recurrencePattern.minute == 45)
    }

    @Test("monthly 패턴에서 시·분 순차 변경")
    func testSetHourAndMinuteInMonthlyPeriod() async throws {
        // Given
        let viewModel = TemplatePatternFormViewModel(
            recurrencePattern: RecurrencePattern.monthly(on: 15, hour: 9, minute: 0)
        )

        // When
        viewModel.send(.setHour(14))
        viewModel.send(.setMinute(30))

        // Then
        #expect(viewModel.recurrencePattern.period == .monthly)
        #expect(viewModel.recurrencePattern.dayOfMonth == 15) // 일 보존
        #expect(viewModel.recurrencePattern.hour == 14)
        #expect(viewModel.recurrencePattern.minute == 30)
    }

    // MARK: - patternDescription 테스트

    @Test("none 패턴 설명")
    func testPatternDescriptionForNone() async throws {
        // Given
        let viewModel = TemplatePatternFormViewModel(
            recurrencePattern: RecurrencePattern(period: .none)
        )

        // When & Then
        #expect(viewModel.patternDescription == "일회성 템플릿")
    }

    @Test("weekly 패턴 설명")
    func testPatternDescriptionForWeekly() async throws {
        // Given
        let viewModel = TemplatePatternFormViewModel(
            recurrencePattern: RecurrencePattern.weekly(on: 1) // 일요일
        )

        // When
        let description = viewModel.patternDescription

        // Then
        #expect(description.contains("매주"))
    }

    @Test("monthly 패턴 설명")
    func testPatternDescriptionForMonthly() async throws {
        // Given
        let viewModel = TemplatePatternFormViewModel(
            recurrencePattern: RecurrencePattern.monthly(on: 15)
        )

        // When
        let description = viewModel.patternDescription

        // Then
        #expect(description == "매월 15일")
    }

    @Test("yearly 패턴 설명")
    func testPatternDescriptionForYearly() async throws {
        // Given
        let viewModel = TemplatePatternFormViewModel(
            recurrencePattern: RecurrencePattern.yearly(month: 12, day: 25)
        )

        // When
        let description = viewModel.patternDescription

        // Then
        #expect(description.contains("매년"))
        #expect(description.contains("25일"))
    }

    // MARK: - summary 테스트

    @Test("빈 메모와 none 패턴일 때 summary")
    func testSummaryWithEmptyMemoAndNonePeriod() async throws {
        // Given
        let viewModel = TemplatePatternFormViewModel(
            memo: "",
            recurrencePattern: RecurrencePattern(period: .none)
        )

        // When
        let summary = viewModel.summary

        // Then
        #expect(summary == "🔄 일회성 템플릿")
    }

    @Test("짧은 메모와 weekly 패턴일 때 summary")
    func testSummaryWithShortMemoAndWeeklyPeriod() async throws {
        // Given
        let shortMemo = "월급날"
        let viewModel = TemplatePatternFormViewModel(
            memo: shortMemo,
            recurrencePattern: RecurrencePattern.weekly(on: 2)
        )

        // When
        let summary = viewModel.summary

        // Then
        #expect(summary.contains("📝 월급날"))
        #expect(summary.contains("매주"))
    }

    @Test("긴 메모(20자 초과)일 때 summary에서 잘림")
    func testSummaryWithLongMemoTruncation() async throws {
        // Given
        let longMemo = "이것은 매우 긴 메모입니다. 20자를 초과하는 메모는 요약되어야 합니다."
        let viewModel = TemplatePatternFormViewModel(
            memo: longMemo,
            recurrencePattern: RecurrencePattern.monthly(on: 1)
        )

        // When
        let summary = viewModel.summary

        // Then
        #expect(summary.contains("...")) // 잘림 표시
        #expect(!summary.contains(longMemo)) // 전체 메모는 포함되지 않음
    }

    // MARK: - isValid 테스트

    @Test("모든 패턴이 유효함")
    func testIsValidForAllPatterns() async throws {
        // Given
        let patterns: [RecurrencePattern] = [
            RecurrencePattern(period: .none),
            RecurrencePattern.weekly(on: 3),
            RecurrencePattern.monthly(on: 15),
            RecurrencePattern.yearly(month: 6, day: 10)
        ]

        // When & Then
        for pattern in patterns {
            let viewModel = TemplatePatternFormViewModel(recurrencePattern: pattern)
            #expect(viewModel.isValid)
        }
    }
}
