//
//  MockCategoryRepository.swift
//  MoneyMoa
//
//  Created by Claude Code on 9/3/25.
//

import Foundation

/// Mock Category Repository for Testing and Previews
/// - Provides realistic test data with configurable scenarios  
/// - Supports error simulation and delay testing
/// - Includes both Category and SubCategory operations
public final class MockCategoryRepository: CategoryRepository {
    
    // MARK: - Mock Control Properties
    
    /// Simulated delay for async operations (seconds)
    public var delay: TimeInterval = 0
    
    /// Flag to simulate failures
    public var shouldFail = false
    
    /// Custom error to throw when shouldFail is true
    public var errorToThrow: Error = MockError.simulatedFailure
    
    // MARK: - Data Storage
    
    private var categories: [CategoryDTO] = []
    private var subCategories: [SubCategoryDTO] = []
    
    // MARK: - Scenarios
    
    public enum DataScenario {
        case empty
        case minimal
        case normal
        case realistic
    }
    
    // MARK: - Initialization
    
    public init(scenario: DataScenario = .normal) {
        loadScenario(scenario)
    }
    
    public func loadScenario(_ scenario: DataScenario) {
        switch scenario {
        case .empty:
            let data = CategoryFactory.empty
            categories = data.categories
            subCategories = data.subCategories
        case .minimal:
            let data = CategoryFactory.minimal
            categories = data.categories
            subCategories = data.subCategories
        case .normal:
            let data = CategoryFactory.normal
            categories = data.categories
            subCategories = data.subCategories
        case .realistic:
            let data = CategoryFactory.realistic()
            categories = data.categories
            subCategories = data.subCategories
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
    
    // MARK: - CategoryReader Implementation
    
    public func fetchCategories() async throws -> [CategoryDTO] {
        try await simulateDelay()
        try checkFailure()
        
        return categories.sorted { $0.orderIndex < $1.orderIndex }
    }

    public func fetchCategoriesByType(_ type: TransactionType) async throws -> [CategoryDTO] {
        try await simulateDelay()
        try checkFailure()
        
        return categories
            .filter { $0.transactionType == type && $0.isActive }
            .map { category in
                let categorySubCategories = subCategories.filter { 
                    $0.categoryId == category.id && $0.isActive 
                }
                return CategoryDTO(
                    id: category.id,
                    name: category.name,
                    iconName: category.iconName,
                    transactionType: category.transactionType,
                    isActive: category.isActive,
                    orderIndex: category.orderIndex,
                    subCategories: categorySubCategories
                )
            }
            .sorted { $0.orderIndex < $1.orderIndex }
    }
    
    // MARK: - SubCategory Reader Implementation
    
    public func fetchSubCategories(categoryId: UUID) async throws -> [SubCategoryDTO] {
        try await simulateDelay()
        try checkFailure()
        
        return subCategories
            .filter { $0.categoryId == categoryId && $0.isActive }
            .sorted { $0.orderIndex < $1.orderIndex }
    }
    
    // MARK: - Validation Methods
    
    public func validateCategoryName(_ name: String, type: TransactionType, excludingId: UUID?) async throws -> Bool {
        try await simulateDelay()
        try checkFailure()
        
        return !categories.contains { category in
            category.name == name && 
            category.transactionType == type &&
            category.id != excludingId
        }
    }
    
    public func validateSubCategoryName(_ name: String, categoryId: UUID, excludingId: UUID?) async throws -> Bool {
        try await simulateDelay()
        try checkFailure()
        
        return !subCategories.contains { subCategory in
            subCategory.name == name &&
            subCategory.categoryId == categoryId &&
            subCategory.id != excludingId
        }
    }
    
    // MARK: - CategoryWriter Implementation
    
    public func insertCategory(_ category: CategoryDTO) async throws {
        try await simulateDelay()
        try checkFailure()
        
        categories.append(category)
    }
    
    public func updateCategory(_ category: CategoryDTO) async throws {
        try await simulateDelay()
        try checkFailure()
        
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
        } else {
            throw MockError.categoryNotFound
        }
    }
    
    // MARK: - SubCategory Writer Implementation
    
    public func insertSubCategory(_ subCategory: SubCategoryDTO) async throws {
        try await simulateDelay()
        try checkFailure()
        
        // Check if parent category exists
        if !categories.contains(where: { $0.id == subCategory.categoryId }) {
            throw MockError.categoryNotFound
        }
        
        subCategories.append(subCategory)
    }
    
    public func updateSubCategory(_ subCategory: SubCategoryDTO) async throws {
        try await simulateDelay()
        try checkFailure()
        
        if let index = subCategories.firstIndex(where: { $0.id == subCategory.id }) {
            // Check if new parent category exists
            if !categories.contains(where: { $0.id == subCategory.categoryId }) {
                throw MockError.categoryNotFound
            }
            subCategories[index] = subCategory
        } else {
            throw MockError.subCategoryNotFound
        }
    }
    
}
