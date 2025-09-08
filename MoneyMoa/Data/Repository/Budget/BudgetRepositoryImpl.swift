//
//  BudgetRepositoryImpl.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/28/25.
//

import Foundation
import SwiftData

/// Budget Repository 구현체
public final class BudgetRepositoryImpl: BudgetRepository {
    private let database: Database
    
    public init(database: Database) {
        self.database = database
    }
    
    // MARK: - Helper Methods
    
    private func budgetPredicate(for month: YearMonth) -> Predicate<Budget> {
        #Predicate<Budget> { 
            $0.month.year == month.year && $0.month.month == month.month 
        }
    }
    
    private func validateCategoryBudgetsSum(_ budgets: [CategoryBudgetDTO], totalAmount: Decimal) throws {
        let sum = budgets.reduce(0) { $0 + $1.amount }
        guard sum <= totalAmount else {
            throw RepositoryError.categoryBudgetsExceedTotalAmount
        }
    }
    
    private func updateCategoryBudgetsWithDiff(
        existing: [CategoryBudget],
        new: [CategoryBudgetDTO],
        budget: Budget,
        context: ModelContext
    ) {
        // 기존 카테고리 예산을 Map으로 변환
        var existingMap = Dictionary(uniqueKeysWithValues: 
            existing.map { ($0.categoryID, $0) }
        )
        
        // 새로운 카테고리 예산 처리
        for dto in new {
            if let existing = existingMap[dto.categoryID] {
                // UPDATE: 기존 항목 수정
                existing.amount = dto.amount
                existing.categoryName = dto.categoryName
                existingMap.removeValue(forKey: dto.categoryID)
            } else {
                // INSERT: 새 항목 추가
                let categoryBudget = dto.toModel(budget: budget)
                context.insert(categoryBudget)
            }
        }
        
        // DELETE: 남은 기존 항목 삭제
        for (_, categoryBudget) in existingMap {
            context.delete(categoryBudget)
        }
    }
    
    // MARK: - Common Fetch Logic
    
    private func fetchBudgetDTOs(
        predicate: Predicate<Budget>? = nil,
        sortBy: [SortDescriptor<Budget>] = [],
        limit: Int? = nil,
        includeCategoryBudgets: Bool = false
    ) async throws -> [BudgetDTO] {
        try await database.withModelContext { context in
            var descriptor = FetchDescriptor<Budget>(
                predicate: predicate,
                sortBy: sortBy
            )
            if let limit = limit {
                descriptor.fetchLimit = limit
            }
            
            let budgets = try context.fetch(descriptor)
            return budgets.toDTOs(includeCategoryBudgets: includeCategoryBudgets)
        }
    }
    
    private func fetchSingleBudget(
        for month: YearMonth,
        includeCategoryBudgets: Bool = false
    ) async throws -> BudgetDTO? {
        let predicate = budgetPredicate(for: month)
        
        let budgets = try await fetchBudgetDTOs(
            predicate: predicate,
            limit: 1,
            includeCategoryBudgets: includeCategoryBudgets
        )
        
        return budgets.first
    }
    
    // MARK: - BudgetReader Implementation
    
    public func fetchBudget(for month: YearMonth) async throws -> BudgetDTO? {
        try await fetchSingleBudget(for: month, includeCategoryBudgets: false)
    }
    
    public func fetchBudgetWithCategories(for month: YearMonth) async throws -> BudgetDTO? {
        try await fetchSingleBudget(for: month, includeCategoryBudgets: true)
    }
    
    public func fetchCurrentBudget() async throws -> BudgetDTO {
        let currentMonth = YearMonth.current
        
        if let existingBudget = try await fetchBudget(for: currentMonth) {
            return existingBudget
        }
        
        return try await ensureBudgetExists(for: currentMonth)
    }
    
    public func fetchCurrentBudgetWithCategories() async throws -> BudgetDTO {
        let currentMonth = YearMonth.current
        
        // 최적화: ensureBudgetExists가 이미 카테고리 포함된 DTO를 반환하도록 개선
        if let existingBudget = try await fetchBudgetWithCategories(for: currentMonth) {
            return existingBudget
        }
        
        // 생성 후 카테고리 포함하여 반환
        return try await createBudgetFromTemplate(for: currentMonth, includeCategories: true)
    }
    
    public func fetchRecentBudgets(months: Int = 12) async throws -> [BudgetDTO] {
        try await fetchBudgetDTOs(
            sortBy: [
                SortDescriptor(\.month.year, order: .reverse),
                SortDescriptor(\.month.month, order: .reverse)
            ],
            limit: months,
            includeCategoryBudgets: false
        )
    }
    
    // MARK: - BudgetWriter Implementation
    @discardableResult
    public func createBudget(_ budget: BudgetDTO) async throws -> BudgetDTO {
        let predicate = budgetPredicate(for: budget.month)
        return try await database.withModelContext { context in
            let descriptor = FetchDescriptor<Budget>(predicate: predicate)
            let existingBudgets = try context.fetch(descriptor)
            
            if !existingBudgets.isEmpty {
                throw RepositoryError.budgetAlreadyExists
            }
            
            // Create new budget
            let newBudget = Budget(
                month: budget.month,
                totalAmount: budget.totalAmount
            )
            context.insert(newBudget)
            
            // Create category budgets
            for categoryBudgetDTO in budget.categoryBudgets {
                let categoryBudget = CategoryBudget(
                    amount: categoryBudgetDTO.amount,
                    categoryID: categoryBudgetDTO.categoryID,
                    categoryName: categoryBudgetDTO.categoryName,
                    budget: newBudget
                )
                context.insert(categoryBudget)
            }
            
            try context.save()
            
            // Return created budget with actual IDs
            return newBudget.toDTO(includeCategoryBudgets: true)
        }
    }
    
    public func createBudget(for month: YearMonth, budget: BudgetDTO) async throws {
        let predicate = budgetPredicate(for: month)
        return try await database.withModelContext { context in
            let descriptor = FetchDescriptor<Budget>(predicate: predicate)
            let existingBudgets = try context.fetch(descriptor)
            
            // Delete existing budget if any (manually delete CategoryBudgets first)
            for existing in existingBudgets {
                // Manually delete associated CategoryBudgets to avoid relationship issues
                for categoryBudget in existing.categoryBudgets {
                    context.delete(categoryBudget)
                }
                context.delete(existing)
            }
            
            // Create new budget
            let newBudget = Budget(
                month: month,
                totalAmount: budget.totalAmount
            )
            context.insert(newBudget)
            
            // Create category budgets
            for categoryBudgetDTO in budget.categoryBudgets {
                let categoryBudget = CategoryBudget(
                    amount: categoryBudgetDTO.amount,
                    categoryID: categoryBudgetDTO.categoryID,
                    categoryName: categoryBudgetDTO.categoryName,
                    budget: newBudget
                )
                context.insert(categoryBudget)
            }
            
            try context.save()
        }
    }
    
    private func createBudgetFromTemplate(for month: YearMonth, includeCategories: Bool = false) async throws -> BudgetDTO {
        try await database.withModelContext { context in
            // Fetch template
            guard let template = try context.fetch(FetchDescriptor<BudgetTemplate>()).first else {
                throw RepositoryError.budgetTemplateNotFound
            }
            
            // Create budget from template
            let newBudget = Budget(
                month: month,
                totalAmount: template.totalAmount
            )
            context.insert(newBudget)
            
            // Create category budgets from template
            var categoryBudgetDTOs: [CategoryBudgetDTO] = []
            for categoryBudgetTemplate in template.categoryBudgetTemplates {
                let categoryBudget = CategoryBudget(
                    template: categoryBudgetTemplate,
                    budget: newBudget
                )
                context.insert(categoryBudget)
                
                if includeCategories {
                    categoryBudgetDTOs.append(CategoryBudgetDTO(
                        amount: categoryBudget.amount,
                        categoryID: categoryBudget.categoryID,
                        categoryName: categoryBudget.categoryName,
                        budgetId: newBudget.id
                    ))
                }
            }
            
            try context.save()
            
            // Return DTO directly without re-fetching
            return BudgetDTO(
                id: newBudget.id,
                month: month,
                totalAmount: newBudget.totalAmount,
                categoryBudgets: categoryBudgetDTOs
            )
        }
    }
    
    public func ensureBudgetExists(for month: YearMonth) async throws -> BudgetDTO {
        // Return if already exists
        if let existingBudget = try await fetchBudget(for: month) {
            return existingBudget
        }
        
        // Create from template and return directly (no re-fetch)
        return try await createBudgetFromTemplate(for: month, includeCategories: false)
    }
    
    public func updateBudget(for month: YearMonth, budget: BudgetDTO) async throws {
        try validateCategoryBudgetsSum(budget.categoryBudgets, totalAmount: budget.totalAmount)
        
        let predicate = budgetPredicate(for: month)
        return try await database.withModelContext { context in
            let descriptor = FetchDescriptor<Budget>(predicate: predicate)
            
            guard let existingBudget = try context.fetch(descriptor).first else {
                throw RepositoryError.budgetNotFound
            }
            
            // Update budget
            existingBudget.totalAmount = budget.totalAmount
            
            // Diff-based category budgets update
            self.updateCategoryBudgetsWithDiff(
                existing: Array(existingBudget.categoryBudgets),
                new: budget.categoryBudgets,
                budget: existingBudget,
                context: context
            )
            
            try context.save()
        }
    }
    
    public func updateBudgetTotalAmount(for month: YearMonth, totalAmount: Decimal) async throws {
        try await database.withModelContext { context in
            let predicate = self.budgetPredicate(for: month)
            let descriptor = FetchDescriptor<Budget>(predicate: predicate)
            
            guard let budget = try context.fetch(descriptor).first else {
                throw RepositoryError.budgetNotFound
            }
            
            // Validate category budgets sum
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
            let predicate = self.budgetPredicate(for: month)
            let descriptor = FetchDescriptor<Budget>(predicate: predicate)
            
            guard let budget = try context.fetch(descriptor).first else {
                throw RepositoryError.budgetNotFound
            }
            
            try self.validateCategoryBudgetsSum(categoryBudgets, totalAmount: budget.totalAmount)
            
            // Diff-based update
            self.updateCategoryBudgetsWithDiff(
                existing: Array(budget.categoryBudgets),
                new: categoryBudgets,
                budget: budget,
                context: context
            )
            
            try context.save()
        }
    }
    
    public func updateCategoryBudget(categoryId: UUID, amount: Decimal, for month: YearMonth) async throws {
        try await database.withModelContext { context in
            let budgetPredicate = self.budgetPredicate(for: month)
            let budgetDescriptor = FetchDescriptor<Budget>(predicate: budgetPredicate)
            
            guard let budget = try context.fetch(budgetDescriptor).first else {
                throw RepositoryError.budgetNotFound
            }
            
            guard let categoryBudget = budget.categoryBudgets.first(where: { $0.categoryID == categoryId }) else {
                throw RepositoryError.categoryBudgetNotFound
            }
            
            // Validate new sum
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
