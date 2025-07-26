//
//  Transaction.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/26/25.
//

import Foundation
import SwiftData

// MARK: - Transaction Model

@Model
final class Transaction {
    @Attribute(.unique) var id: UUID
    var amount: Decimal
    var date: Date
    var memo: String?
    var isFavorite: Bool
    var transactionType: TransactionType
    
    @Relationship var subCategory: SubCategory
    @Relationship var paymentMethod: PaymentMethod
    
    init(
        id: UUID = UUID(),
        amount: Decimal,
        date: Date = Date(),
        memo: String? = nil,
        transactionType: TransactionType,
        isFavorite: Bool = false,
        subCategory: SubCategory,
        paymentMethod: PaymentMethod
    ) {
        self.id = id
        self.amount = amount
        self.date = date
        self.memo = memo
        self.transactionType = transactionType
        self.isFavorite = isFavorite
        self.subCategory = subCategory
        self.paymentMethod = paymentMethod
    }
}

// MARK: - Payment Method Model

@Model
final class PaymentMethod {
    @Attribute(.unique) var id: UUID
    var name: String
    var kind: PaymentMethodKind
    var orderIndex: Int
    var isActive: Bool
    
    @Relationship(deleteRule: .cascade, inverse: \Transaction.paymentMethod)
    var transactions: [Transaction]
    
    // Detailed information(추후 추가)
    var institutionName: String?
    var accountNumber: String?
    var cardNumber: String?
    var color: String?
    var iconName: String?
    
    init(
        id: UUID = UUID(),
        name: String,
        kind: PaymentMethodKind,
        orderIndex: Int = 0,
        isActive: Bool = true,
        transactions: [Transaction] = []
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.orderIndex = orderIndex
        self.isActive = isActive
        self.transactions = transactions
    }
}
