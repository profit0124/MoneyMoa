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
        processedCount: Int = 0,
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
        self.nextDueDate = nextDueDate
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
            isFavorite: false,
            subCategory: self.subCategory,
            paymentMethod: self.paymentMethod,
            timeContext: self.timeContext,
            transactionTemplate: self
        )
    }
}
