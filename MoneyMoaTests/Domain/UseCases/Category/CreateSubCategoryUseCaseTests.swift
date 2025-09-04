//
//  CreateSubCategoryUseCaseTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 9/3/25.
//

import XCTest
@testable import MoneyMoa

// MARK: - CreateSubCategoryUseCaseTests

@MainActor
final class CreateSubCategoryUseCaseTests: XCTestCase {
    
    // MARK: - Properties
    
    private var useCase: CreateSubCategoryUseCaseImpl!
    private var mockRepository: MockCategoryRepository!
    private var parentCategory: CategoryDTO!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        
        mockRepository = MockCategoryRepository(scenario: .empty)
        useCase = CreateSubCategoryUseCaseImpl(categoryRepository: mockRepository)
        
        // Set up parent category
        parentCategory = CategoryDTO(
            name: "식비",
            iconName: "fork.knife",
            transactionType: .variableExpense,
            subCategories: []
        )
    }
    
    override func tearDown() {
        useCase = nil
        mockRepository = nil
        parentCategory = nil
        super.tearDown()
    }
    
    // MARK: - Test Methods - Success Cases
    
    func test_execute_withValidSubCategory_createsSuccessfully() async throws {
        // Given
        try await mockRepository.insertCategory(parentCategory)
        
        let subCategory = SubCategoryDTO(
            name: "외식",
            transactionType: .variableExpense,
            categoryId: parentCategory.id,
            categoryName: "식비",
            categoryIconName: "fork.knife"
        )
        
        // When
        try await useCase.execute(subCategory)
        
        // Then
        let subCategories = try await mockRepository.fetchSubCategories(categoryId: parentCategory.id)
        XCTAssertEqual(subCategories.count, 1)
        XCTAssertEqual(subCategories.first?.name, "외식")
        XCTAssertEqual(subCategories.first?.categoryId, parentCategory.id)
        XCTAssertEqual(subCategories.first?.categoryName, "식비")
        XCTAssertEqual(subCategories.first?.transactionType, .variableExpense)
    }
    
    func test_execute_withWhitespaceInName_trimsAndCreates() async throws {
        // Given
        try await mockRepository.insertCategory(parentCategory)
        
        let subCategory = SubCategoryDTO(
            name: "  장보기  ",
            transactionType: .variableExpense,
            categoryId: parentCategory.id,
            categoryName: "식비",
            categoryIconName: "fork.knife"
        )
        
        // When
        try await useCase.execute(subCategory)
        
        // Then
        let subCategories = try await mockRepository.fetchSubCategories(categoryId: parentCategory.id)
        XCTAssertEqual(subCategories.count, 1)
        XCTAssertEqual(subCategories.first?.name, "  장보기  ") // Repository stores as-is
    }
    
    func test_execute_withMultipleDifferentSubCategories_createsAll() async throws {
        // Given
        try await mockRepository.insertCategory(parentCategory)
        
        let subCategories = [
            SubCategoryDTO(
                name: "외식",
                transactionType: .variableExpense,
                categoryId: parentCategory.id,
                categoryName: "식비",
                categoryIconName: "fork.knife"
            ),
            SubCategoryDTO(
                name: "장보기",
                transactionType: .variableExpense,
                categoryId: parentCategory.id,
                categoryName: "식비",
                categoryIconName: "fork.knife"
            ),
            SubCategoryDTO(
                name: "카페",
                transactionType: .variableExpense,
                categoryId: parentCategory.id,
                categoryName: "식비",
                categoryIconName: "fork.knife"
            )
        ]
        
        // When
        for subCategory in subCategories {
            try await useCase.execute(subCategory)
        }
        
        // Then
        let fetchedSubCategories = try await mockRepository.fetchSubCategories(categoryId: parentCategory.id)
        XCTAssertEqual(fetchedSubCategories.count, 3)
        XCTAssertTrue(fetchedSubCategories.contains { $0.name == "외식" })
        XCTAssertTrue(fetchedSubCategories.contains { $0.name == "장보기" })
        XCTAssertTrue(fetchedSubCategories.contains { $0.name == "카페" })
    }
    
    // MARK: - Test Methods - Validation Error Cases
    
    func test_execute_withEmptySubCategoryName_throwsEmptyNameError() async throws {
        // Given
        try await mockRepository.insertCategory(parentCategory)
        
        let subCategory = SubCategoryDTO(
            name: "",
            transactionType: .variableExpense,
            categoryId: parentCategory.id,
            categoryName: "식비",
            categoryIconName: "fork.knife"
        )
        
        // When/Then
        do {
            try await useCase.execute(subCategory)
            XCTFail("Expected error but succeeded")
        } catch let error as SubCategoryCreationError {
            XCTAssertEqual(error, SubCategoryCreationError.emptyName)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func test_execute_withOnlyWhitespaceSubCategoryName_throwsEmptyNameError() async throws {
        // Given
        try await mockRepository.insertCategory(parentCategory)
        
        let subCategory = SubCategoryDTO(
            name: "   ",
            transactionType: .variableExpense,
            categoryId: parentCategory.id,
            categoryName: "식비",
            categoryIconName: "fork.knife"
        )
        
        // When/Then
        do {
            try await useCase.execute(subCategory)
            XCTFail("Expected error but succeeded")
        } catch let error as SubCategoryCreationError {
            XCTAssertEqual(error, SubCategoryCreationError.emptyName)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func test_execute_withDuplicateSubCategoryName_throwsDuplicateNameError() async throws {
        // Given
        try await mockRepository.insertCategory(parentCategory)
        
        let existingSubCategory = SubCategoryDTO(
            name: "외식",
            transactionType: .variableExpense,
            categoryId: parentCategory.id,
            categoryName: "식비",
            categoryIconName: "fork.knife"
        )
        
        // Create existing subcategory
        try await mockRepository.insertSubCategory(existingSubCategory)
        
        // Try to create duplicate
        let duplicateSubCategory = SubCategoryDTO(
            name: "외식",
            transactionType: .variableExpense,
            categoryId: parentCategory.id,
            categoryName: "식비",
            categoryIconName: "fork.knife"
        )
        
        // When/Then
        do {
            try await useCase.execute(duplicateSubCategory)
            XCTFail("Expected error but succeeded")
        } catch let error as SubCategoryCreationError {
            XCTAssertEqual(error, SubCategoryCreationError.duplicateName)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func test_execute_withSameNameInDifferentCategories_createsSuccessfully() async throws {
        // Given
        let secondParentCategory = CategoryDTO(
            name: "교통비",
            iconName: "car",
            transactionType: .variableExpense,
            subCategories: []
        )
        
        try await mockRepository.insertCategory(parentCategory)
        try await mockRepository.insertCategory(secondParentCategory)
        
        // Create subcategory in first category
        let subCategory1 = SubCategoryDTO(
            name: "외식",
            transactionType: .variableExpense,
            categoryId: parentCategory.id,
            categoryName: "식비",
            categoryIconName: "fork.knife"
        )
        
        // Create subcategory with same name in second category
        let subCategory2 = SubCategoryDTO(
            name: "외식", // Same name but different parent
            transactionType: .variableExpense,
            categoryId: secondParentCategory.id,
            categoryName: "교통비",
            categoryIconName: "car"
        )
        
        // When
        try await useCase.execute(subCategory1)
        try await useCase.execute(subCategory2)
        
        // Then
        let subCategories1 = try await mockRepository.fetchSubCategories(categoryId: parentCategory.id)
        let subCategories2 = try await mockRepository.fetchSubCategories(categoryId: secondParentCategory.id)
        
        XCTAssertEqual(subCategories1.count, 1)
        XCTAssertEqual(subCategories2.count, 1)
        XCTAssertEqual(subCategories1.first?.name, "외식")
        XCTAssertEqual(subCategories2.first?.name, "외식")
        XCTAssertEqual(subCategories1.first?.categoryId, parentCategory.id)
        XCTAssertEqual(subCategories2.first?.categoryId, secondParentCategory.id)
    }
    
    // MARK: - Test Methods - Parent Category Validation
    
    func test_execute_withNonExistentParentCategory_throwsCategoryNotFoundError() async throws {
        // Given
        let nonExistentCategoryId = UUID()
        let subCategory = SubCategoryDTO(
            name: "외식",
            transactionType: .variableExpense,
            categoryId: nonExistentCategoryId,
            categoryName: "존재하지않는카테고리",
            categoryIconName: "question"
        )
        
        // When/Then
        do {
            try await useCase.execute(subCategory)
            XCTFail("Expected error but succeeded")
        } catch let error as MockError {
            XCTAssertEqual(error, MockError.categoryNotFound)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Test Methods - Repository Error Handling
    
    func test_execute_withRepositoryError_propagatesError() async throws {
        // Given
        try await mockRepository.insertCategory(parentCategory)
        
        // Configure repository to fail
        mockRepository.shouldFail = true
        mockRepository.errorToThrow = MockError.networkTimeout
        
        let subCategory = SubCategoryDTO(
            name: "외식",
            transactionType: .variableExpense,
            categoryId: parentCategory.id,
            categoryName: "식비",
            categoryIconName: "fork.knife"
        )
        
        // When/Then
        do {
            try await useCase.execute(subCategory)
            XCTFail("Expected error but succeeded")
        } catch let error as MockError {
            XCTAssertEqual(error, MockError.networkTimeout)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Test Methods - Transaction Type Consistency
    
    func test_execute_withDifferentTransactionTypes_createsSuccessfully() async throws {
        // Given
        let incomeCategory = CategoryDTO(
            name: "급여",
            iconName: "banknote",
            transactionType: .income,
            subCategories: []
        )
        
        let fixedExpenseCategory = CategoryDTO(
            name: "주거비",
            iconName: "house",
            transactionType: .fixedExpense,
            subCategories: []
        )
        
        try await mockRepository.insertCategory(incomeCategory)
        try await mockRepository.insertCategory(fixedExpenseCategory)
        
        let incomeSubCategory = SubCategoryDTO(
            name: "월급",
            transactionType: .income,
            categoryId: incomeCategory.id,
            categoryName: "급여",
            categoryIconName: "banknote"
        )
        
        let fixedExpenseSubCategory = SubCategoryDTO(
            name: "월세",
            transactionType: .fixedExpense,
            categoryId: fixedExpenseCategory.id,
            categoryName: "주거비",
            categoryIconName: "house"
        )
        
        // When
        try await useCase.execute(incomeSubCategory)
        try await useCase.execute(fixedExpenseSubCategory)
        
        // Then
        let incomeSubCategories = try await mockRepository.fetchSubCategories(categoryId: incomeCategory.id)
        let fixedExpenseSubCategories = try await mockRepository.fetchSubCategories(categoryId: fixedExpenseCategory.id)
        
        XCTAssertEqual(incomeSubCategories.count, 1)
        XCTAssertEqual(fixedExpenseSubCategories.count, 1)
        XCTAssertEqual(incomeSubCategories.first?.transactionType, .income)
        XCTAssertEqual(fixedExpenseSubCategories.first?.transactionType, .fixedExpense)
    }
    
    // MARK: - Test Methods - Concurrent Operations
    
    func test_execute_withConcurrentCreation_handlesCorrectly() async throws {
        // Given
        try await mockRepository.insertCategory(parentCategory)
        
        let subCategories = [
            SubCategoryDTO(
                name: "외식",
                transactionType: .variableExpense,
                categoryId: parentCategory.id,
                categoryName: "식비",
                categoryIconName: "fork.knife"
            ),
            SubCategoryDTO(
                name: "장보기",
                transactionType: .variableExpense,
                categoryId: parentCategory.id,
                categoryName: "식비",
                categoryIconName: "fork.knife"
            ),
            SubCategoryDTO(
                name: "카페",
                transactionType: .variableExpense,
                categoryId: parentCategory.id,
                categoryName: "식비",
                categoryIconName: "fork.knife"
            )
        ]
        
        // When - Create concurrently
        await withThrowingTaskGroup(of: Void.self) { group in
            for subCategory in subCategories {
                group.addTask {
                    try await self.useCase.execute(subCategory)
                }
            }
        }
        
        // Then
        let fetchedSubCategories = try await mockRepository.fetchSubCategories(categoryId: parentCategory.id)
        XCTAssertEqual(fetchedSubCategories.count, 3)
        XCTAssertTrue(fetchedSubCategories.contains { $0.name == "외식" })
        XCTAssertTrue(fetchedSubCategories.contains { $0.name == "장보기" })
        XCTAssertTrue(fetchedSubCategories.contains { $0.name == "카페" })
    }
}
