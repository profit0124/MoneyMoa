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
public final class MockCategoryRepository: @unchecked Sendable, CategoryRepository {

    // MARK: - Mock Control Properties

    /// Simulated delay for async operations (seconds)
    public var delay: TimeInterval = 0

    /// Flag to simulate failures
    public var shouldFail = false

    /// Custom error to throw when shouldFail is true
    public var errorToThrow: Error = MockError.simulatedFailure

    // MARK: - Tracking Properties

    /// Tracks if deleteCategory was called
    public var deleteCategoryCalled = false

    /// Tracks the last deleted category ID
    public var lastDeletedCategoryId: UUID?

    /// Tracks if deleteSubCategory was called
    public var deleteSubCategoryCalled = false

    /// Tracks the last deleted subcategory ID
    public var lastDeletedSubCategoryId: UUID?
    
    // MARK: - Data Storage
    
    private var categories: [CategoryDTO] = []
    private var subCategories: [SubCategoryDTO] = []
    
    // MARK: - Thread Safety
    
    private let serialQueue = DispatchQueue(label: "MockCategoryRepository.serialQueue", qos: .utility)
    
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
        
        return await withCheckedContinuation { continuation in
            serialQueue.async {
                let result = self.categories.sorted { $0.orderIndex < $1.orderIndex }
                continuation.resume(returning: result)
            }
        }
    }

    public func fetchCategoriesByType(_ type: TransactionType) async throws -> [CategoryDTO] {
        try await simulateDelay()
        try checkFailure()
        
        return await withCheckedContinuation { continuation in
            serialQueue.async {
                let result = self.categories
                    .filter { $0.transactionType == type && $0.isActive }
                    .map { category in
                        let categorySubCategories = self.subCategories.filter { 
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
                continuation.resume(returning: result)
            }
        }
    }
    
    // MARK: - SubCategory Reader Implementation
    
    public func fetchSubCategories(categoryId: UUID) async throws -> [SubCategoryDTO] {
        try await simulateDelay()
        try checkFailure()
        
        return await withCheckedContinuation { continuation in
            serialQueue.async {
                let result = self.subCategories
                    .filter { $0.categoryId == categoryId && $0.isActive }
                    .sorted { $0.orderIndex < $1.orderIndex }
                continuation.resume(returning: result)
            }
        }
    }
    
    // MARK: - Validation Methods
    
    public func validateCategoryName(_ name: String, type: TransactionType, excludingId: UUID?) async throws -> Bool {
        try await simulateDelay()
        try checkFailure()
        
        return await withCheckedContinuation { continuation in
            serialQueue.async {
                let result = !self.categories.contains { category in
                    category.name == name && 
                    category.transactionType == type &&
                    category.id != excludingId
                }
                continuation.resume(returning: result)
            }
        }
    }
    
    public func validateSubCategoryName(_ name: String, categoryId: UUID, excludingId: UUID?) async throws -> Bool {
        try await simulateDelay()
        try checkFailure()
        
        return await withCheckedContinuation { continuation in
            serialQueue.async {
                let result = !self.subCategories.contains { subCategory in
                    subCategory.name == name &&
                    subCategory.categoryId == categoryId &&
                    subCategory.id != excludingId
                }
                continuation.resume(returning: result)
            }
        }
    }
    
    // MARK: - CategoryWriter Implementation
    
    public func insertCategory(_ category: CategoryDTO) async throws {
        try await simulateDelay()
        try checkFailure()
        
        return await withCheckedContinuation { continuation in
            serialQueue.async {
                self.categories.append(category)
                continuation.resume()
            }
        }
    }
    
    public func updateCategory(_ category: CategoryDTO) async throws {
        try await simulateDelay()
        try checkFailure()
        
        return try await withCheckedThrowingContinuation { continuation in
            serialQueue.async {
                if let index = self.categories.firstIndex(where: { $0.id == category.id }) {
                    self.categories[index] = category
                    continuation.resume()
                } else {
                    continuation.resume(throwing: MockError.categoryNotFound)
                }
            }
        }
    }
    
    // MARK: - SubCategory Writer Implementation
    
    public func insertSubCategory(_ subCategory: SubCategoryDTO) async throws {
        try await simulateDelay()
        try checkFailure()
        
        return try await withCheckedThrowingContinuation { continuation in
            serialQueue.async {
                // Check if parent category exists
                if !self.categories.contains(where: { $0.id == subCategory.categoryId }) {
                    continuation.resume(throwing: MockError.categoryNotFound)
                    return
                }
                
                self.subCategories.append(subCategory)
                continuation.resume()
            }
        }
    }
    
    public func updateSubCategory(_ subCategory: SubCategoryDTO) async throws {
        try await simulateDelay()
        try checkFailure()

        return try await withCheckedThrowingContinuation { continuation in
            serialQueue.async {
                if let index = self.subCategories.firstIndex(where: { $0.id == subCategory.id }) {
                    // Check if new parent category exists
                    if !self.categories.contains(where: { $0.id == subCategory.categoryId }) {
                        continuation.resume(throwing: MockError.categoryNotFound)
                        return
                    }
                    self.subCategories[index] = subCategory
                    continuation.resume()
                } else {
                    continuation.resume(throwing: MockError.subCategoryNotFound)
                }
            }
        }
    }

    // MARK: - Delete Implementation

    public func deleteCategory(_ id: UUID) async throws {
        try await simulateDelay()
        try checkFailure()

        return try await withCheckedThrowingContinuation { continuation in
            serialQueue.async {
                self.deleteCategoryCalled = true
                self.lastDeletedCategoryId = id

                guard self.categories.contains(where: { $0.id == id }) else {
                    continuation.resume(throwing: MockError.categoryNotFound)
                    return
                }

                // Mock은 Transaction이 없다고 가정하고 hard delete 수행
                self.categories.removeAll { $0.id == id }
                self.subCategories.removeAll { $0.categoryId == id }
                continuation.resume()
            }
        }
    }

    public func deleteSubCategory(_ id: UUID) async throws {
        try await simulateDelay()
        try checkFailure()

        return try await withCheckedThrowingContinuation { continuation in
            serialQueue.async {
                self.deleteSubCategoryCalled = true
                self.lastDeletedSubCategoryId = id

                guard self.subCategories.contains(where: { $0.id == id }) else {
                    continuation.resume(throwing: MockError.subCategoryNotFound)
                    return
                }

                // Mock은 Transaction이 없다고 가정하고 hard delete 수행
                self.subCategories.removeAll { $0.id == id }
                continuation.resume()
            }
        }
    }

}
