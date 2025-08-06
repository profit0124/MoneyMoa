//
//  TestDataFactory.swift
//  MoneyMoaTests
//
//  Created by Sooik Kim on 7/28/25.
//

import Foundation
@testable import MoneyMoa

// MARK: - Test Data Factory

struct TestDataFactory {
    
    // MARK: - Category Factory Methods
    
    static func createCategory(
        id: UUID = UUID(),
        name: String = "식비",
        iconName: String = "fork.knife",
        type: TransactionType = .variableExpense,
        isActive: Bool = true,
        orderIndex: Int = 0
    ) -> CategoryDTO {
        CategoryDTO(
            id: id,
            name: name,
            iconName: iconName,
            transactionType: type,
            isActive: isActive,
            orderIndex: orderIndex
        )
    }
    
    static func createCategories() -> [CategoryDTO] {
        [
            createCategory(name: "식비", iconName: "fork.knife", type: .variableExpense, orderIndex: 0),
            createCategory(name: "교통비", iconName: "car.fill", type: .variableExpense, orderIndex: 1),
            createCategory(name: "급여", iconName: "banknote", type: .income, orderIndex: 0),
            createCategory(name: "월세", iconName: "house.fill", type: .fixedExpense, orderIndex: 0)
        ]
    }
    
    // MARK: - SubCategory Factory Methods
    
    static func createSubCategory(
        id: UUID = UUID(),
        name: String = "외식비",
        categoryId: UUID,
        categoryIconName: String = "fork.knife",
        type: TransactionType = .variableExpense,
        isActive: Bool = true,
        orderIndex: Int = 0
    ) -> SubCategoryDTO {
        SubCategoryDTO(
            id: id,
            name: name,
            transactionType: type,
            isActive: isActive,
            orderIndex: orderIndex,
            categoryId: categoryId,
            categoryIconName: categoryIconName
        )
    }
    
    static func createSubCategories(for categoryId: UUID, categoryIconName: String = "fork.knife") -> [SubCategoryDTO] {
        [
            createSubCategory(name: "외식비", categoryId: categoryId, categoryIconName: categoryIconName, orderIndex: 0),
            createSubCategory(name: "마트", categoryId: categoryId, categoryIconName: categoryIconName, orderIndex: 1),
            createSubCategory(name: "배달음식", categoryId: categoryId, categoryIconName: categoryIconName, orderIndex: 2)
        ]
    }
    
    // MARK: - PaymentMethod Factory Methods
    
    static func createPaymentMethod(
        id: UUID = UUID(),
        name: String = "신용카드",
        kind: PaymentMethodKind = .credit,
        iconName: String? = nil,
        isActive: Bool = true,
        orderIndex: Int = 0
    ) -> PaymentMethodDTO {
        PaymentMethodDTO(
            id: id,
            name: name,
            kind: kind,
            iconName: iconName,
            orderIndex: orderIndex,
            isActive: isActive
        )
    }
    
    static func createPaymentMethods() -> [PaymentMethodDTO] {
        [
            createPaymentMethod(name: "신용카드", kind: .credit, orderIndex: 0),
            createPaymentMethod(name: "체크카드", kind: .debit, orderIndex: 1),
            createPaymentMethod(name: "현금", kind: .cash, orderIndex: 2),
            createPaymentMethod(name: "계좌이체", kind: .transfer, orderIndex: 3),
            createPaymentMethod(name: "커스텀카드", kind: .credit, iconName: "creditcard.fill", orderIndex: 4)
        ]
    }
    
    // MARK: - Transaction Factory Methods
    
    static func createTransaction(
        id: UUID = UUID(),
        amount: Decimal = 10000,
        date: Date = Date(),
        place: String? = "맥도날드",
        memo: String? = "점심식사",
        transactionType: TransactionType = .variableExpense,
        isFavorite: Bool = false,
        subCategory: SubCategoryDTO,
        paymentMethod: PaymentMethodDTO
    ) -> TransactionDTO {
        TransactionDTO(
            id: id,
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
    
    // MARK: - Date Utilities
    
    static func dateFromDaysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
    }
    
    static func startOfMonth(for date: Date = Date()) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }
    
    static func endOfMonth(for date: Date = Date()) -> Date {
        let calendar = Calendar.current
        guard let startOfMonth = calendar.dateInterval(of: .month, for: date)?.start,
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, second: -1), to: startOfMonth) else {
            return date
        }
        return endOfMonth
    }
    
    // MARK: - Budget Factory Methods
        
    static func createBudgetTemplate(
        id: UUID = UUID(),
        totalAmount: Decimal = 1000000,
        categoryBudgetTemplates: [CategoryBudgetTemplateDTO] = []
    ) -> BudgetTemplateDTO {
        BudgetTemplateDTO(
            id: id,
            totalAmount: totalAmount,
            categoryBudgetTemplates: categoryBudgetTemplates
        )
    }
    
    static func createCategoryBudgetTemplate(
        id: UUID = UUID(),
        amount: Decimal = 300000,
        categoryID: UUID,
        categoryName: String = "식비",
        budgetTemplateId: UUID
    ) -> CategoryBudgetTemplateDTO {
        CategoryBudgetTemplateDTO(
            id: id,
            amount: amount,
            categoryID: categoryID,
            categoryName: categoryName,
            budgetTemplateId: budgetTemplateId
        )
    }
    
    static func createBudget(
        id: UUID = UUID(),
        month: YearMonth = YearMonth.current,
        totalAmount: Decimal = 1000000,
        categoryBudgets: [CategoryBudgetDTO] = []
    ) -> BudgetDTO {
        BudgetDTO(
            id: id,
            month: month,
            totalAmount: totalAmount,
            categoryBudgets: categoryBudgets
        )
    }
    
    static func createCategoryBudget(
        id: UUID = UUID(),
        amount: Decimal = 300000,
        categoryID: UUID,
        categoryName: String = "식비",
        budgetId: UUID
    ) -> CategoryBudgetDTO {
        CategoryBudgetDTO(
            id: id,
            amount: amount,
            categoryID: categoryID,
            categoryName: categoryName,
            budgetId: budgetId
        )
    }
    
    // MARK: - SummaryDisplayData Factory Methods
    
    static func createSummaryDisplayData(
        currentMonthExpense: Decimal = 800000,
        previousMonthExpense: Decimal = 600000,
        monthlyComparison: Decimal? = 200000,
        comparisonPercentage: Double? = 0.33,
        hasPreviousMonthData: Bool = true,
        budget: BudgetDTO? = nil,
        remainingBudget: Decimal? = nil,
        budgetUsagePercentage: Double? = nil
    ) -> SummaryDisplayData {
        SummaryDisplayData(
            currentMonthExpense: currentMonthExpense,
            previousMonthExpense: previousMonthExpense,
            monthlyComparison: monthlyComparison,
            comparisonPercentage: comparisonPercentage,
            hasPreviousMonthData: hasPreviousMonthData,
            budget: budget,
            remainingBudget: remainingBudget,
            budgetUsagePercentage: budgetUsagePercentage
        )
    }
    
    static func createSummaryDisplayDataWithBudget(
        currentMonthExpense: Decimal = 800000,
        budgetAmount: Decimal = 2000000
    ) -> SummaryDisplayData {
        let budget = createBudget(
            totalAmount: budgetAmount,
            categoryBudgets: [
                createCategoryBudget(
                    amount: 800000,
                    categoryID: UUID(),
                    categoryName: "식비",
                    budgetId: UUID()
                ),
                createCategoryBudget(
                    amount: 400000,
                    categoryID: UUID(),
                    categoryName: "교통비",
                    budgetId: UUID()
                )
            ]
        )
        
        return createSummaryDisplayData(
            currentMonthExpense: currentMonthExpense,
            budget: budget,
            remainingBudget: budgetAmount - currentMonthExpense,
            budgetUsagePercentage: Double(truncating: currentMonthExpense as NSNumber) / Double(truncating: budgetAmount as NSNumber)
        )
    }
    
    static func createSummaryDisplayDataWithoutBudget(
        currentMonthExpense: Decimal = 500000
    ) -> SummaryDisplayData {
        createSummaryDisplayData(
            currentMonthExpense: currentMonthExpense,
            previousMonthExpense: 400000,
            monthlyComparison: 100000,
            comparisonPercentage: 0.25,
            budget: nil,
            remainingBudget: nil,
            budgetUsagePercentage: nil
        )
    }
}
