//
//  TransactionTemplateDTOTests.swift
//  MoneyMoaTests
//
//  Created by Generated on 3/7/24.
//

import Testing
@testable import MoneyMoa
import Foundation

@Suite("TransactionTemplateDTO Scheduling Tests")
struct TransactionTemplateDTOTests {

    // MARK: - Helpers

    private var testTimeContext: TransactionTimeContext {
        TransactionTimeContext(
            timeZoneIdentifier: "Asia/Seoul",
            calendarIdentifier: "gregorian",
            localeIdentifier: "ko_KR"
        )
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        calendar.locale = Locale(identifier: "ko_KR")
        return calendar
    }

    private func january(_ day: Int, hour: Int = 9, minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = 2025
        components.month = 1
        components.day = day
        components.hour = hour
        components.minute = minute
        components.timeZone = TimeZone(identifier: "Asia/Seoul")
        return calendar.date(from: components)!
    }

    private func makeWeeklyTemplate(createdAt: Date, executionState: TemplateExecutionState = TemplateExecutionState()) -> TransactionTemplateDTO {
        let weekday = calendar.component(.weekday, from: createdAt)
        let hour = calendar.component(.hour, from: createdAt)
        let minute = calendar.component(.minute, from: createdAt)

        let pattern = RecurrencePattern.weekly(
            on: weekday,
            hour: hour,
            minute: minute
        )

        return TransactionTemplateDTO(
            amount: 1000,
            place: "테스트",
            memo: "주간 패턴",
            transactionType: .fixedExpense,
            recurrencePeriod: .weekly,
            createdAt: createdAt,
            timeContext: testTimeContext,
            subCategory: .mockFoodExpense,
            paymentMethod: .mockCreditCard,
            recurrencePattern: pattern,
            executionState: executionState
        )
    }

    // MARK: - Tests

    @Test("calculatedNextDueDate가 첫 실행을 포함한다")
    func testCalculatedNextDueDateIncludesFirstOccurrence() {
        let createdAt = january(6) // 2025-01-06 (월요일) 09:00
        let template = makeWeeklyTemplate(createdAt: createdAt)

        let nextDueDate = template.calculatedNextDueDate

        #expect(nextDueDate == createdAt, "첫 예정 실행일이 누락되면 안 된다")
    }

    @Test("getDueOccurrences가 아직 실행되지 않은 첫 슬롯을 반환한다")
    func testGetDueOccurrencesReturnsFirstSlotWhenNeverExecuted() {
        let createdAt = january(6)
        let template = makeWeeklyTemplate(createdAt: createdAt)

        let occurrences = template.getDueOccurrences(upToDate: createdAt)

        #expect(occurrences.count == 1)
        #expect(occurrences.first == createdAt)
    }

    @Test("recordExecution 후 실행 상태와 다음 예정일이 업데이트된다")
    func testRecordExecutionUpdatesStateAndNextDueDate() {
        let createdAt = january(6)
        let template = makeWeeklyTemplate(createdAt: createdAt)

        let executedTemplate = template.recordExecution(at: createdAt)

        #expect(executedTemplate.executionState.lastExecutedAt == createdAt)
        #expect(executedTemplate.executionState.executionCount == 1)

        let expectedNext = calendar.date(byAdding: .day, value: 7, to: createdAt)
        #expect(executedTemplate.nextDueDate == expectedNext)
    }

    @Test("TransactionDTO.toTemplateDTO가 패턴과 실행 상태를 채운다")
    func testTransactionDTOToTemplateDTOPopulatesPatternAndState() {
        let transactionDate = january(10)
        let transaction = TransactionDTO(
            id: UUID(),
            amount: 5000,
            date: transactionDate,
            place: "카페",
            memo: "월간 회비",
            transactionType: .fixedExpense,
            subCategory: .mockFoodExpense,
            paymentMethod: .mockCreditCard,
            timeContext: testTimeContext
        )

        let template = transaction.toTemplateDTO(
            recurrencePeriod: .monthly
        )

        #expect(template.recurrencePattern.period == .monthly)
        #expect(template.recurrencePattern.dayOfMonth == calendar.component(.day, from: transactionDate))
        #expect(template.recurrencePattern.hour == calendar.component(.hour, from: transactionDate))
        #expect(template.recurrencePattern.minute == calendar.component(.minute, from: transactionDate))

        #expect(template.executionState.lastExecutedAt == transactionDate)
        #expect(template.executionState.executionCount == 1)

        let expectedNext = calendar.date(byAdding: .month, value: 1, to: transactionDate)
        #expect(template.nextDueDate == expectedNext)
    }
}
