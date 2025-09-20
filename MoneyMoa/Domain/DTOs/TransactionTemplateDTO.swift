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
    public let processedCount: Int
    public let lastAddedAt: Date
    public let nextDueDate: Date?
    public let timeContext: TransactionTimeContext
    public let subCategory: SubCategoryDTO
    public let paymentMethod: PaymentMethodDTO

    public init(
        id: UUID = UUID(),
        amount: Decimal,
        place: String? = nil,
        memo: String? = nil,
        transactionType: TransactionType,
        recurrencePeriod: RecurrencePeriod = .none,
        createdAt: Date = Date(),
        processedCount: Int = 1,
        lastAddedAt: Date?,
        nextDueDate: Date? = nil,
        timeContext: TransactionTimeContext = .current,
        subCategory: SubCategoryDTO,
        paymentMethod: PaymentMethodDTO
    ) {
        self.id = id
        self.amount = amount
        self.place = place
        self.memo = memo
        self.transactionType = transactionType
        self.recurrencePeriod = recurrencePeriod
        self.createdAt = createdAt
        self.processedCount = processedCount
        self.lastAddedAt = lastAddedAt ?? createdAt
        self.nextDueDate = nextDueDate ?? recurrencePeriod.calculateOccurenceDate(from: createdAt, processCount: processedCount)
        self.timeContext = timeContext
        self.subCategory = subCategory
        self.paymentMethod = paymentMethod
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
    public var formattedRecurrence: String {
        let calendar = timeContext.calendar

        switch recurrencePeriod {
        case .none:
            return "반복 없음"
        case .weekly:
            let createdAt = createdAt
            let weekday = calendar.component(.weekday, from: createdAt)
            let weekdaySymbols = calendar.weekdaySymbols
            return "매주 \(weekdaySymbols[weekday - 1])"

        case .monthly:
            let createdAt = createdAt
            let day = calendar.component(.day, from: createdAt)
            return "매월 \(day)일"

        case .yearly:
            let createdAt = createdAt
            let month = calendar.component(.month, from: createdAt)
            let day = calendar.component(.day, from: createdAt)
            return "매년 \(month)월 \(day)일"
        }
    }

    public var nextDueDateText: String? {
        guard let nextDate = nextDueDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.doesRelativeDateFormatting = true
        return formatter.string(from: nextDate)
    }
}
