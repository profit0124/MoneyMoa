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

// MARK: - TransactionDTO Extensions for Formatting

extension TransactionDTO {
    
    /// 거래 금액을 포맷된 문자열로 반환
    public var formattedAmount: String {
        return transactionType.formatAmount(amount)
    }
    
}

#if DEBUG
extension TransactionDTO {
    static let mockLunch = TransactionDTO(
        amount: 15000,
        date: Date(),
        place: "맥도날드 강남점",
        memo: "점심식사",
        transactionType: .variableExpense,
        subCategory: .mockFoodExpense,
        paymentMethod: .mockCreditCard
    )
    
    static let mockTransport = TransactionDTO(
        amount: 25000,
        date: Date(),
        place: nil,
        memo: "교통비",
        transactionType: .variableExpense,
        subCategory: .mockTransportBus,
        paymentMethod: .mockCreditCard
    )
    
    static let mockAllowance = TransactionDTO(
        amount: 50000,
        date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
        place: "아버지",
        memo: "용돈",
        transactionType: .income,
        subCategory: .mockIncomeAllowance,
        paymentMethod: .mockCash
    )
    
    static let mockBeauty = TransactionDTO(
        amount: 80000,
        date: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
        place: "올리브영 홍대점",
        memo: "화장품",
        transactionType: .variableExpense,
        subCategory: .mockBeauty,
        paymentMethod: .mockDebitCard
    )
    
    static let mockSalary = TransactionDTO(
        amount: 120000,
        date: Calendar.current.date(byAdding: .day, value: -4, to: Date()) ?? Date(),
        place: nil,
        memo: "월급",
        transactionType: .income,
        subCategory: .mockSalary,
        paymentMethod: .mockTransfer
    )
    
    static let mockDatas: [TransactionDTO] = [
        mockLunch, mockTransport, mockAllowance, mockBeauty, mockSalary
    ]
    
    static let mockStandardExpense = TransactionDTO(
        amount: 10000,
        transactionType: .variableExpense,
        subCategory: .mockFoodExpense,
        paymentMethod: .mockCreditCard
    )
    
    static let mockStandardIncome = TransactionDTO(
        amount: 50000,
        transactionType: .income,
        subCategory: .mockIncomeAllowance,
        paymentMethod: .mockCash
    )
    
    static func mockWith(
        amount: Decimal = 10000,
        date: Date = Date(),
        place: String? = nil,
        memo: String? = nil,
        transactionType: TransactionType = .variableExpense,
        isFavorite: Bool = false,
        subCategory: SubCategoryDTO,
        paymentMethod: PaymentMethodDTO
    ) -> TransactionDTO {
        return TransactionDTO(
            amount: amount,
            date: date,
            place: place,
            memo: memo,
            transactionType: transactionType,
            isFavorite: isFavorite,
            subCategory: subCategory,
            paymentMethod: paymentMethod
        )
    }
}
#endif
