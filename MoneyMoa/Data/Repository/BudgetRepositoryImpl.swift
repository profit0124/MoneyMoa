//
//  BudgetRepositoryImpl.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/28/25.
//

import Foundation
import SwiftData

// MARK: - BudgetRepositoryImpl

public class BudgetRepositoryImpl: BudgetRepository {
    private let database: Database
    
    public init(database: Database) {
        self.database = database
    }
    
    // MARK: - Template 관리 (Template Management)
    
    public func fetchBudgetTemplate() async throws -> BudgetTemplateDTO? {
        try await database.withModelContext { context in
            let descriptor = FetchDescriptor<BudgetTemplate>()
            let templates = try context.fetch(descriptor)
            
            // 템플릿은 하나만 존재
            return templates.first?.toDTO(includeCategoryBudgets: false)
        }
    }
    
    public func fetchBudgetTemplateWithCategories() async throws -> BudgetTemplateDTO? {
        try await database.withModelContext { context in
            let descriptor = FetchDescriptor<BudgetTemplate>()
            let templates = try context.fetch(descriptor)
            
            return templates.first?.toDTO(includeCategoryBudgets: true)
        }
    }
    
    public func upsertBudgetTemplate(_ template: BudgetTemplateDTO) async throws {
        try await database.withModelContext { context in
            // 기존 템플릿 삭제 (하나만 존재해야 함)
            let existingDescriptor = FetchDescriptor<BudgetTemplate>()
            let existingTemplates = try context.fetch(existingDescriptor)
            
            for existingTemplate in existingTemplates {
                context.delete(existingTemplate)
            }
            
            // 새 템플릿 생성
            let newTemplate = template.toModel()
            context.insert(newTemplate)
            
            // 카테고리별 예산 템플릿 생성
            for categoryBudgetTemplateDTO in template.categoryBudgetTemplates {
                let categoryBudgetTemplate = categoryBudgetTemplateDTO.toModel(budgetTemplate: newTemplate)
                context.insert(categoryBudgetTemplate)
            }
            
            try context.save()
        }
    }
    
    public func updateCategoryBudgetTemplates(_ categoryBudgetTemplates: [CategoryBudgetTemplateDTO]) async throws {
        try await database.withModelContext { context in
            guard let template = try context.fetch(FetchDescriptor<BudgetTemplate>()).first else {
                throw RepositoryError.budgetTemplateNotFound
            }
            
            // 기존 카테고리별 예산 템플릿 삭제
            let existingDescriptor = FetchDescriptor<CategoryBudgetTemplate>()
            let existingCategoryTemplates = try context.fetch(existingDescriptor)
            
            for existing in existingCategoryTemplates {
                context.delete(existing)
            }
            
            // 새 카테고리별 예산 템플릿 생성
            for categoryBudgetTemplateDTO in categoryBudgetTemplates {
                let categoryBudgetTemplate = categoryBudgetTemplateDTO.toModel(budgetTemplate: template)
                context.insert(categoryBudgetTemplate)
            }
            
            try context.save()
        }
    }
    
    // MARK: - Budget 관리 (Monthly Budget Management)
    
    public func fetchBudget(for month: YearMonth) async throws -> BudgetDTO? {
        try await database.withModelContext { context in
            let predicate = #Predicate<Budget> { $0.month == month }
            let descriptor = FetchDescriptor<Budget>(predicate: predicate)
            
            guard let budget = try context.fetch(descriptor).first else {
                return nil
            }
            
            return budget.toDTO(includeCategoryBudgets: false)
        }
    }
    
    public func fetchBudgetWithCategories(for month: YearMonth) async throws -> BudgetDTO? {
        try await database.withModelContext { context in
            let predicate = #Predicate<Budget> { $0.month == month }
            let descriptor = FetchDescriptor<Budget>(predicate: predicate)
            
            guard let budget = try context.fetch(descriptor).first else {
                return nil
            }
            
            return budget.toDTO(includeCategoryBudgets: true)
        }
    }
    
    public func fetchCurrentBudget() async throws -> BudgetDTO {
        let currentMonth = YearMonth.current
        
        if let existingBudget = try await fetchBudget(for: currentMonth) {
            return existingBudget
        }
        
        // 현재 월 예산이 없으면 자동 생성
        return try await ensureBudgetExists(for: currentMonth)
    }
    
    public func fetchCurrentBudgetWithCategories() async throws -> BudgetDTO {
        let currentMonth = YearMonth.current
        
        if let existingBudget = try await fetchBudgetWithCategories(for: currentMonth) {
            return existingBudget
        }
        
        // 현재 월 예산이 없으면 자동 생성 후 다시 조회
        _ = try await ensureBudgetExists(for: currentMonth)
        return try await fetchBudgetWithCategories(for: currentMonth)!
    }
    
    public func ensureBudgetExists(for month: YearMonth) async throws -> BudgetDTO {
        // 이미 존재하면 반환
        if let existingBudget = try await fetchBudget(for: month) {
            return existingBudget
        }
        
        try await database.withModelContext { context in
            // 템플릿 조회
            guard let template = try context.fetch(FetchDescriptor<BudgetTemplate>()).first else {
                throw RepositoryError.budgetTemplateNotFound
            }
            
            // 템플릿 기반으로 새 예산 생성
            let newBudget = Budget(
                month: month,
                totalAmount: template.totalAmount
            )
            context.insert(newBudget)
            
            // 카테고리별 예산 생성
            for categoryBudgetTemplate in template.categoryBudgetTemplates {
                let categoryBudget = CategoryBudget(
                    template: categoryBudgetTemplate,
                    budget: newBudget
                )
                context.insert(categoryBudget)
            }
            
            try context.save()
        }
        
        return try await fetchBudget(for: month)!
    }
    
    public func fetchRecentBudgets(months: Int = 12) async throws -> [BudgetDTO] {
        try await database.withModelContext { context in
            var descriptor = FetchDescriptor<Budget>(
                sortBy: [SortDescriptor(\.month, order: .reverse)]
            )
            descriptor.fetchLimit = months
            
            let budgets = try context.fetch(descriptor)
            return budgets.toDTOs(includeCategoryBudgets: false)
        }
    }
    
    
    // MARK: - 예산 수정 (Budget Updates)
    
    public func updateBudget(for month: YearMonth, budget: BudgetDTO) async throws {
        try await database.withModelContext { context in
            let predicate = #Predicate<Budget> { $0.month == month }
            let descriptor = FetchDescriptor<Budget>(predicate: predicate)
            
            guard let existingBudget = try context.fetch(descriptor).first else {
                throw RepositoryError.budgetNotFound
            }
            
            // Validation: categoryBudgets 합이 totalAmount 초과하는지 확인
            let categoryBudgetsSum = budget.categoryBudgets.reduce(0) { $0 + $1.amount }
            if categoryBudgetsSum > budget.totalAmount {
                throw RepositoryError.categoryBudgetsExceedTotalAmount
            }
            
            // Budget 정보 업데이트
            existingBudget.totalAmount = budget.totalAmount
            
            // 기존 카테고리별 예산 삭제
            for existingCategoryBudget in existingBudget.categoryBudgets {
                context.delete(existingCategoryBudget)
            }
            
            // 새 카테고리별 예산 생성
            for categoryBudgetDTO in budget.categoryBudgets {
                let categoryBudget = categoryBudgetDTO.toModel(budget: existingBudget)
                context.insert(categoryBudget)
            }
            
            try context.save()
        }
    }
    
    public func updateBudgetTotalAmount(for month: YearMonth, totalAmount: Decimal) async throws {
        try await database.withModelContext { context in
            let predicate = #Predicate<Budget> { $0.month == month }
            let descriptor = FetchDescriptor<Budget>(predicate: predicate)
            
            guard let budget = try context.fetch(descriptor).first else {
                throw RepositoryError.budgetNotFound
            }
            
            // Validation: 기존 categoryBudgets 합이 새로운 totalAmount 초과하는지 확인
            let categoryBudgetsSum = budget.categoryBudgets.reduce(0) { $0 + $1.amount }
            if categoryBudgetsSum > totalAmount {
                throw RepositoryError.categoryBudgetsExceedTotalAmount
            }
            
            budget.totalAmount = totalAmount
            try context.save()
        }
    }
    
    public func updateCategoryBudgets(for month: YearMonth, categoryBudgets: [CategoryBudgetDTO]) async throws {
        try await database.withModelContext { context in
            let predicate = #Predicate<Budget> { $0.month == month }
            let descriptor = FetchDescriptor<Budget>(predicate: predicate)
            
            guard let budget = try context.fetch(descriptor).first else {
                throw RepositoryError.budgetNotFound
            }
            
            // Validation: categoryBudgets 합이 totalAmount 초과하는지 확인
            let categoryBudgetsSum = categoryBudgets.reduce(0) { $0 + $1.amount }
            if categoryBudgetsSum > budget.totalAmount {
                throw RepositoryError.categoryBudgetsExceedTotalAmount
            }
            
            // 기존 카테고리별 예산 삭제
            for existingCategoryBudget in budget.categoryBudgets {
                context.delete(existingCategoryBudget)
            }
            
            // 새 카테고리별 예산 생성
            for categoryBudgetDTO in categoryBudgets {
                let categoryBudget = categoryBudgetDTO.toModel(budget: budget)
                context.insert(categoryBudget)
            }
            
            try context.save()
        }
    }
    
    public func updateCategoryBudget(categoryId: UUID, amount: Decimal, for month: YearMonth) async throws {
        try await database.withModelContext { context in
            let budgetPredicate = #Predicate<Budget> { $0.month == month }
            let budgetDescriptor = FetchDescriptor<Budget>(predicate: budgetPredicate)
            
            guard let budget = try context.fetch(budgetDescriptor).first else {
                throw RepositoryError.budgetNotFound
            }
            
            // 해당 카테고리의 예산 찾기
            guard let categoryBudget = budget.categoryBudgets.first(where: { $0.categoryID == categoryId }) else {
                throw RepositoryError.categoryBudgetNotFound
            }
            
            // Validation: 수정 후 categoryBudgets 합이 totalAmount 초과하는지 확인
            let otherCategoryBudgetsSum = budget.categoryBudgets
                .filter { $0.categoryID != categoryId }
                .reduce(0) { $0 + $1.amount }
            let newCategoryBudgetsSum = otherCategoryBudgetsSum + amount
            
            if newCategoryBudgetsSum > budget.totalAmount {
                throw RepositoryError.categoryBudgetsExceedTotalAmount
            }
            
            categoryBudget.amount = amount
            try context.save()
        }
    }
}
