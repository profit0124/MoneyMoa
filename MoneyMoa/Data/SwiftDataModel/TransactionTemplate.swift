//
//  TransactionTemplate.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/14/25.
//

import Foundation
import SwiftData

// MARK: - TransactionTemplate Model

@Model
final class TransactionTemplate {
    @Attribute(.unique) var id: UUID
    var amount: Decimal
    var place: String?
    var memo: String?
    var transactionTypeRawValue: String
    var transactionType: TransactionType {
        get { TransactionType(rawValue: transactionTypeRawValue) ?? .fixedExpense }
        set { transactionTypeRawValue = newValue.rawValue }
    }

    // MARK: - Recurrence Fields
    var recurrencePeriodRawValue: String
    var recurrencePeriod: RecurrencePeriod {
        get { RecurrencePeriod(rawValue: recurrencePeriodRawValue) ?? .none }
        set { recurrencePeriodRawValue = newValue.rawValue }
    }
    var createdAt: Date
    var lastAddedAt: Date?  // 마지막 동기화 시점 (Optional로 변경)
    var nextDueDate: Date?

    // 새로운 RecurrencePattern 저장을 위한 필드들
    var recurrencePatternData: Data?  // JSON encoded RecurrencePattern
    var executionStateData: Data?     // JSON encoded TemplateExecutionState

    // MARK: - TimeZone Context Fields
    var timeZoneIdentifier: String
    var calendarIdentifier: String
    var localeIdentifier: String?

    @Relationship var subCategory: SubCategory
    @Relationship var paymentMethod: PaymentMethod
    @Relationship(deleteRule: .nullify, inverse: \Transaction.template)
    var transactions: [Transaction] = []

    init(id: UUID = UUID(),
         amount: Decimal,
         place: String? = nil,
         memo: String? = nil,
         transactionType: TransactionType,
         recurrencePeriod: RecurrencePeriod = .none,
         createdAt: Date = Date(),
         lastAddedAt: Date? = nil,
         nextDueDate: Date? = nil,
         originalDayOfMonth: Int? = nil,
         timeZoneIdentifier: String,
         calendarIdentifier: String,
         localeIdentifier: String? = nil,
         subCategory: SubCategory,
         paymentMethod: PaymentMethod,
         recurrencePattern: RecurrencePattern? = nil,
         executionState: TemplateExecutionState? = nil
    ) {
        self.id = id
        self.amount = amount
        self.place = place
        self.memo = memo
        self.transactionTypeRawValue = transactionType.rawValue
        self.recurrencePeriodRawValue = recurrencePeriod.rawValue
        self.createdAt = createdAt
        self.lastAddedAt = lastAddedAt
        self.nextDueDate = nextDueDate
        self.timeZoneIdentifier = timeZoneIdentifier
        self.calendarIdentifier = calendarIdentifier
        self.localeIdentifier = localeIdentifier
        self.subCategory = subCategory
        self.paymentMethod = paymentMethod

        // 새 필드들 초기화
        self.recurrencePatternData = try? JSONEncoder().encode(recurrencePattern)
        self.executionStateData = try? JSONEncoder().encode(executionState)
    }
}

// MARK: - RecurrencePattern & ExecutionState Support

extension TransactionTemplate {

    /// RecurrencePattern 접근을 위한 계산 프로퍼티
    var recurrencePattern: RecurrencePattern? {
        get {
            guard let data = recurrencePatternData else { return nil }
            return try? JSONDecoder().decode(RecurrencePattern.self, from: data)
        }
        set {
            recurrencePatternData = try? JSONEncoder().encode(newValue)
        }
    }

    /// TemplateExecutionState 접근을 위한 계산 프로퍼티
    var executionState: TemplateExecutionState? {
        get {
            guard let data = executionStateData else { return nil }
            return try? JSONDecoder().decode(TemplateExecutionState.self, from: data)
        }
        set {
            executionStateData = try? JSONEncoder().encode(newValue)
        }
    }
}

// MARK: - TransactionTemplate to DTO Extensions

extension TransactionTemplate {
    /// TransactionTemplate을 TransactionTemplateDTO로 변환
    public func toDTO() -> TransactionTemplateDTO {
        let timeContext = TransactionTimeContext(
            timeZoneIdentifier: timeZoneIdentifier,
            calendarIdentifier: calendarIdentifier,
            localeIdentifier: localeIdentifier
        )

        return TransactionTemplateDTO(
            id: self.id,
            amount: self.amount,
            place: self.place,
            memo: self.memo,
            transactionType: self.transactionType,
            recurrencePeriod: self.recurrencePeriod,
            createdAt: self.createdAt,
            lastAddedAt: self.lastAddedAt,
            nextDueDate: self.nextDueDate,
            timeContext: timeContext,
            subCategory: self.subCategory.toDTO(),
            paymentMethod: self.paymentMethod.toDTO(),
            recurrencePattern: self.recurrencePattern,  // 새 필드
            executionState: self.executionState         // 새 필드
        )
    }
}

// MARK: - DTO to SwiftData Model Extensions

extension TransactionTemplateDTO {
    /// TransactionTemplateDTO를 SwiftData TransactionTemplate 모델로 변환
    func toModel(subCategory: SubCategory, paymentMethod: PaymentMethod) -> TransactionTemplate {
        let template = TransactionTemplate(
            id: self.id,
            amount: self.amount,
            place: self.place,
            memo: self.memo,
            transactionType: self.transactionType,
            recurrencePeriod: self.recurrencePeriod,
            createdAt: self.createdAt,
            lastAddedAt: self.lastAddedAt,
            nextDueDate: self.nextDueDate,
            originalDayOfMonth: nil,  // 필요시 계산
            timeZoneIdentifier: self.timeContext.timeZoneIdentifier,
            calendarIdentifier: self.timeContext.calendarIdentifier,
            localeIdentifier: self.timeContext.localeIdentifier,
            subCategory: subCategory,
            paymentMethod: paymentMethod,
            recurrencePattern: self.recurrencePattern,  // 새 필드
            executionState: self.executionState         // 새 필드
        )
        return template
    }
}
