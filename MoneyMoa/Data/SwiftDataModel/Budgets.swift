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

// MARK: - Budget to DTO Extensions

extension BudgetTemplate {
    /// BudgetTemplate을 BudgetTemplateDTO로 변환
    public func toDTO(includeCategoryBudgets: Bool = false) -> BudgetTemplateDTO {
        let categoryBudgetTemplateDTOs: [CategoryBudgetTemplateDTO] = includeCategoryBudgets ?
        self.categoryBudgetTemplates.toDTOs() : []
        
        return BudgetTemplateDTO(
            id: self.id,
            totalAmount: self.totalAmount,
            categoryBudgetTemplates: categoryBudgetTemplateDTOs
        )
    }
}

extension CategoryBudgetTemplate {
    /// CategoryBudgetTemplate을 CategoryBudgetTemplateDTO로 변환
    public func toDTO() -> CategoryBudgetTemplateDTO {
        return CategoryBudgetTemplateDTO(
            id: self.id,
            amount: self.amount,
            categoryID: self.categoryID,
            categoryName: self.categoryName,
            budgetTemplateId: self.budgetTemplate.id
        )
    }
}

extension Budget {
    /// Budget을 BudgetDTO로 변환
    public func toDTO(includeCategoryBudgets: Bool = false) -> BudgetDTO {
        let categoryBudgetDTOs: [CategoryBudgetDTO] = includeCategoryBudgets ?
        self.categoryBudgets.toDTOs() : []
        
        return BudgetDTO(
            id: self.id,
            month: self.month,
            totalAmount: self.totalAmount,
            categoryBudgets: categoryBudgetDTOs
        )
    }
}

extension CategoryBudget {
    /// CategoryBudget을 CategoryBudgetDTO로 변환
    public func toDTO() -> CategoryBudgetDTO {
        return CategoryBudgetDTO(
            id: self.id,
            amount: self.amount,
            categoryID: self.categoryID,
            categoryName: self.categoryName,
            budgetId: self.budget.id
        )
    }
}

// MARK: - Collection Extensions

extension Collection where Element == BudgetTemplate {
    /// BudgetTemplate 배열을 BudgetTemplateDTO 배열로 변환
    func toDTOs(includeCategoryBudgets: Bool = false) -> [BudgetTemplateDTO] {
        return self.map { $0.toDTO(includeCategoryBudgets: includeCategoryBudgets) }
    }
}

extension Collection where Element == CategoryBudgetTemplate {
    /// CategoryBudgetTemplate 배열을 CategoryBudgetTemplateDTO 배열로 변환
    func toDTOs() -> [CategoryBudgetTemplateDTO] {
        return self.map { $0.toDTO() }.sorted()
    }
}

extension Collection where Element == Budget {
    /// Budget 배열을 BudgetDTO 배열로 변환
    func toDTOs(includeCategoryBudgets: Bool = false) -> [BudgetDTO] {
        return self.map { $0.toDTO(includeCategoryBudgets: includeCategoryBudgets) }.sorted()
    }
}

extension Collection where Element == CategoryBudget {
    /// CategoryBudget 배열을 CategoryBudgetDTO 배열로 변환
    func toDTOs() -> [CategoryBudgetDTO] {
        return self.map { $0.toDTO() }.sorted()
    }
}

// MARK: - DTO to SwiftData Model Extensions

extension BudgetTemplateDTO {
    /// BudgetTemplateDTO를 SwiftData BudgetTemplate 모델로 변환
    /// - Note: 카테고리 예산 템플릿들은 별도로 생성해야 함 (관계형 데이터)
    func toModel() -> BudgetTemplate {
        return BudgetTemplate(
            id: self.id,
            totalAmount: self.totalAmount
        )
    }
    
    /// BudgetTemplateDTO를 SwiftData BudgetTemplate 모델로 변환 (카테고리 포함)
    func toModelWithCategories() -> BudgetTemplate {
        let budgetTemplate = BudgetTemplate(
            id: self.id,
            totalAmount: self.totalAmount
        )
        
        let categoryTemplates = self.categoryBudgetTemplates.map { categoryDTO in
            categoryDTO.toModel(budgetTemplate: budgetTemplate)
        }
        budgetTemplate.categoryBudgetTemplates = categoryTemplates
        
        return budgetTemplate
    }
}

extension CategoryBudgetTemplateDTO {
    /// CategoryBudgetTemplateDTO를 SwiftData CategoryBudgetTemplate 모델로 변환
    /// - Parameter budgetTemplate: 상위 예산 템플릿 모델 (필수)
    func toModel(budgetTemplate: BudgetTemplate) -> CategoryBudgetTemplate {
        return CategoryBudgetTemplate(
            id: self.id,
            amount: self.amount,
            budgetTemplate: budgetTemplate,
            categoryID: self.categoryID,
            categoryName: self.categoryName
        )
    }
}

extension BudgetDTO {
    /// BudgetDTO를 SwiftData Budget 모델로 변환
    /// - Note: 카테고리 예산들은 별도로 생성해야 함 (관계형 데이터)  
    func toModel() -> Budget {
        return Budget(
            id: self.id,
            month: self.month,
            totalAmount: self.totalAmount
        )
    }
}

extension CategoryBudgetDTO {
    /// CategoryBudgetDTO를 SwiftData CategoryBudget 모델로 변환
    /// - Parameter budget: 상위 예산 모델 (필수)
    func toModel(budget: Budget) -> CategoryBudget {
        return CategoryBudget(
            id: self.id,
            amount: self.amount,
            categoryID: self.categoryID,
            categoryName: self.categoryName,
            budget: budget
        )
    }
}
