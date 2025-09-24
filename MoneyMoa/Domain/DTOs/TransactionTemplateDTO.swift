//
//  TransactionTemplateDTO.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/14/25.
//

import Foundation

// MARK: - TransactionTemplateDTO

public struct TransactionTemplateDTO: Sendable, Hashable, Identifiable {
    public let id: UUID
    public let amount: Decimal
    public let place: String?
    public let memo: String?
    public let transactionType: TransactionType
    public let recurrencePeriod: RecurrencePeriod
    public let createdAt: Date
    public let lastAddedAt: Date?  // Optional로 변경
    public let nextDueDate: Date?
    public let timeContext: TransactionTimeContext
    public let subCategory: SubCategoryDTO
    public let paymentMethod: PaymentMethodDTO

    // 새로운 필드들
    public let recurrencePattern: RecurrencePattern?
    public let executionState: TemplateExecutionState?

    public init(
        id: UUID = UUID(),
        amount: Decimal,
        place: String? = nil,
        memo: String? = nil,
        transactionType: TransactionType,
        recurrencePeriod: RecurrencePeriod = .none,
        createdAt: Date = Date(),
        lastAddedAt: Date? = nil,  // Optional로 변경
        nextDueDate: Date? = nil,
        timeContext: TransactionTimeContext = .current,
        subCategory: SubCategoryDTO,
        paymentMethod: PaymentMethodDTO,
        recurrencePattern: RecurrencePattern? = nil,
        executionState: TemplateExecutionState? = nil
    ) {
        self.id = id
        self.amount = amount
        self.place = place
        self.memo = memo
        self.transactionType = transactionType
        self.recurrencePeriod = recurrencePeriod
        self.createdAt = createdAt
        self.lastAddedAt = lastAddedAt
        self.nextDueDate = nextDueDate
        self.timeContext = timeContext
        self.subCategory = subCategory
        self.paymentMethod = paymentMethod
        self.recurrencePattern = recurrencePattern
        self.executionState = executionState
    }
}

extension TransactionTemplateDTO {
    /// TransactionTemplateDTO를 기반으로 TransactionDTO 생성
    /// - Parameter date: 거래 발생 날짜
    /// - Returns: 생성된 TransactionDTO
    public func toTransaction(date: Date = Date()) -> TransactionDTO {
        return TransactionDTO(
            id: UUID(),
            amount: self.amount,
            date: date,
            place: self.place,
            memo: self.memo,
            transactionType: self.transactionType,
            subCategory: self.subCategory,
            paymentMethod: self.paymentMethod,
            timeContext: self.timeContext,
            transactionTemplate: self
        )
    }
}

extension TransactionTemplateDTO {

    // MARK: - Computed Properties for New Structure

    /// 유효한 반복 패턴 (새 구조 우선, 없으면 기존 구조로 생성)
    public var effectiveRecurrencePattern: RecurrencePattern {
        if let pattern = recurrencePattern {
            return pattern
        }

        // 기존 구조로부터 패턴 생성
        let calendar = timeContext.calendar
        let components = calendar.dateComponents([.weekday, .day, .month], from: createdAt)

        switch recurrencePeriod {
        case .none:
            return RecurrencePattern(period: .none)
        case .weekly:
            return RecurrencePattern.weekly(on: components.weekday ?? 1)
        case .monthly:
            return RecurrencePattern.monthly(on: components.day ?? 1)
        case .yearly:
            return RecurrencePattern.yearly(
                month: components.month ?? 1,
                day: components.day ?? 1
            )
        }
    }

    /// 유효한 실행 상태 (새 구조 우선, 없으면 기존 구조로 생성)
    public var effectiveExecutionState: TemplateExecutionState {
        if let state = executionState {
            return state
        }

        // 기존 구조로부터 상태 생성 (processedCount 제거됨, 기본값 사용)
        return TemplateExecutionState(
            lastExecutedAt: lastAddedAt,
            executionCount: 0
        )
    }

    /// 다음 예정일 계산 (새 구조 사용)
    public var calculatedNextDueDate: Date? {
        let pattern = effectiveRecurrencePattern
        let state = effectiveExecutionState

        guard pattern.period != .none else { return nil }

        return RecurrenceCalculator.calculateNextOccurrence(
            pattern: pattern,
            after: state.lastExecutedAt ?? createdAt,
            calendar: timeContext.calendar
        )
    }

    /// 현재까지 밀린 발생일들 계산
    public func getDueOccurrences(upToDate: Date = Date()) -> [Date] {
        let pattern = effectiveRecurrencePattern
        let state = effectiveExecutionState

        return RecurrenceCalculator.calculateDueOccurrences(
            pattern: pattern,
            lastExecutedAt: state.lastExecutedAt,
            baseDate: createdAt,
            upToDate: upToDate,
            calendar: timeContext.calendar
        )
    }

    /// 실행 후 Template 상태 업데이트
    public func recordExecution(at date: Date) -> TransactionTemplateDTO {
        let newState = effectiveExecutionState.recordExecution(at: date)

        return TransactionTemplateDTO(
            id: self.id,
            amount: self.amount,
            place: self.place,
            memo: self.memo,
            transactionType: self.transactionType,
            recurrencePeriod: self.recurrencePeriod,
            createdAt: self.createdAt,
            lastAddedAt: newState.lastExecutedAt,     // 기존 필드 업데이트
            nextDueDate: calculatedNextDueDate,       // 재계산
            timeContext: self.timeContext,
            subCategory: self.subCategory,
            paymentMethod: self.paymentMethod,
            recurrencePattern: self.effectiveRecurrencePattern,
            executionState: newState
        )
    }

    // MARK: - Legacy Support

    public var formattedRecurrence: String {
        return effectiveRecurrencePattern.formattedDescription
    }

    public var nextDueDateText: String? {
        guard let nextDate = calculatedNextDueDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.doesRelativeDateFormatting = true
        return formatter.string(from: nextDate)
    }
}
