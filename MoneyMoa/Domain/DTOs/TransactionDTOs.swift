//
//  TransactionDTOs.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/27/25.
//

import Foundation

// MARK: - Transaction DTO

public struct TransactionDTO: Sendable, Hashable, Identifiable {
    public let id: UUID
    public let amount: Decimal
    public let date: Date
    public let place: String?  // 거래 장소/대상 (맥도날드, 친구들과 더치페이, 어머니 용돈 등)
    public let memo: String?
    public let transactionType: TransactionType
    public let isFavorite: Bool
    public let subCategory: SubCategoryDTO
    public let paymentMethod: PaymentMethodDTO
    
    public init(
        id: UUID = UUID(),
        amount: Decimal,
        date: Date = Date(),
        place: String? = nil,
        memo: String? = nil,
        transactionType: TransactionType,
        isFavorite: Bool = false,
        subCategory: SubCategoryDTO,
        paymentMethod: PaymentMethodDTO
    ) {
        self.id = id
        self.amount = amount
        self.date = date
        self.place = place
        self.memo = memo
        self.transactionType = transactionType
        self.isFavorite = isFavorite
        self.subCategory = subCategory
        self.paymentMethod = paymentMethod
    }
}
// MARK: - for Sorting

extension TransactionDTO: Comparable {
    static public func < (lhs: TransactionDTO, rhs: TransactionDTO) -> Bool {
        // 날짜 내림차순 정렬 (최신 거래가 먼저)
        if lhs.date != rhs.date {
            return lhs.date > rhs.date
        }
        // 날짜가 같으면 금액 내림차순
        return lhs.amount > rhs.amount
    }
}
