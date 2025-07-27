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
    var transactionTypeRawValue: String
    var transactionType: TransactionType {
        get { TransactionType(rawValue: transactionTypeRawValue) ?? .variableExpense }
        set { transactionTypeRawValue = newValue.rawValue }
    }
    
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
        self.transactionTypeRawValue = transactionType.rawValue
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
        transactions: [Transaction] = [],
        institutionName: String? = nil,
        accountNumber: String? = nil,
        cardNumber: String? = nil,
        color: String? = nil,
        iconName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.orderIndex = orderIndex
        self.isActive = isActive
        self.transactions = transactions
        self.institutionName = institutionName
        self.accountNumber = accountNumber
        self.cardNumber = cardNumber
        self.color = color
        self.iconName = iconName
    }
}

// MARK: - Transaction to DTO Extensions

extension Transaction {
    /// Transaction을 TransactionDTO로 변환
    public func toDTO() -> TransactionDTO {
        return TransactionDTO(
            id: self.id,
            amount: self.amount,
            date: self.date,
            memo: self.memo,
            transactionType: self.transactionType,
            isFavorite: self.isFavorite,
            subCategory: self.subCategory.toDTO(),
            paymentMethod: self.paymentMethod.toDTO()
        )
    }
}

extension PaymentMethod {
    /// PaymentMethod를 PaymentMethodDTO로 변환
    public func toDTO() -> PaymentMethodDTO {
        return PaymentMethodDTO(
            id: self.id,
            name: self.name,
            kind: self.kind,
            orderIndex: self.orderIndex,
            isActive: self.isActive,
        )
    }
}

// MARK: - Collection Extensions

extension Collection where Element == Transaction {
    /// Transaction 배열을 TransactionDTO 배열로 변환
    func toDTOs() -> [TransactionDTO] {
        return self.map { $0.toDTO() }.sorted()
    }
}

extension Collection where Element == PaymentMethod {
    /// PaymentMethod 배열을 PaymentMethodDTO 배열로 변환
    func toDTOs() -> [PaymentMethodDTO] {
        return self.map { $0.toDTO() }.sorted()
    }
}

// MARK: - DTO to SwiftData Model Extensions

extension TransactionDTO {
    /// TransactionDTO를 SwiftData Transaction 모델로 변환
    /// - Parameters:
    ///   - subCategory: 연결할 SubCategory 모델 (필수)
    ///   - paymentMethod: 연결할 PaymentMethod 모델 (필수)
    func toModel(subCategory: SubCategory, paymentMethod: PaymentMethod) -> Transaction {
        return Transaction(
            id: self.id,
            amount: self.amount,
            date: self.date,
            memo: self.memo,
            transactionType: self.transactionType,
            isFavorite: self.isFavorite,
            subCategory: subCategory,
            paymentMethod: paymentMethod
        )
    }
}

extension PaymentMethodDTO {
    /// PaymentMethodDTO를 SwiftData PaymentMethod 모델로 변환
    func toModel() -> PaymentMethod {
        return PaymentMethod(
            id: self.id,
            name: self.name,
            kind: self.kind,
            orderIndex: self.orderIndex,
            isActive: self.isActive,
        )
    }
}
