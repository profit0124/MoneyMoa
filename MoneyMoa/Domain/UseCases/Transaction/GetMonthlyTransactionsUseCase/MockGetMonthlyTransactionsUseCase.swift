//
//  MockGetMonthlyTransactionsUseCase.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/30/25.
//

import Foundation

// MARK: - Mock UseCase for Preview and Testing

public class MockGetMonthlyTransactionsUseCase: GetMonthlyTransactionsUseCase {
    public init() {}
    
    public func execute(yearMonth: YearMonth) async throws -> [TransactionDTO] {
        // Mock Categories
        let expenseCategory = CategoryDTO(
            name: "생활비", 
            iconName: "house.fill",
            transactionType: .variableExpense
        )
        let incomeCategory = CategoryDTO(
            name: "수입", 
            iconName: "plus.circle.fill",
            transactionType: .income
        )
        
        // Mock data for preview and testing
        return [
            TransactionDTO(
                amount: 15000,
                date: Date(),
                place: "맥도날드 강남점",
                memo: "점심식사",
                transactionType: .variableExpense,
                subCategory: SubCategoryDTO(
                    name: "식비",
                    transactionType: .variableExpense,
                    categoryId: expenseCategory.id,
                    categoryIconName: expenseCategory.iconName
                ),
                paymentMethod: PaymentMethodDTO(
                    name: "신용카드",
                    kind: .credit,
                    iconName: "creditcard.fill"  // 커스텀 아이콘 예시
                )
            ),
            TransactionDTO(
                amount: 25000,
                date: Date(),
                place: nil,
                memo: "교통비",
                transactionType: .variableExpense,
                subCategory: SubCategoryDTO(
                    name: "교통",
                    transactionType: .variableExpense,
                    categoryId: expenseCategory.id,
                    categoryIconName: expenseCategory.iconName
                ),
                paymentMethod: PaymentMethodDTO(
                    name: "교통카드",
                    kind: .credit
                )
            ),
            TransactionDTO(
                amount: 50000,
                date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                place: "아버지",
                memo: "용돈",
                transactionType: .income,
                subCategory: SubCategoryDTO(
                    name: "용돈",
                    transactionType: .income,
                    categoryId: incomeCategory.id,
                    categoryIconName: incomeCategory.iconName
                ),
                paymentMethod: PaymentMethodDTO(
                    name: "현금",
                    kind: .cash
                )
            ),
            TransactionDTO(
                amount: 80000,
                date: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
                place: "올리브영 홍대점",
                memo: "화장품",
                transactionType: .variableExpense,
                subCategory: SubCategoryDTO(
                    name: "미용",
                    transactionType: .variableExpense,
                    categoryId: expenseCategory.id,
                    categoryIconName: expenseCategory.iconName
                ),
                paymentMethod: PaymentMethodDTO(
                    name: "체크카드",
                    kind: .debit
                )
            ),
            TransactionDTO(
                amount: 120000,
                date: Calendar.current.date(byAdding: .day, value: -4, to: Date()) ?? Date(),
                place: nil,
                memo: "월급",
                transactionType: .income,
                subCategory: SubCategoryDTO(
                    name: "급여",
                    transactionType: .income,
                    categoryId: incomeCategory.id,
                    categoryIconName: incomeCategory.iconName
                ),
                paymentMethod: PaymentMethodDTO(
                    name: "계좌이체",
                    kind: .transfer
                )
            )
        ]
    }
}
