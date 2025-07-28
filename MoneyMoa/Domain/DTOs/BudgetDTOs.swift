//
//  BudgetDTOs.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/28/25.
//

import Foundation

// MARK: - BudgetTemplate DTO

public struct BudgetTemplateDTO: Sendable, Hashable, Identifiable {
    public let id: UUID
    public let totalAmount: Decimal
    public let categoryBudgetTemplates: [CategoryBudgetTemplateDTO]
    
    public init(
        id: UUID = UUID(),
        totalAmount: Decimal,
        categoryBudgetTemplates: [CategoryBudgetTemplateDTO] = []
    ) {
        self.id = id
        self.totalAmount = totalAmount
        self.categoryBudgetTemplates = categoryBudgetTemplates
    }
}

// MARK: - CategoryBudgetTemplate DTO

public struct CategoryBudgetTemplateDTO: Sendable, Hashable, Identifiable {
    public let id: UUID
    public let amount: Decimal
    public let categoryID: UUID
    public let categoryName: String
    public let budgetTemplateId: UUID
    
    public init(
        id: UUID = UUID(),
        amount: Decimal,
        categoryID: UUID,
        categoryName: String,
        budgetTemplateId: UUID
    ) {
        self.id = id
        self.amount = amount
        self.categoryID = categoryID
        self.categoryName = categoryName
        self.budgetTemplateId = budgetTemplateId
    }
}

// MARK: - Budget DTO

public struct BudgetDTO: Sendable, Hashable, Identifiable {
    public let id: UUID
    public let month: YearMonth
    public let totalAmount: Decimal
    public let categoryBudgets: [CategoryBudgetDTO]
    
    public init(
        id: UUID = UUID(),
        month: YearMonth,
        totalAmount: Decimal,
        categoryBudgets: [CategoryBudgetDTO] = []
    ) {
        self.id = id
        self.month = month
        self.totalAmount = totalAmount
        self.categoryBudgets = categoryBudgets
    }
}

// MARK: - CategoryBudget DTO

public struct CategoryBudgetDTO: Sendable, Hashable, Identifiable {
    public let id: UUID
    public let amount: Decimal
    public let categoryID: UUID
    public let categoryName: String
    public let budgetId: UUID
    
    public init(
        id: UUID = UUID(),
        amount: Decimal,
        categoryID: UUID,
        categoryName: String,
        budgetId: UUID
    ) {
        self.id = id
        self.amount = amount
        self.categoryID = categoryID
        self.categoryName = categoryName
        self.budgetId = budgetId
    }
}

// MARK: - Comparable Extensions

extension BudgetDTO: Comparable {
    public static func < (lhs: BudgetDTO, rhs: BudgetDTO) -> Bool {
        // YearMonth 기준 내림차순 정렬 (최신 월이 먼저)
        lhs.month > rhs.month
    }
}

extension CategoryBudgetDTO: Comparable {
    public static func < (lhs: CategoryBudgetDTO, rhs: CategoryBudgetDTO) -> Bool {
        // 카테고리 이름 기준 오름차순 정렬
        lhs.categoryName < rhs.categoryName
    }
}

extension CategoryBudgetTemplateDTO: Comparable {
    public static func < (lhs: CategoryBudgetTemplateDTO, rhs: CategoryBudgetTemplateDTO) -> Bool {
        // 카테고리 이름 기준 오름차순 정렬
        lhs.categoryName < rhs.categoryName
    }
}