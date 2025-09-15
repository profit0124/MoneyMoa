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
    var processedCount: Int  // 처리된 거래 횟수 (Count 기반)
    var lastAddedAt: Date  // 마지막 동기화 시점
    var nextDueDate: Date?

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
         processedCount: Int = 0,
         lastAddedAt: Date? = nil,
         nextDueDate: Date? = nil,
         originalDayOfMonth: Int? = nil,
         timeZoneIdentifier: String,
         calendarIdentifier: String,
         localeIdentifier: String? = nil,
         subCategory: SubCategory,
         paymentMethod: PaymentMethod
    ) {
        self.id = id
        self.amount = amount
        self.place = place
        self.memo = memo
        self.transactionTypeRawValue = transactionType.rawValue
        self.recurrencePeriodRawValue = recurrencePeriod.rawValue
        self.createdAt = createdAt
        self.processedCount = processedCount
        self.lastAddedAt = lastAddedAt ?? createdAt
        self.nextDueDate = nextDueDate
        self.timeZoneIdentifier = timeZoneIdentifier
        self.calendarIdentifier = calendarIdentifier
        self.localeIdentifier = localeIdentifier
        self.subCategory = subCategory
        self.paymentMethod = paymentMethod
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
            processedCount: self.processedCount,
            lastAddedAt: self.lastAddedAt,
            nextDueDate: self.nextDueDate,
            timeContext: timeContext,
            subCategory: self.subCategory.toDTO(),
            paymentMethod: self.paymentMethod.toDTO()
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
            processedCount: self.processedCount,
            lastAddedAt: self.lastAddedAt,
            nextDueDate: self.nextDueDate,
            originalDayOfMonth: nil,  // 필요시 계산
            timeZoneIdentifier: self.timeContext.timeZoneIdentifier,
            calendarIdentifier: self.timeContext.calendarIdentifier,
            localeIdentifier: self.timeContext.localeIdentifier,
            subCategory: subCategory,
            paymentMethod: paymentMethod
        )
        return template
    }
}
