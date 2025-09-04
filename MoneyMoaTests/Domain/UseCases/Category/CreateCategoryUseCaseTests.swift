//
//  CreateCategoryUseCaseTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 9/3/25.
//

import XCTest
@testable import MoneyMoa

// MARK: - CreateCategoryUseCaseTests

@MainActor
final class CreateCategoryUseCaseTests: XCTestCase {
    
    // MARK: - Properties
    
    private var useCase: CreateCategoryUseCaseImpl!
    private var mockRepository: MockCategoryRepository!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        
        mockRepository = MockCategoryRepository(scenario: .empty)
        useCase = CreateCategoryUseCaseImpl(categoryRepository: mockRepository)
    }
    
    override func tearDown() {
        useCase = nil
        mockRepository = nil
        super.tearDown()
    }
    
    // MARK: - Test Methods - Success Cases
    
    func test_execute_withValidCategoryNoSubCategories_createsSuccessfully() async throws {
        // Given
        let category = CategoryDTO(
            name: "식비",
            iconName: "fork.knife",
            transactionType: .variableExpense,
            subCategories: []
        )
        
        // When
        try await useCase.execute(category)
        
        // Then
        let categories = try await mockRepository.fetchCategories()
        XCTAssertEqual(categories.count, 1)
        XCTAssertEqual(categories.first?.name, "식비")
        XCTAssertEqual(categories.first?.iconName, "fork.knife")
        XCTAssertEqual(categories.first?.transactionType, .variableExpense)
    }
    
    func test_execute_withValidCategoryAndSubCategories_createsAllSuccessfully() async throws {
        // Given
        let categoryId = UUID()
        let subCategories = [
            SubCategoryDTO(
                name: "외식",
                transactionType: .variableExpense,
                categoryId: categoryId,
                categoryName: "식비",
                categoryIconName: "fork.knife"
            ),
            SubCategoryDTO(
                name: "장보기",
                transactionType: .variableExpense,
                categoryId: categoryId,
                categoryName: "식비",
                categoryIconName: "fork.knife"
            )
        ]
        
        let category = CategoryDTO(
            id: categoryId,
            name: "식비",
            iconName: "fork.knife",
            transactionType: .variableExpense,
            subCategories: subCategories
        )
        
        // When
        try await useCase.execute(category)
        
        // Then
        let categories = try await mockRepository.fetchCategories()
        XCTAssertEqual(categories.count, 1)
        XCTAssertEqual(categories.first?.name, "식비")
        
        let fetchedSubCategories = try await mockRepository.fetchSubCategories(categoryId: categoryId)
        XCTAssertEqual(fetchedSubCategories.count, 2)
        XCTAssertTrue(fetchedSubCategories.contains { $0.name == "외식" })
        XCTAssertTrue(fetchedSubCategories.contains { $0.name == "장보기" })
    }
    
    func test_execute_withWhitespaceInName_trimsAndCreates() async throws {
        // Given
        let category = CategoryDTO(
            name: "  교통비  ",
            iconName: "car",
            transactionType: .variableExpense,
            subCategories: []
        )
        
        // When
        try await useCase.execute(category)
        
        // Then
        let categories = try await mockRepository.fetchCategories()
        XCTAssertEqual(categories.count, 1)
        XCTAssertEqual(categories.first?.name, "  교통비  ") // Repository stores as-is
    }
    
    // MARK: - Test Methods - Validation Error Cases
    
    func test_execute_withEmptyCategoryName_throwsEmptyNameError() async throws {
        // Given
        let category = CategoryDTO(
            name: "",
            iconName: "folder",
            transactionType: .income,
            subCategories: []
        )
        
        // When/Then
        do {
            try await useCase.execute(category)
            XCTFail("Expected error but succeeded")
        } catch let error as CategoryCreationError {
            XCTAssertEqual(error, CategoryCreationError.emptyName)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func test_execute_withOnlyWhitespaceCategoryName_throwsEmptyNameError() async throws {
        // Given
        let category = CategoryDTO(
            name: "   ",
            iconName: "folder",
            transactionType: .income,
            subCategories: []
        )
        
        // When/Then
        do {
            try await useCase.execute(category)
            XCTFail("Expected error but succeeded")
        } catch let error as CategoryCreationError {
            XCTAssertEqual(error, CategoryCreationError.emptyName)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func test_execute_withDuplicateCategoryName_throwsDuplicateNameError() async throws {
        // Given
        let existingCategory = CategoryDTO(
            name: "식비",
            iconName: "fork.knife",
            transactionType: .variableExpense,
            subCategories: []
        )
        
        // Create existing category
        try await mockRepository.insertCategory(existingCategory)
        
        // Try to create duplicate
        let duplicateCategory = CategoryDTO(
            name: "식비",
            iconName: "utensils",
            transactionType: .variableExpense,
            subCategories: []
        )
        
        // When/Then
        do {
            try await useCase.execute(duplicateCategory)
            XCTFail("Expected error but succeeded")
        } catch let error as CategoryCreationError {
            XCTAssertEqual(error, CategoryCreationError.duplicateName)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func test_execute_withSameNameDifferentType_createsSuccessfully() async throws {
        // Given
        let existingCategory = CategoryDTO(
            name: "교육",
            iconName: "book",
            transactionType: .variableExpense,
            subCategories: []
        )
        
        // Create existing category
        try await mockRepository.insertCategory(existingCategory)
        
        // Create same name but different type
        let newCategory = CategoryDTO(
            name: "교육",
            iconName: "graduation.cap",
            transactionType: .fixedExpense,
            subCategories: []
        )
        
        // When
        try await useCase.execute(newCategory)
        
        // Then
        let categories = try await mockRepository.fetchCategories()
        XCTAssertEqual(categories.count, 2)
        XCTAssertTrue(categories.contains { $0.name == "교육" && $0.transactionType == .variableExpense })
        XCTAssertTrue(categories.contains { $0.name == "교육" && $0.transactionType == .fixedExpense })
    }
    
    func test_execute_withEmptySubCategoryName_throwsEmptySubCategoryNameError() async throws {
        // Given
        let categoryId = UUID()
        let subCategories = [
            SubCategoryDTO(
                name: "",
                transactionType: .variableExpense,
                categoryId: categoryId,
                categoryName: "식비",
                categoryIconName: "fork.knife"
            )
        ]
        
        let category = CategoryDTO(
            id: categoryId,
            name: "식비",
            iconName: "fork.knife",
            transactionType: .variableExpense,
            subCategories: subCategories
        )
        
        // When/Then
        do {
            try await useCase.execute(category)
            XCTFail("Expected error but succeeded")
        } catch let error as CategoryCreationError {
            XCTAssertEqual(error, CategoryCreationError.emptySubCategoryName)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func test_execute_withDuplicateSubCategoryName_throwsDuplicateSubCategoryNameError() async throws {
        // Given
        let categoryId = UUID()
        let subCategories = [
            SubCategoryDTO(
                name: "외식",
                transactionType: .variableExpense,
                categoryId: categoryId,
                categoryName: "식비",
                categoryIconName: "fork.knife"
            ),
            SubCategoryDTO(
                name: "외식", // Duplicate name
                transactionType: .variableExpense,
                categoryId: categoryId,
                categoryName: "식비",
                categoryIconName: "fork.knife"
            )
        ]
        
        let category = CategoryDTO(
            id: categoryId,
            name: "식비",
            iconName: "fork.knife",
            transactionType: .variableExpense,
            subCategories: subCategories
        )
        
        // When/Then
        do {
            try await useCase.execute(category)
            XCTFail("Expected error but succeeded")
        } catch let error as CategoryCreationError {
            XCTAssertEqual(error, CategoryCreationError.duplicateSubCategoryName)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Test Methods - Repository Error Handling
    
    func test_execute_withRepositoryError_propagatesError() async throws {
        // Given
        mockRepository.shouldFail = true
        mockRepository.errorToThrow = MockError.networkTimeout
        
        let category = CategoryDTO(
            name: "식비",
            iconName: "fork.knife",
            transactionType: .variableExpense,
            subCategories: []
        )
        
        // When/Then
        do {
            try await useCase.execute(category)
            XCTFail("Expected error but succeeded")
        } catch let error as MockError {
            XCTAssertEqual(error, MockError.networkTimeout)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Test Methods - Concurrent Operations
    
    func test_execute_withConcurrentCreation_handlesCorrectly() async throws {
        // Given
        let categories = [
            CategoryDTO(
                name: "식비",
                iconName: "fork.knife",
                transactionType: .variableExpense,
                subCategories: []
            ),
            CategoryDTO(
                name: "교통비",
                iconName: "car",
                transactionType: .variableExpense,
                subCategories: []
            ),
            CategoryDTO(
                name: "쇼핑",
                iconName: "bag",
                transactionType: .variableExpense,
                subCategories: []
            )
        ]
        
        // When - Create concurrently
        await withThrowingTaskGroup(of: Void.self) { group in
            for category in categories {
                group.addTask {
                    try await self.useCase.execute(category)
                }
            }
        }
        
        // Then
        let fetchedCategories = try await mockRepository.fetchCategories()
        XCTAssertEqual(fetchedCategories.count, 3)
        XCTAssertTrue(fetchedCategories.contains { $0.name == "식비" })
        XCTAssertTrue(fetchedCategories.contains { $0.name == "교통비" })
        XCTAssertTrue(fetchedCategories.contains { $0.name == "쇼핑" })
    }
    
    func test_execute_withConcurrentDuplicateCreation_oneSucceedsOtherFails() async throws {
        // Given
        let category1 = CategoryDTO(
            name: "식비",
            iconName: "fork.knife",
            transactionType: .variableExpense,
            subCategories: []
        )
        
        let category2 = CategoryDTO(
            name: "식비", // Same name and type
            iconName: "utensils",
            transactionType: .variableExpense,
            subCategories: []
        )
        
        // When - Try to create both concurrently
        var successCount = 0
        var failureCount = 0
        
        await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                do {
                    try await self.useCase.execute(category1)
                    return true
                } catch {
                    return false
                }
            }
            
            group.addTask {
                do {
                    // Small delay to increase chance of conflict
                    try await Task.sleep(for: .milliseconds(10))
                    try await self.useCase.execute(category2)
                    return true
                } catch {
                    return false
                }
            }
            
            for await result in group {
                if result {
                    successCount += 1
                } else {
                    failureCount += 1
                }
            }
        }
        
        // Then - One should succeed, one should fail
        XCTAssertEqual(successCount, 1, "One creation should succeed")
        XCTAssertEqual(failureCount, 1, "One creation should fail due to duplicate")
        
        let categories = try await mockRepository.fetchCategories()
        XCTAssertEqual(categories.count, 1)
        XCTAssertEqual(categories.first?.name, "식비")
    }
}
