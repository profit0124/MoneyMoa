//
//  MockBudgetRepository.swift
//  MoneyMoa
//
//  Created by Claude Code on 9/8/25.
//

import Foundation

/// Mock Budget Repository for Testing and Previews
/// - Provides realistic test data with configurable scenarios  
/// - Supports error simulation and delay testing
/// - Includes budget management and monthly operations
public final class MockBudgetRepository: @unchecked Sendable, BudgetRepository {

    // MARK: - Mock Control Properties
    
    /// Simulated delay for async operations (seconds)
    public var delay: TimeInterval = 0
    
    /// Flag to simulate failures
    public var shouldFail = false
    
    /// Custom error to throw when shouldFail is true
    public var errorToThrow: Error = MockError.simulatedFailure
    
    // MARK: - Data Storage
    
    private var budgets: [YearMonth: BudgetDTO] = [:]
    private let templateRepository: MockBudgetTemplateRepository
    
    // MARK: - Thread Safety
    
    private let serialQueue = DispatchQueue(label: "MockBudgetRepository.serialQueue", qos: .utility)
    
    // MARK: - Scenarios
    
    public enum DataScenario {
        case empty
        case minimal
        case normal
        case multipleMonths
        case realistic
    }
    
    // MARK: - Initialization
    
    public init(scenario: DataScenario = .normal, templateRepository: MockBudgetTemplateRepository? = nil) {
        self.templateRepository = templateRepository ?? MockBudgetTemplateRepository(scenario: .normal)
        loadScenario(scenario)
    }
    
    public func loadScenario(_ scenario: DataScenario) {
        budgets.removeAll()
        
        switch scenario {
        case .empty:
            // No budgets
            break
        case .minimal:
            let budget = BudgetFactory.minimal()
            budgets[budget.month] = budget
        case .normal:
            let budget = BudgetFactory.normal()
            budgets[budget.month] = budget
        case .multipleMonths:
            let multipleBudgets = BudgetFactory.multipleMonths(count: 6)
            for budget in multipleBudgets {
                budgets[budget.month] = budget
            }
        case .realistic:
            let recentBudgets = BudgetFactory.recentHistory()
            for budget in recentBudgets {
                budgets[budget.month] = budget
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func simulateDelay() async throws {
        if delay > 0 {
            try await Task.sleep(for: .seconds(delay))
        }
    }
    
    private func checkFailure() throws {
        if shouldFail {
            throw errorToThrow
        }
    }
    
    private func validateCategoryBudgetsSum(_ categoryBudgets: [CategoryBudgetDTO], totalAmount: Decimal) throws {
        let sum = categoryBudgets.reduce(0) { $0 + $1.amount }
        if sum > totalAmount {
            throw MockError.simulatedFailure // Using closest mock error for validation
        }
    }
    
    // MARK: - BudgetReader Implementation
    
    public func fetchBudget(for month: YearMonth) async throws -> BudgetDTO? {
        try await simulateDelay()
        try checkFailure()
        
        return await withCheckedContinuation { continuation in
            serialQueue.async {
                let budget = self.budgets[month]
                let result = budget.map { budget in
                    BudgetDTO(
                        id: budget.id,
                        month: budget.month,
                        totalAmount: budget.totalAmount,
                        categoryBudgets: [] // Without categories as per interface
                    )
                }
                continuation.resume(returning: result)
            }
        }
    }
    
    public func fetchBudgetWithCategories(for month: YearMonth) async throws -> BudgetDTO? {
        try await simulateDelay()
        try checkFailure()
        
        return await withCheckedContinuation { continuation in
            serialQueue.async {
                continuation.resume(returning: self.budgets[month])
            }
        }
    }
    
    public func fetchCurrentBudget() async throws -> BudgetDTO {
        try await simulateDelay()
        try checkFailure()
        
        return try await ensureBudgetExists(for: YearMonth.current)
    }
    
    public func fetchCurrentBudgetWithCategories() async throws -> BudgetDTO {
        try await simulateDelay()
        try checkFailure()
        
        let currentMonth = YearMonth.current
        if let existingBudget = budgets[currentMonth] {
            return existingBudget
        }
        
        // Create from template with categories
        return try await createBudgetFromTemplate(for: currentMonth, includeCategories: true)
    }
    
    public func fetchRecentBudgets(months: Int = 12) async throws -> [BudgetDTO] {
        try await simulateDelay()
        try checkFailure()
        
        return await withCheckedContinuation { continuation in
            serialQueue.async {
                let result = Array(self.budgets.values)
                    .sorted { $0.month > $1.month }
                    .prefix(months)
                    .map { budget in
                        BudgetDTO(
                            id: budget.id,
                            month: budget.month,
                            totalAmount: budget.totalAmount,
                            categoryBudgets: [] // Without categories as per interface
                        )
                    }
                continuation.resume(returning: Array(result))
            }
        }
    }
    
    // MARK: - BudgetWriter Implementation
    
    @discardableResult
    public func createBudget(_ budget: BudgetDTO) async throws -> BudgetDTO {
        try await simulateDelay()
        try checkFailure()
        
        return try await withCheckedThrowingContinuation { continuation in
            serialQueue.async {
                // Check if budget already exists
                if self.budgets[budget.month] != nil {
                    continuation.resume(throwing: MockError.simulatedFailure) // Using closest mock error
                    return
                }
                
                // Validate category budgets sum
                do {
                    try self.validateCategoryBudgetsSum(budget.categoryBudgets, totalAmount: budget.totalAmount)
                } catch {
                    continuation.resume(throwing: error)
                    return
                }
                
                let createdBudget = BudgetDTO(
                    id: budget.id,
                    month: budget.month,
                    totalAmount: budget.totalAmount,
                    categoryBudgets: budget.categoryBudgets
                )
                self.budgets[budget.month] = createdBudget
                continuation.resume(returning: createdBudget)
            }
        }
    }
    
    public func createBudget(for month: YearMonth, budget: BudgetDTO) async throws {
        try await simulateDelay()
        try checkFailure()
        
        return try await withCheckedThrowingContinuation { continuation in
            serialQueue.async {
                // Validate category budgets sum
                do {
                    try self.validateCategoryBudgetsSum(budget.categoryBudgets, totalAmount: budget.totalAmount)
                } catch {
                    continuation.resume(throwing: error)
                    return
                }
                
                let newBudget = BudgetDTO(
                    id: budget.id,
                    month: month,
                    totalAmount: budget.totalAmount,
                    categoryBudgets: budget.categoryBudgets
                )
                self.budgets[month] = newBudget
                continuation.resume(returning: ())
            }
        }
    }
    
    public func ensureBudgetExists(for month: YearMonth) async throws -> BudgetDTO {
        try await simulateDelay()
        try checkFailure()
        
        // Return if already exists
        if let existingBudget = budgets[month] {
            return BudgetDTO(
                id: existingBudget.id,
                month: existingBudget.month,
                totalAmount: existingBudget.totalAmount,
                categoryBudgets: [] // Without categories
            )
        }
        
        // Create from template
        return try await createBudgetFromTemplate(for: month, includeCategories: false)
    }
    
    public func updateBudget(for month: YearMonth, budget: BudgetDTO) async throws {
        try await simulateDelay()
        try checkFailure()
        
        return try await withCheckedThrowingContinuation { continuation in
            serialQueue.async {
                guard self.budgets[month] != nil else {
                    continuation.resume(throwing: MockError.budgetNotFound)
                    return
                }
                
                // Validate category budgets sum
                do {
                    try self.validateCategoryBudgetsSum(budget.categoryBudgets, totalAmount: budget.totalAmount)
                } catch {
                    continuation.resume(throwing: error)
                    return
                }
                
                let updatedBudget = BudgetDTO(
                    id: budget.id,
                    month: month,
                    totalAmount: budget.totalAmount,
                    categoryBudgets: budget.categoryBudgets
                )
                self.budgets[month] = updatedBudget
                continuation.resume()
            }
        }
    }
    
    public func updateBudgetTotalAmount(for month: YearMonth, totalAmount: Decimal) async throws {
        try await simulateDelay()
        try checkFailure()
        
        return try await withCheckedThrowingContinuation { continuation in
            serialQueue.async {
                guard let existingBudget = self.budgets[month] else {
                    continuation.resume(throwing: MockError.budgetNotFound)
                    return
                }
                
                // Validate category budgets sum doesn't exceed new total
                let categorySum = existingBudget.categoryBudgets.reduce(0) { $0 + $1.amount }
                if categorySum > totalAmount {
                    continuation.resume(throwing: MockError.simulatedFailure) // Using closest mock error
                    return
                }
                
                let updatedBudget = BudgetDTO(
                    id: existingBudget.id,
                    month: existingBudget.month,
                    totalAmount: totalAmount,
                    categoryBudgets: existingBudget.categoryBudgets
                )
                self.budgets[month] = updatedBudget
                continuation.resume()
            }
        }
    }
    
    public func updateCategoryBudgets(for month: YearMonth, categoryBudgets: [CategoryBudgetDTO]) async throws {
        try await simulateDelay()
        try checkFailure()
        
        return try await withCheckedThrowingContinuation { continuation in
            serialQueue.async {
                guard let existingBudget = self.budgets[month] else {
                    continuation.resume(throwing: MockError.budgetNotFound)
                    return
                }
                
                // Validate category budgets sum
                do {
                    try self.validateCategoryBudgetsSum(categoryBudgets, totalAmount: existingBudget.totalAmount)
                } catch {
                    continuation.resume(throwing: error)
                    return
                }
                
                let updatedBudget = BudgetDTO(
                    id: existingBudget.id,
                    month: existingBudget.month,
                    totalAmount: existingBudget.totalAmount,
                    categoryBudgets: categoryBudgets
                )
                self.budgets[month] = updatedBudget
                continuation.resume()
            }
        }
    }
    
    public func updateCategoryBudget(categoryId: UUID, amount: Decimal, for month: YearMonth) async throws {
        try await simulateDelay()
        try checkFailure()
        
        return try await withCheckedThrowingContinuation { continuation in
            serialQueue.async {
                guard let existingBudget = self.budgets[month] else {
                    continuation.resume(throwing: MockError.budgetNotFound)
                    return
                }
                
                guard let categoryIndex = existingBudget.categoryBudgets.firstIndex(where: { $0.categoryID == categoryId }) else {
                    continuation.resume(throwing: MockError.simulatedFailure) // Using closest mock error for category not found
                    return
                }
                
                var updatedCategoryBudgets = existingBudget.categoryBudgets
                updatedCategoryBudgets[categoryIndex] = CategoryBudgetDTO(
                    id: updatedCategoryBudgets[categoryIndex].id,
                    amount: amount,
                    categoryID: updatedCategoryBudgets[categoryIndex].categoryID,
                    categoryName: updatedCategoryBudgets[categoryIndex].categoryName,
                    budgetId: updatedCategoryBudgets[categoryIndex].budgetId
                )
                
                // Validate total doesn't exceed budget
                let totalCategoryAmount = updatedCategoryBudgets.reduce(0) { $0 + $1.amount }
                if totalCategoryAmount > existingBudget.totalAmount {
                    continuation.resume(throwing: MockError.simulatedFailure) // Using closest mock error
                    return
                }
                
                let updatedBudget = BudgetDTO(
                    id: existingBudget.id,
                    month: existingBudget.month,
                    totalAmount: existingBudget.totalAmount,
                    categoryBudgets: updatedCategoryBudgets
                )
                self.budgets[month] = updatedBudget
                continuation.resume()
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func createBudgetFromTemplate(for month: YearMonth, includeCategories: Bool) async throws -> BudgetDTO {
        // Get template from template repository
        guard let template = try await templateRepository.fetchBudgetTemplateWithCategories() else {
            throw MockError.budgetTemplateNotFound
        }
        
        let budgetId = UUID()
        let categoryBudgets = includeCategories ? template.categoryBudgetTemplates.map { templateCategory in
            CategoryBudgetDTO(
                amount: templateCategory.amount,
                categoryID: templateCategory.categoryID,
                categoryName: templateCategory.categoryName,
                budgetId: budgetId
            )
        } : []
        
        let newBudget = BudgetDTO(
            id: budgetId,
            month: month,
            totalAmount: template.totalAmount,
            categoryBudgets: categoryBudgets
        )
        
        budgets[month] = newBudget
        return newBudget
    }
    
    // MARK: - Testing Utilities
    
    /// Clear all data (useful for testing)
    public func clearData() {
        serialQueue.sync {
            budgets.removeAll()
        }
    }
    
    /// Check if budget exists for month
    public func hasBudget(for month: YearMonth) -> Bool {
        return serialQueue.sync {
            budgets[month] != nil
        }
    }
    
    /// Get current budgets count synchronously (for testing)
    public var budgetCount: Int {
        return serialQueue.sync {
            budgets.count
        }
    }
    
    /// Get all budgets synchronously (for testing)
    public var allBudgets: [BudgetDTO] {
        return serialQueue.sync {
            Array(budgets.values).sorted { $0.month > $1.month }
        }
    }
}

// MARK: - Convenience Extensions

public extension MockBudgetRepository {
    
    /// Create with specific budgets
    convenience init(budgets: [BudgetDTO], templateRepository: MockBudgetTemplateRepository? = nil) {
        self.init(scenario: .empty, templateRepository: templateRepository)
        for budget in budgets {
            self.budgets[budget.month] = budget
        }
    }
    
    /// Add budget directly (for testing)
    func addBudget(_ budget: BudgetDTO) {
        serialQueue.sync {
            self.budgets[budget.month] = budget
        }
    }
    
    /// Set budgets directly (for testing)
    func setBudgets(_ budgets: [BudgetDTO]) {
        serialQueue.sync {
            self.budgets.removeAll()
            for budget in budgets {
                self.budgets[budget.month] = budget
            }
        }
    }
}
