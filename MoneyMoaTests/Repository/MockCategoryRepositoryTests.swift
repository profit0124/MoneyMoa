//
//  MockCategoryRepositoryTests.swift
//  MoneyMoaTests
//
//  Created by Claude Code on 9/3/25.
//

import XCTest
@testable import MoneyMoa

final class MockCategoryRepositoryTests: XCTestCase {
    
    private var mockRepository: MockCategoryRepository!
    
    override func setUpWithError() throws {
        mockRepository = MockCategoryRepository(scenario: .normal)
    }
    
    override func tearDownWithError() throws {
        mockRepository = nil
    }
    
    // MARK: - Scenario Loading Tests
    
    func testLoadEmptyScenario() async throws {
        // Given: Empty scenario
        mockRepository.loadScenario(.empty)
        
        // When: Fetch categories
        let categories = try await mockRepository.fetchCategories()
        
        // Then: Returns empty array
        XCTAssertTrue(categories.isEmpty)
    }
    
    func testLoadMinimalScenario() async throws {
        // Given: Minimal scenario
        mockRepository.loadScenario(.minimal)
        
        // When: Fetch categories
        let categories = try await mockRepository.fetchCategories()
        
        // Then: Returns minimal data set
        XCTAssertFalse(categories.isEmpty)
        XCTAssertLessThanOrEqual(categories.count, 3) // Minimal should have few categories
    }
    
    func testLoadNormalScenario() async throws {
        // Given: Normal scenario (default)
        mockRepository.loadScenario(.normal)
        
        // When: Fetch categories
        let categories = try await mockRepository.fetchCategories()
        
        // Then: Returns normal data set
        XCTAssertFalse(categories.isEmpty)
        XCTAssertGreaterThan(categories.count, 3)
    }
    
    func testLoadRealisticScenario() async throws {
        // Given: Realistic scenario
        mockRepository.loadScenario(.realistic)
        
        // When: Fetch categories
        let categories = try await mockRepository.fetchCategories()
        
        // Then: Returns realistic data set
        XCTAssertFalse(categories.isEmpty)
        // Realistic scenario should provide comprehensive data
    }
    
    // MARK: - Error Simulation Tests
    
    func testFailureSimulation() async throws {
        // Given: Mock configured to fail
        mockRepository.shouldFail = true
        mockRepository.errorToThrow = MockError.simulatedFailure
        
        // When: Attempt to fetch categories
        // Then: Should throw the configured error
        do {
            _ = try await mockRepository.fetchCategories()
            XCTFail("Should have thrown an error")
        } catch let error as MockError {
            XCTAssertEqual(error, MockError.simulatedFailure)
        }
    }
    
    func testCustomErrorThrow() async throws {
        // Given: Mock configured with custom error
        struct CustomError: Error, Equatable {}
        mockRepository.shouldFail = true
        mockRepository.errorToThrow = CustomError()
        
        // When: Attempt to fetch categories
        // Then: Should throw the custom error
        do {
            _ = try await mockRepository.fetchCategories()
            XCTFail("Should have thrown custom error")
        } catch is CustomError {
            // Expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Delay Simulation Tests
    
    func testDelaySimulation() async throws {
        // Given: Mock configured with delay
        let delayDuration: TimeInterval = 0.1
        mockRepository.delay = delayDuration
        
        // When: Measure execution time
        let startTime = Date()
        _ = try await mockRepository.fetchCategories()
        let executionTime = Date().timeIntervalSince(startTime)
        
        // Then: Should take at least the configured delay
        XCTAssertGreaterThanOrEqual(executionTime, delayDuration)
    }
    
    // MARK: - CategoryReader Implementation Tests
    
    func testFetchCategoriesByType() async throws {
        // Given: Mock with normal scenario
        mockRepository.loadScenario(.normal)
        
        // When: Fetch categories by type
        let incomeCategories = try await mockRepository.fetchCategoriesByType(.income)
        let expenseCategories = try await mockRepository.fetchCategoriesByType(.variableExpense)
        
        // Then: Returns filtered categories
        XCTAssertTrue(incomeCategories.allSatisfy { $0.transactionType == .income })
        XCTAssertTrue(expenseCategories.allSatisfy { $0.transactionType == .variableExpense })
        
        // Categories should include subcategories
        if let categoryWithSubs = incomeCategories.first(where: { !$0.subCategories.isEmpty }) {
            XCTAssertFalse(categoryWithSubs.subCategories.isEmpty)
        }
    }
    
    func testFetchSubCategories() async throws {
        // Given: Mock with data containing subcategories
        mockRepository.loadScenario(.realistic)
        let categories = try await mockRepository.fetchCategoriesByType(.variableExpense)
        
        guard let categoryWithSubs = categories.first(where: { !$0.subCategories.isEmpty }) else {
            XCTFail("Realistic scenario should include categories with subcategories")
            return
        }
        
        // When: Fetch subcategories for specific category
        let subCategories = try await mockRepository.fetchSubCategories(categoryId: categoryWithSubs.id)
        
        // Then: Returns subcategories for that category
        XCTAssertFalse(subCategories.isEmpty)
        XCTAssertTrue(subCategories.allSatisfy { $0.categoryId == categoryWithSubs.id })
        XCTAssertTrue(subCategories.allSatisfy { $0.isActive })
    }
    
    // MARK: - Validation Tests
    
    func testValidateCategoryName() async throws {
        // Given: Mock with existing categories
        mockRepository.loadScenario(.normal)
        let existingCategories = try await mockRepository.fetchCategories()
        
        guard let existingCategory = existingCategories.first else {
            XCTFail("Normal scenario should have categories")
            return
        }
        
        // When: Validate existing name
        let isDuplicate = try await mockRepository.validateCategoryName(
            existingCategory.name,
            type: existingCategory.transactionType,
            excludingId: nil
        )
        
        // Then: Should return false (name is taken)
        XCTAssertFalse(isDuplicate)
        
        // When: Validate new unique name
        let isUnique = try await mockRepository.validateCategoryName(
            "Unique Category Name",
            type: existingCategory.transactionType,
            excludingId: nil
        )
        
        // Then: Should return true (name is available)
        XCTAssertTrue(isUnique)
    }
    
    func testValidateSubCategoryName() async throws {
        // Given: Mock with subcategories
        mockRepository.loadScenario(.realistic)
        let categories = try await mockRepository.fetchCategoriesByType(.variableExpense)
        
        guard let categoryWithSubs = categories.first(where: { !$0.subCategories.isEmpty }),
              let existingSubCategory = categoryWithSubs.subCategories.first else {
            XCTFail("Should have category with subcategories")
            return
        }
        
        // When: Validate existing subcategory name
        let isDuplicate = try await mockRepository.validateSubCategoryName(
            existingSubCategory.name,
            categoryId: categoryWithSubs.id,
            excludingId: nil
        )
        
        // Then: Should return false (name is taken)
        XCTAssertFalse(isDuplicate)
        
        // When: Validate unique subcategory name
        let isUnique = try await mockRepository.validateSubCategoryName(
            "Unique SubCategory Name",
            categoryId: categoryWithSubs.id,
            excludingId: nil
        )
        
        // Then: Should return true (name is available)
        XCTAssertTrue(isUnique)
    }
    
    // MARK: - CategoryWriter Implementation Tests
    
    func testInsertCategory() async throws {
        // Given: Mock with empty scenario
        mockRepository.loadScenario(.empty)
        let initialCount = try await mockRepository.fetchCategories().count
        
        let newCategory = CategoryDTO(
            id: UUID(),
            name: "New Category",
            iconName: "plus.circle.fill",
            transactionType: .variableExpense,
            isActive: true,
            orderIndex: 1,
            subCategories: []
        )
        
        // When: Insert category
        try await mockRepository.insertCategory(newCategory)
        
        // Then: Category is added
        let categories = try await mockRepository.fetchCategories()
        XCTAssertEqual(categories.count, initialCount + 1)
        XCTAssertTrue(categories.contains { $0.id == newCategory.id })
    }
    
    func testUpdateCategory() async throws {
        // Given: Mock with existing categories
        mockRepository.loadScenario(.normal)
        let categories = try await mockRepository.fetchCategories()
        
        guard let existingCategory = categories.first else {
            XCTFail("Normal scenario should have categories")
            return
        }
        
        let updatedCategory = CategoryDTO(
            id: existingCategory.id,
            name: "Updated Name",
            iconName: existingCategory.iconName,
            transactionType: existingCategory.transactionType,
            isActive: existingCategory.isActive,
            orderIndex: 99,
            subCategories: existingCategory.subCategories
        )
        
        // When: Update category
        try await mockRepository.updateCategory(updatedCategory)
        
        // Then: Category is updated
        let updatedCategories = try await mockRepository.fetchCategories()
        let found = updatedCategories.first { $0.id == existingCategory.id }
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.name, "Updated Name")
        XCTAssertEqual(found?.orderIndex, 99)
    }
    
    func testUpdateNonExistentCategory() async throws {
        // Given: Mock with categories
        mockRepository.loadScenario(.normal)
        
        let nonExistentCategory = CategoryDTO(
            id: UUID(), // Random UUID that doesn't exist
            name: "Non-existent",
            iconName: "questionmark.circle.fill",
            transactionType: .income,
            isActive: true,
            orderIndex: 0,
            subCategories: []
        )
        
        // When: Attempt to update non-existent category
        // Then: Should throw categoryNotFound error
        do {
            try await mockRepository.updateCategory(nonExistentCategory)
            XCTFail("Should have thrown categoryNotFound error")
        } catch MockError.categoryNotFound {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testInsertSubCategory() async throws {
        // Given: Mock with categories
        mockRepository.loadScenario(.normal)
        let categories = try await mockRepository.fetchCategories()
        
        guard let parentCategory = categories.first else {
            XCTFail("Normal scenario should have categories")
            return
        }
        
        let initialSubCount = try await mockRepository.fetchSubCategories(categoryId: parentCategory.id).count
        
        let newSubCategory = SubCategoryDTO(
            id: UUID(),
            name: "New SubCategory",
            transactionType: parentCategory.transactionType,
            isActive: true,
            orderIndex: 1,
            categoryId: parentCategory.id,
            categoryName: parentCategory.name,
            categoryIconName: parentCategory.iconName
        )
        
        // When: Insert subcategory
        try await mockRepository.insertSubCategory(newSubCategory)
        
        // Then: Subcategory is added
        let subCategories = try await mockRepository.fetchSubCategories(categoryId: parentCategory.id)
        XCTAssertEqual(subCategories.count, initialSubCount + 1)
        XCTAssertTrue(subCategories.contains { $0.id == newSubCategory.id })
    }
    
    func testInsertSubCategoryWithInvalidParent() async throws {
        // Given: Mock with categories
        mockRepository.loadScenario(.normal)
        
        let invalidSubCategory = SubCategoryDTO(
            id: UUID(),
            name: "Invalid SubCategory",
            transactionType: .income,
            isActive: true,
            orderIndex: 0,
            categoryId: UUID(), // Non-existent parent
            categoryName: "Invalid",
            categoryIconName: "questionmark.circle.fill"
        )
        
        // When: Attempt to insert subcategory with invalid parent
        // Then: Should throw categoryNotFound error
        do {
            try await mockRepository.insertSubCategory(invalidSubCategory)
            XCTFail("Should have thrown categoryNotFound error")
        } catch MockError.categoryNotFound {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testUpdateSubCategory() async throws {
        // Given: Mock with subcategories
        mockRepository.loadScenario(.realistic)
        let categories = try await mockRepository.fetchCategoriesByType(.variableExpense)
        
        guard let categoryWithSubs = categories.first(where: { !$0.subCategories.isEmpty }),
              let existingSubCategory = categoryWithSubs.subCategories.first else {
            XCTFail("Should have category with subcategories")
            return
        }
        
        let updatedSubCategory = SubCategoryDTO(
            id: existingSubCategory.id,
            name: "Updated SubCategory Name",
            transactionType: existingSubCategory.transactionType,
            isActive: existingSubCategory.isActive,
            orderIndex: 99,
            categoryId: existingSubCategory.categoryId,
            categoryName: existingSubCategory.categoryName,
            categoryIconName: existingSubCategory.categoryIconName
        )
        
        // When: Update subcategory
        try await mockRepository.updateSubCategory(updatedSubCategory)
        
        // Then: Subcategory is updated
        let subCategories = try await mockRepository.fetchSubCategories(categoryId: categoryWithSubs.id)
        let found = subCategories.first { $0.id == existingSubCategory.id }
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.name, "Updated SubCategory Name")
        XCTAssertEqual(found?.orderIndex, 99)
    }
    
    func testUpdateNonExistentSubCategory() async throws {
        // Given: Mock with categories
        mockRepository.loadScenario(.normal)
        let categories = try await mockRepository.fetchCategories()
        
        guard let parentCategory = categories.first else {
            XCTFail("Normal scenario should have categories")
            return
        }
        
        let nonExistentSubCategory = SubCategoryDTO(
            id: UUID(), // Random UUID that doesn't exist
            name: "Non-existent Sub",
            transactionType: parentCategory.transactionType,
            isActive: true,
            orderIndex: 0,
            categoryId: parentCategory.id,
            categoryName: parentCategory.name,
            categoryIconName: parentCategory.iconName
        )
        
        // When: Attempt to update non-existent subcategory
        // Then: Should throw subCategoryNotFound error
        do {
            try await mockRepository.updateSubCategory(nonExistentSubCategory)
            XCTFail("Should have thrown subCategoryNotFound error")
        } catch MockError.subCategoryNotFound {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Integration Tests
    
    func testCompleteWorkflow() async throws {
        // Given: Empty mock repository
        mockRepository.loadScenario(.empty)
        
        // When: Create complete category structure
        let categoryId = UUID()
        let category = CategoryDTO(
            id: categoryId,
            name: "Test Category",
            iconName: "star.fill",
            transactionType: .variableExpense,
            isActive: true,
            orderIndex: 0,
            subCategories: []
        )
        
        try await mockRepository.insertCategory(category)
        
        let subCategoryId = UUID()
        let subCategory = SubCategoryDTO(
            id: subCategoryId,
            name: "Test SubCategory",
            transactionType: .variableExpense,
            isActive: true,
            orderIndex: 0,
            categoryId: categoryId,
            categoryName: "Test Category",
            categoryIconName: "star.fill"
        )
        
        try await mockRepository.insertSubCategory(subCategory)
        
        // Then: Verify complete structure
        let categoriesByType = try await mockRepository.fetchCategoriesByType(.variableExpense)
        XCTAssertEqual(categoriesByType.count, 1)
        XCTAssertEqual(categoriesByType[0].subCategories.count, 1)
        
        let subCategories = try await mockRepository.fetchSubCategories(categoryId: categoryId)
        XCTAssertEqual(subCategories.count, 1)
        XCTAssertEqual(subCategories[0].name, "Test SubCategory")
    }
}
