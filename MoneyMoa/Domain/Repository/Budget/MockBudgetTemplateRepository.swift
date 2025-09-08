//
//  MockBudgetTemplateRepository.swift
//  MoneyMoa
//
//  Created by Claude Code on 9/8/25.
//

import Foundation

/// Mock BudgetTemplate Repository for Testing and Previews
/// - Provides realistic test data with configurable scenarios  
/// - Supports error simulation and delay testing
/// - Includes template management and validation
public final class MockBudgetTemplateRepository: @unchecked Sendable, BudgetTemplateRepository {

    // MARK: - Mock Control Properties
    
    /// Simulated delay for async operations (seconds)
    public var delay: TimeInterval = 0
    
    /// Flag to simulate failures
    public var shouldFail = false
    
    /// Custom error to throw when shouldFail is true
    public var errorToThrow: Error = MockError.simulatedFailure
    
    // MARK: - Data Storage
    
    private var budgetTemplate: BudgetTemplateDTO?
    
    // MARK: - Thread Safety
    
    private let serialQueue = DispatchQueue(label: "MockBudgetTemplateRepository.serialQueue", qos: .utility)
    
    // MARK: - Scenarios
    
    public enum DataScenario {
        case empty
        case minimal
        case normal
        case lowIncome
        case middleIncome
        case highIncome
        case realistic
    }
    
    // MARK: - Initialization
    
    public init(scenario: DataScenario = .normal) {
        loadScenario(scenario)
    }
    
    public func loadScenario(_ scenario: DataScenario) {
        switch scenario {
        case .empty:
            budgetTemplate = nil
        case .minimal:
            budgetTemplate = BudgetTemplateFactory.minimal
        case .normal:
            budgetTemplate = BudgetTemplateFactory.normal
        case .lowIncome:
            budgetTemplate = BudgetTemplateFactory.lowIncome
        case .middleIncome:
            budgetTemplate = BudgetTemplateFactory.middleIncome
        case .highIncome:
            budgetTemplate = BudgetTemplateFactory.highIncome
        case .realistic:
            budgetTemplate = BudgetTemplateFactory.createRealistic()
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
    
    // MARK: - BudgetTemplateReader Implementation
    
    public func fetchBudgetTemplate() async throws -> BudgetTemplateDTO? {
        try await simulateDelay()
        try checkFailure()
        
        return await withCheckedContinuation { continuation in
            serialQueue.async {
                let result = self.budgetTemplate.map { template in
                    BudgetTemplateDTO(
                        id: template.id,
                        totalAmount: template.totalAmount,
                        categoryBudgetTemplates: [] // Without categories as per interface
                    )
                }
                continuation.resume(returning: result)
            }
        }
    }
    
    public func fetchBudgetTemplateWithCategories() async throws -> BudgetTemplateDTO? {
        try await simulateDelay()
        try checkFailure()
        
        return await withCheckedContinuation { continuation in
            serialQueue.async {
                continuation.resume(returning: self.budgetTemplate)
            }
        }
    }
    
    // MARK: - BudgetTemplateWriter Implementation
    
    @discardableResult
    public func createBudgetTemplate(_ template: BudgetTemplateDTO) async throws -> BudgetTemplateDTO {
        try await simulateDelay()
        try checkFailure()
        
        // Validate category budgets sum doesn't exceed total amount
        let categorySum = template.categoryBudgetTemplates.reduce(0) { $0 + $1.amount }
        if categorySum > template.totalAmount {
            throw MockError.budgetTemplateNotFound // Using closest mock error
        }
        
        return await withCheckedContinuation { continuation in
            serialQueue.async {
                let createdTemplate = BudgetTemplateDTO(
                    id: template.id,
                    totalAmount: template.totalAmount,
                    categoryBudgetTemplates: template.categoryBudgetTemplates
                )
                self.budgetTemplate = createdTemplate
                continuation.resume(returning: createdTemplate)
            }
        }
    }
    
    @discardableResult
    public func updateBudgetTemplate(_ template: BudgetTemplateDTO) async throws -> BudgetTemplateDTO {
        try await simulateDelay()
        try checkFailure()
        
        return try await withCheckedThrowingContinuation { continuation in
            serialQueue.async {
                guard let existingTemplate = self.budgetTemplate else {
                    continuation.resume(throwing: MockError.budgetTemplateNotFound)
                    return
                }
                
                // Validate category budgets sum doesn't exceed total amount
                let categorySum = template.categoryBudgetTemplates.reduce(0) { $0 + $1.amount }
                if categorySum > template.totalAmount {
                    continuation.resume(throwing: MockError.budgetTemplateNotFound) // Using closest mock error
                    return
                }
                
                // 기존 템플릿 ID를 자동으로 사용하고 카테고리 템플릿 ID도 자동 수정
                let correctedCategoryTemplates = template.categoryBudgetTemplates.map { category in
                    CategoryBudgetTemplateDTO(
                        id: category.id,
                        amount: category.amount,
                        categoryID: category.categoryID,
                        categoryName: category.categoryName,
                        budgetTemplateId: existingTemplate.id // 기존 템플릿 ID로 자동 수정
                    )
                }
                
                let updatedTemplate = BudgetTemplateDTO(
                    id: existingTemplate.id, // 기존 템플릿의 ID 유지
                    totalAmount: template.totalAmount,
                    categoryBudgetTemplates: correctedCategoryTemplates
                )
                self.budgetTemplate = updatedTemplate
                continuation.resume(returning: updatedTemplate)
            }
        }
    }
    
    public func updateCategoryBudgetTemplates(_ categoryBudgetTemplates: [CategoryBudgetTemplateDTO]) async throws {
        try await simulateDelay()
        try checkFailure()
        
        return try await withCheckedThrowingContinuation { continuation in
            serialQueue.async {
                guard let existingTemplate = self.budgetTemplate else {
                    continuation.resume(throwing: MockError.budgetTemplateNotFound)
                    return
                }
                
                // Validate category budgets sum doesn't exceed total amount
                let categorySum = categoryBudgetTemplates.reduce(0) { $0 + $1.amount }
                if categorySum > existingTemplate.totalAmount {
                    continuation.resume(throwing: MockError.budgetTemplateNotFound) // Using closest mock error
                    return
                }
                
                let updatedTemplate = BudgetTemplateDTO(
                    id: existingTemplate.id,
                    totalAmount: existingTemplate.totalAmount,
                    categoryBudgetTemplates: categoryBudgetTemplates
                )
                self.budgetTemplate = updatedTemplate
                continuation.resume()
            }
        }
    }
    
    // MARK: - Testing Utilities
    
    /// Clear all data (useful for testing)
    public func clearData() {
        serialQueue.sync {
            budgetTemplate = nil
        }
    }
    
    /// Check if template exists
    public var hasTemplate: Bool {
        return serialQueue.sync {
            budgetTemplate != nil
        }
    }
    
    /// Get current template synchronously (for testing)
    public var currentTemplate: BudgetTemplateDTO? {
        return serialQueue.sync {
            budgetTemplate
        }
    }
}

// MARK: - Convenience Extensions

public extension MockBudgetTemplateRepository {
    
    /// Create with specific template
    convenience init(template: BudgetTemplateDTO) {
        self.init(scenario: .empty)
        self.budgetTemplate = template
    }
    
    /// Set template directly (for testing)
    func setTemplate(_ template: BudgetTemplateDTO?) {
        serialQueue.sync {
            self.budgetTemplate = template
        }
    }
}
