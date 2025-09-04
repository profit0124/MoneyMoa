//
//  GetCategoriesByTypeUseCaseTests.swift
//  MoneyMoaTests
//
//  Created by Claude Code on 9/3/25.
//

import XCTest
@testable import MoneyMoa

final class GetCategoriesByTypeUseCaseTests: XCTestCase {
    
    private var mockRepository: MockCategoryRepository!
    private var useCase: GetCategoriesByTypeUseCaseImpl!
    
    override func setUpWithError() throws {
        mockRepository = MockCategoryRepository(scenario: .realistic)
        useCase = GetCategoriesByTypeUseCaseImpl(categoryRepository: mockRepository)
    }
    
    override func tearDownWithError() throws {
        mockRepository = nil
        useCase = nil
    }
    
    // MARK: - Success Cases
    
    func testExecuteWithIncomeType() async throws {
        // Given: Mock repository with realistic data
        // Repository is already set up with realistic scenario
        
        // When: Execute use case for income type
        let categories = try await useCase.execute(.income)
        
        // Then: Returns only income categories with subcategories
        XCTAssertFalse(categories.isEmpty)
        XCTAssertTrue(categories.allSatisfy { $0.transactionType == .income })
        XCTAssertTrue(categories.allSatisfy { $0.isActive })
        
        // Categories should be sorted by orderIndex
        let orderIndices = categories.map { $0.orderIndex }
        let sortedOrderIndices = orderIndices.sorted()
        XCTAssertEqual(orderIndices, sortedOrderIndices)
        
        // Should include subcategories if available
        let totalSubCategories = categories.flatMap { $0.subCategories }.count
        print("Income categories: \(categories.count), total subcategories: \(totalSubCategories)")
    }
    
    func testExecuteWithVariableExpenseType() async throws {
        // Given: Mock repository with realistic data
        // Repository is already set up with realistic scenario
        
        // When: Execute use case for variable expense type
        let categories = try await useCase.execute(.variableExpense)
        
        // Then: Returns only variable expense categories with subcategories
        XCTAssertFalse(categories.isEmpty)
        XCTAssertTrue(categories.allSatisfy { $0.transactionType == .variableExpense })
        XCTAssertTrue(categories.allSatisfy { $0.isActive })
        
        // Should include subcategories
        let categoriesWithSubs = categories.filter { !$0.subCategories.isEmpty }
        print("Variable expense categories: \(categories.count), with subcategories: \(categoriesWithSubs.count)")
    }
    
    func testExecuteWithFixedExpenseType() async throws {
        // Given: Mock repository with realistic data
        // Repository is already set up with realistic scenario
        
        // When: Execute use case for fixed expense type
        let categories = try await useCase.execute(.fixedExpense)
        
        // Then: Returns only fixed expense categories
        XCTAssertTrue(categories.allSatisfy { $0.transactionType == .fixedExpense })
        XCTAssertTrue(categories.allSatisfy { $0.isActive })
        
        print("Fixed expense categories: \(categories.count)")
    }
    
    func testExecuteWithEmptyResult() async throws {
        // Given: Mock repository with empty scenario
        mockRepository.loadScenario(.empty)
        
        // When: Execute use case for any type
        let categories = try await useCase.execute(.income)
        
        // Then: Returns empty array
        XCTAssertTrue(categories.isEmpty)
    }
    
    func testExecuteReturnsOnlyActiveCategories() async throws {
        // Given: Mock repository with normal data
        mockRepository.loadScenario(.normal)
        
        // When: Execute use case
        let categories = try await useCase.execute(.variableExpense)
        
        // Then: All returned categories should be active
        XCTAssertTrue(categories.allSatisfy { $0.isActive })
        
        // All subcategories should also be active
        let allSubCategories = categories.flatMap { $0.subCategories }
        XCTAssertTrue(allSubCategories.allSatisfy { $0.isActive })
    }
    
    // MARK: - Error Cases
    
    func testExecuteWithRepositoryFailure() async throws {
        // Given: Mock repository configured to fail
        mockRepository.shouldFail = true
        mockRepository.errorToThrow = MockError.simulatedFailure
        
        // When: Execute use case
        // Then: Should propagate repository error
        do {
            _ = try await useCase.execute(.income)
            XCTFail("Should have thrown an error")
        } catch let error as MockError {
            XCTAssertEqual(error, MockError.simulatedFailure)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testExecuteWithCustomRepositoryError() async throws {
        // Given: Mock repository with custom error
        struct NetworkError: Error, Equatable {}
        mockRepository.shouldFail = true
        mockRepository.errorToThrow = NetworkError()
        
        // When: Execute use case
        // Then: Should propagate custom error
        do {
            _ = try await useCase.execute(.variableExpense)
            XCTFail("Should have thrown custom error")
        } catch is NetworkError {
            // Expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Data Consistency Tests
    
    func testExecuteConsistentDataAcrossMultipleCalls() async throws {
        // Given: Mock repository with normal data
        mockRepository.loadScenario(.normal)
        
        // When: Execute use case multiple times
        let categories1 = try await useCase.execute(.income)
        let categories2 = try await useCase.execute(.income)
        
        // Then: Should return consistent data
        XCTAssertEqual(categories1.count, categories2.count)
        
        for (cat1, cat2) in zip(categories1, categories2) {
            XCTAssertEqual(cat1.id, cat2.id)
            XCTAssertEqual(cat1.name, cat2.name)
            XCTAssertEqual(cat1.transactionType, cat2.transactionType)
            XCTAssertEqual(cat1.subCategories.count, cat2.subCategories.count)
        }
    }
    
    func testExecuteSubCategoryConsistency() async throws {
        // Given: Mock repository with realistic data
        mockRepository.loadScenario(.realistic)
        
        // When: Execute use case
        let categories = try await useCase.execute(.variableExpense)
        
        // Then: Subcategories should have consistent parent relationship
        for category in categories {
            for subCategory in category.subCategories {
                XCTAssertEqual(subCategory.categoryId, category.id)
                XCTAssertEqual(subCategory.categoryName, category.name)
                XCTAssertEqual(subCategory.categoryIconName, category.iconName)
                XCTAssertEqual(subCategory.transactionType, category.transactionType)
            }
        }
    }
    
    // MARK: - Performance Tests
    
    func testExecutePerformanceWithRealisticData() async throws {
        // Given: Mock repository with realistic data
        mockRepository.loadScenario(.realistic)
        
        // When: Measure execution time
        let startTime = Date()
        _ = try await useCase.execute(.variableExpense)
        let executionTime = Date().timeIntervalSince(startTime)
        
        // Then: Should execute quickly (under 1 second for realistic data)
        XCTAssertLessThan(executionTime, 1.0, "Use case execution should be fast")
    }
    
    func testExecutePerformanceWithSimulatedDelay() async throws {
        // Given: Mock repository with simulated network delay
        mockRepository.loadScenario(.normal)
        mockRepository.delay = 0.1 // 100ms delay
        
        // When: Measure execution time
        let startTime = Date()
        _ = try await useCase.execute(.income)
        let executionTime = Date().timeIntervalSince(startTime)
        
        // Then: Should take at least the simulated delay
        XCTAssertGreaterThanOrEqual(executionTime, 0.1)
        XCTAssertLessThan(executionTime, 0.2) // But not too much longer
    }
    
    // MARK: - Integration Tests
    
    func testExecuteWithAllTransactionTypes() async throws {
        // Given: Mock repository with comprehensive data
        mockRepository.loadScenario(.realistic)
        
        // When: Execute for all transaction types
        let incomeCategories = try await useCase.execute(.income)
        let fixedExpenseCategories = try await useCase.execute(.fixedExpense)
        let variableExpenseCategories = try await useCase.execute(.variableExpense)
        
        // Then: Should get distinct categories for each type
        let allCategories = incomeCategories + fixedExpenseCategories + variableExpenseCategories
        let uniqueCategoryIds = Set(allCategories.map { $0.id })
        
        // No category should appear in multiple transaction types
        XCTAssertEqual(allCategories.count, uniqueCategoryIds.count)
        
        // Each group should only contain its transaction type
        XCTAssertTrue(incomeCategories.allSatisfy { $0.transactionType == .income })
        XCTAssertTrue(fixedExpenseCategories.allSatisfy { $0.transactionType == .fixedExpense })
        XCTAssertTrue(variableExpenseCategories.allSatisfy { $0.transactionType == .variableExpense })
        
        print("Categories by type - Income: \(incomeCategories.count), Fixed: \(fixedExpenseCategories.count), Variable: \(variableExpenseCategories.count)")
    }
    
    func testExecuteDataStructureIntegrity() async throws {
        // Given: Mock repository with realistic data
        mockRepository.loadScenario(.realistic)
        
        // When: Execute use case
        let categories = try await useCase.execute(.variableExpense)
        
        // Then: Verify complete data structure integrity
        for category in categories {
            // Basic category properties
            XCTAssertFalse(category.id.uuidString.isEmpty)
            XCTAssertFalse(category.name.isEmpty)
            XCTAssertFalse(category.iconName.isEmpty)
            XCTAssertTrue(category.isActive)
            XCTAssertGreaterThanOrEqual(category.orderIndex, 0)
            
            // Subcategory integrity
            for subCategory in category.subCategories {
                XCTAssertFalse(subCategory.id.uuidString.isEmpty)
                XCTAssertFalse(subCategory.name.isEmpty)
                XCTAssertTrue(subCategory.isActive)
                XCTAssertGreaterThanOrEqual(subCategory.orderIndex, 0)
                XCTAssertEqual(subCategory.categoryId, category.id)
                XCTAssertEqual(subCategory.transactionType, category.transactionType)
            }
        }
    }
}
