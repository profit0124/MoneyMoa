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
    var place: String?  // 거래 장소/대상 (맥도날드, 친구들과 더치페이, 어머니 용돈 등)
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
        place: String? = nil,
        memo: String? = nil,
        transactionType: TransactionType,
        isFavorite: Bool = false,
        subCategory: SubCategory,
        paymentMethod: PaymentMethod
    ) {
        self.id = id
        self.amount = amount
        self.date = date
        self.place = place
        self.memo = memo
        self.transactionTypeRawValue = transactionType.rawValue
        self.isFavorite = isFavorite
        self.subCategory = subCategory
        self.paymentMethod = paymentMethod
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
            place: self.place,
            memo: self.memo,
            transactionType: self.transactionType,
            isFavorite: self.isFavorite,
            subCategory: self.subCategory.toDTO(),
            paymentMethod: self.paymentMethod.toDTO()
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
            place: self.place,
            memo: self.memo,
            transactionType: self.transactionType,
            isFavorite: self.isFavorite,
            subCategory: subCategory,
            paymentMethod: paymentMethod
        )
    }
}
