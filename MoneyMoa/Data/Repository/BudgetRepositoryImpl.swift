//
//  BudgetRepositoryImpl.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/28/25.
//

import Foundation
import SwiftData

/// Budget Repository 구현체
public final class BudgetRepositoryImpl: CompleteBudgetRepository {
    private let database: Database
    
    public init(database: Database) {
        self.database = database
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
        let predicate = #Predicate<Budget> {
            $0.month.year == month.year && $0.month.month == month.month
        }
        
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
        
        if let existingBudget = try await fetchBudgetWithCategories(for: currentMonth) {
            return existingBudget
        }
        
        _ = try await ensureBudgetExists(for: currentMonth)
        return try await fetchBudgetWithCategories(for: currentMonth)!
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
    
    public func createBudget(_ budget: BudgetDTO) async throws -> BudgetDTO {
        try await database.withModelContext { context in
            let year = budget.month.year
            let month = budget.month.month
            
            // Check for existing budget
            let predicate = #Predicate<Budget> {
                $0.month.year == year && $0.month.month == month
            }
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
            return budget
        }
    }
    
    public func createBudget(for month: YearMonth, budget: BudgetDTO) async throws {
        try await database.withModelContext { context in
            // Delete existing budget if any
            let predicate = #Predicate<Budget> {
                $0.month.year == month.year && $0.month.month == month.month
            }
            let descriptor = FetchDescriptor<Budget>(predicate: predicate)
            let existingBudgets = try context.fetch(descriptor)
            
            for existing in existingBudgets {
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
    
    public func ensureBudgetExists(for month: YearMonth) async throws -> BudgetDTO {
        // Return if already exists
        if let existingBudget = try await fetchBudget(for: month) {
            return existingBudget
        }
        
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
    
    public func updateBudget(for month: YearMonth, budget: BudgetDTO) async throws {
        try await database.withModelContext { context in
            let predicate = #Predicate<Budget> {
                $0.month.year == month.year && $0.month.month == month.month
            }
            let descriptor = FetchDescriptor<Budget>(predicate: predicate)
            
            guard let existingBudget = try context.fetch(descriptor).first else {
                throw RepositoryError.budgetNotFound
            }
            
            // Validate category budgets sum
            let categoryBudgetsSum = budget.categoryBudgets.reduce(0) { $0 + $1.amount }
            if categoryBudgetsSum > budget.totalAmount {
                throw RepositoryError.categoryBudgetsExceedTotalAmount
            }
            
            // Update budget
            existingBudget.totalAmount = budget.totalAmount
            
            // Replace category budgets
            for existingCategoryBudget in existingBudget.categoryBudgets {
                context.delete(existingCategoryBudget)
            }
            
            for categoryBudgetDTO in budget.categoryBudgets {
                let categoryBudget = categoryBudgetDTO.toModel(budget: existingBudget)
                context.insert(categoryBudget)
            }
            
            try context.save()
        }
    }
    
    public func updateBudgetTotalAmount(for month: YearMonth, totalAmount: Decimal) async throws {
        try await database.withModelContext { context in
            let predicate = #Predicate<Budget> {
                $0.month.year == month.year && $0.month.month == month.month
            }
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
            let predicate = #Predicate<Budget> {
                $0.month.year == month.year && $0.month.month == month.month
            }
            let descriptor = FetchDescriptor<Budget>(predicate: predicate)
            
            guard let budget = try context.fetch(descriptor).first else {
                throw RepositoryError.budgetNotFound
            }
            
            // Validate category budgets sum
            let categoryBudgetsSum = categoryBudgets.reduce(0) { $0 + $1.amount }
            if categoryBudgetsSum > budget.totalAmount {
                throw RepositoryError.categoryBudgetsExceedTotalAmount
            }
            
            // Replace category budgets
            for existingCategoryBudget in budget.categoryBudgets {
                context.delete(existingCategoryBudget)
            }
            
            for categoryBudgetDTO in categoryBudgets {
                let categoryBudget = categoryBudgetDTO.toModel(budget: budget)
                context.insert(categoryBudget)
            }
            
            try context.save()
        }
    }
    
    public func updateCategoryBudget(categoryId: UUID, amount: Decimal, for month: YearMonth) async throws {
        try await database.withModelContext { context in
            let budgetPredicate = #Predicate<Budget> {
                $0.month.year == month.year && $0.month.month == month.month
            }
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
    
    // MARK: - BudgetTemplateReader Implementation
    
    public func fetchBudgetTemplate() async throws -> BudgetTemplateDTO? {
        try await database.withModelContext { context in
            let descriptor = FetchDescriptor<BudgetTemplate>()
            let templates = try context.fetch(descriptor)
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
    
    // MARK: - BudgetTemplateWriter Implementation
    
    public func upsertBudgetTemplate(_ template: BudgetTemplateDTO) async throws {
        try await database.withModelContext { context in
            let existingDescriptor = FetchDescriptor<BudgetTemplate>()
            let existingTemplates = try context.fetch(existingDescriptor)
            
            if let existingTemplate = existingTemplates.first {
                // Update existing template
                existingTemplate.totalAmount = template.totalAmount
                
                // Replace category budget templates
                for existingCategoryBudget in existingTemplate.categoryBudgetTemplates {
                    context.delete(existingCategoryBudget)
                }
                
                for categoryBudgetTemplateDTO in template.categoryBudgetTemplates {
                    let categoryBudgetTemplate = categoryBudgetTemplateDTO.toModel(budgetTemplate: existingTemplate)
                    context.insert(categoryBudgetTemplate)
                }
            } else {
                // Create new template
                let newTemplate = template.toModelWithCategories()
                context.insert(newTemplate)
            }
            
            try context.save()
        }
    }
    
    @discardableResult
    public func createBudgetTemplate(_ template: BudgetTemplateDTO) async throws -> BudgetTemplateDTO {
        try await database.withModelContext { context in
            let newTemplate = template.toModelWithCategories()
            context.insert(newTemplate)
            try context.save()
            
            return newTemplate.toDTO(includeCategoryBudgets: true)
        }
    }
    
    @discardableResult
    public func updateBudgetTemplate(_ template: BudgetTemplateDTO) async throws -> BudgetTemplateDTO {
        try await database.withModelContext { context in
            let descriptor = FetchDescriptor<BudgetTemplate>()
            
            guard let existingTemplate = try context.fetch(descriptor).first else {
                throw RepositoryError.budgetTemplateNotFound
            }
            
            // Update template
            existingTemplate.totalAmount = template.totalAmount
            
            // Replace category budget templates
            for existingCategoryBudget in existingTemplate.categoryBudgetTemplates {
                context.delete(existingCategoryBudget)
            }
            
            for categoryBudgetTemplateDTO in template.categoryBudgetTemplates {
                let categoryBudgetTemplate = categoryBudgetTemplateDTO.toModel(budgetTemplate: existingTemplate)
                context.insert(categoryBudgetTemplate)
            }
            
            try context.save()
            
            return existingTemplate.toDTO(includeCategoryBudgets: true)
        }
    }
    
    public func updateCategoryBudgetTemplates(_ categoryBudgetTemplates: [CategoryBudgetTemplateDTO]) async throws {
        try await database.withModelContext { context in
            guard let template = try context.fetch(FetchDescriptor<BudgetTemplate>()).first else {
                throw RepositoryError.budgetTemplateNotFound
            }
            
            // Replace all category budget templates
            let existingDescriptor = FetchDescriptor<CategoryBudgetTemplate>()
            let existingCategoryTemplates = try context.fetch(existingDescriptor)
            
            for existing in existingCategoryTemplates {
                context.delete(existing)
            }
            
            for categoryBudgetTemplateDTO in categoryBudgetTemplates {
                let categoryBudgetTemplate = categoryBudgetTemplateDTO.toModel(budgetTemplate: template)
                context.insert(categoryBudgetTemplate)
            }
            
            try context.save()
        }
    }
}
