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
    public let recurrencePattern: RecurrencePattern
    public let executionState: TemplateExecutionState

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
        recurrencePattern: RecurrencePattern,
        executionState: TemplateExecutionState = TemplateExecutionState()
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

    /// 다음 예정일 계산 (새 구조 사용)
    public var calculatedNextDueDate: Date? {
        guard recurrencePattern.period != .none else { return nil }
        let calendar = timeContext.calendar

        if let lastExecuted = executionState.lastExecutedAt {
            return recurrencePattern.calculateNextOccurrence(
                after: lastExecuted,
                calendar: calendar
            )
        }

        let anchor = calendar.date(byAdding: .second, value: -1, to: createdAt) ?? createdAt.addingTimeInterval(-1)

        return recurrencePattern.calculateNextOccurrence(
            after: anchor,
            calendar: timeContext.calendar
        )
    }

    /// 현재까지 밀린 발생일들 계산
    public func getDueOccurrences(upToDate: Date = Date()) -> [Date] {
        let calendar = timeContext.calendar

        let anchor: Date
        if let lastExecuted = executionState.lastExecutedAt {
            anchor = lastExecuted
        } else {
            anchor = calendar.date(byAdding: .second, value: -1, to: createdAt) ?? createdAt.addingTimeInterval(-1)
        }

        return recurrencePattern.calculateOccurrences(
            after: anchor,
            upTo: upToDate,
            calendar: calendar
        )
    }

    /// 실행 후 Template 상태 업데이트
    public func recordExecution(at date: Date) -> TransactionTemplateDTO {
        let newState = executionState.recordExecution(at: date)
        let nextDueDateAfterExecution = recurrencePattern.calculateNextOccurrence(
            after: date,
            calendar: timeContext.calendar
        )

        return TransactionTemplateDTO(
            id: self.id,
            amount: self.amount,
            place: self.place,
            memo: self.memo,
            transactionType: self.transactionType,
            recurrencePeriod: self.recurrencePeriod,
            createdAt: self.createdAt,
            lastAddedAt: newState.lastExecutedAt,     // 기존 필드 업데이트
            nextDueDate: nextDueDateAfterExecution,   // 실행 시점 기준 재계산
            timeContext: self.timeContext,
            subCategory: self.subCategory,
            paymentMethod: self.paymentMethod,
            recurrencePattern: self.recurrencePattern,
            executionState: newState
        )
    }

    // MARK: - Legacy Support

    public var formattedRecurrence: String {
        return recurrencePattern.formattedDescription
    }

    public var nextDueDateText: String? {
        guard let nextDate = calculatedNextDueDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.doesRelativeDateFormatting = true
        return formatter.string(from: nextDate)
    }
}
