//
//  Budgets.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/26/25.
//

import Foundation
import SwiftData

// MARK: - Budget Template Model

@Model
final class BudgetTemplate {
    @Attribute(.unique) var id: UUID
    var totalAmount: Decimal
    
    @Relationship(deleteRule: .cascade, inverse: \CategoryBudgetTemplate.budgetTemplate)
    var categoryBudgetTemplates: [CategoryBudgetTemplate] = []
    
    init(
        id: UUID = UUID(),
        totalAmount: Decimal,
    ) {
        self.id = id
        self.totalAmount = totalAmount
    }
}

@Model
final class CategoryBudgetTemplate {
    @Attribute(.unique) var id: UUID
    var amount: Decimal
    
    @Relationship var budgetTemplate: BudgetTemplate
    var categoryID: UUID
    var categoryName: String
    
    init(id: UUID = UUID(),
         amount: Decimal,
         budgetTemplate: BudgetTemplate,
         categoryID: UUID,
         categoryName: String
    ) {
        self.id = id
        self.amount = amount
        self.budgetTemplate = budgetTemplate
        self.categoryID = categoryID
        self.categoryName = categoryName
    }
}

// MARK: - Budget Model

@Model
final class Budget {
    @Attribute(.unique) var id: UUID
    var month: YearMonth
    var totalAmount: Decimal
    
    @Relationship(deleteRule: .cascade, inverse: \CategoryBudget.budget)
    var categoryBudgets: [CategoryBudget] = []
    
    init(id: UUID = UUID(),
         month: YearMonth,
         totalAmount: Decimal) {
        self.id = id
        self.month = month
        self.totalAmount = totalAmount
    }
}

// MARK: - CategoryBudget Model

@Model
final class CategoryBudget {
    @Attribute(.unique) var id: UUID
    var amount: Decimal
    var categoryID: UUID
    var categoryName: String
    
    @Relationship var budget: Budget
    
    init(id: UUID = UUID(),
         amount: Decimal,
         categoryID: UUID,
         categoryName: String,
         budget: Budget
    ) {
        self.id = id
        self.amount = amount
        self.categoryID = categoryID
        self.categoryName = categoryName
        self.budget = budget
    }
    
    init(id: UUID = UUID(),
         template: CategoryBudgetTemplate,
         budget: Budget
    ) {
        self.id = id
        self.amount = template.amount
        self.categoryID = template.categoryID
        self.categoryName = template.categoryName
        self.budget = budget
    }
}
