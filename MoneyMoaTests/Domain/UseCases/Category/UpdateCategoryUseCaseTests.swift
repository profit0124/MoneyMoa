//
//  UpdateCategoryUseCaseTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 8/27/25.
//

import XCTest
@testable import MoneyMoa

// MARK: - UpdateCategoryUseCaseTests

@MainActor
final class UpdateCategoryUseCaseTests: XCTestCase {
    
    // MARK: - Properties
    
    private var useCase: UpdateCategoryUseCaseImpl!
    private var mockRepository: MockCategoryRepository!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        
        mockRepository = MockCategoryRepository()
        useCase = UpdateCategoryUseCaseImpl(categoryRepository: mockRepository)
    }
    
    override func tearDown() {
        useCase = nil
        mockRepository = nil
        super.tearDown()
    }
    
    // MARK: - Test Methods - Success Cases
    
    func test_execute_withValidCategory_updatesCategory() async throws {
        // Given
        let category = CategoryDTO(
            name: "업데이트된 식비",
            iconName: "fork.knife",
            transactionType: .variableExpense
        )
        mockRepository.validateCategoryNameResult = true
        
        // When
        try await useCase.execute(category)
        
        // Then
        XCTAssertEqual(mockRepository.updateCategoryCallCount, 1)
        XCTAssertEqual(mockRepository.lastUpdatedCategory?.name, "업데이트된 식비")
        XCTAssertEqual(mockRepository.lastUpdatedCategory?.iconName, "fork.knife")
        XCTAssertEqual(mockRepository.lastUpdatedCategory?.transactionType, .variableExpense)
        
        XCTAssertEqual(mockRepository.validateCategoryNameCallCount, 1)
        XCTAssertEqual(mockRepository.lastValidatedName, "업데이트된 식비")
        XCTAssertEqual(mockRepository.lastValidatedType, .variableExpense)
        XCTAssertEqual(mockRepository.lastExcludingId, category.id)
    }
    
    func test_execute_withWhitespaceInName_trimsAndUpdates() async throws {
        // Given
        let category = CategoryDTO(
            name: "  공백이 있는 이름  ",
            iconName: "house.fill",
            transactionType: .fixedExpense
        )
        mockRepository.validateCategoryNameResult = true
        
        // When
        try await useCase.execute(category)
        
        // Then
        XCTAssertEqual(mockRepository.updateCategoryCallCount, 1)
        XCTAssertEqual(mockRepository.lastUpdatedCategory?.name, "공백이 있는 이름")
        XCTAssertEqual(mockRepository.lastValidatedName, "공백이 있는 이름")
    }
    
    func test_execute_withDifferentTransactionTypes_callsCorrectValidation() async throws {
        // Test Income
        let incomeCategory = CategoryDTO(
            name: "급여수정",
            iconName: "banknote",
            transactionType: .income
        )
        mockRepository.validateCategoryNameResult = true
        
        try await useCase.execute(incomeCategory)
        
        XCTAssertEqual(mockRepository.lastValidatedType, .income)
        
        // Test Fixed Expense
        mockRepository.reset()
        let fixedExpenseCategory = CategoryDTO(
            name: "월세수정",
            iconName: "house.fill",
            transactionType: .fixedExpense
        )
        mockRepository.validateCategoryNameResult = true
        
        try await useCase.execute(fixedExpenseCategory)
        
        XCTAssertEqual(mockRepository.lastValidatedType, .fixedExpense)
    }
    
    // MARK: - Test Methods - Validation Error Cases
    
    func test_execute_withEmptyName_throwsEmptyNameError() async {
        // Given
        let category = CategoryDTO(
            name: "",
            iconName: "fork.knife",
            transactionType: .variableExpense
        )
        
        // When & Then
        do {
            try await useCase.execute(category)
            XCTFail("Expected CategoryUpdateError.emptyName")
        } catch let error as CategoryUpdateError {
            XCTAssertEqual(error, .emptyName)
            XCTAssertEqual(mockRepository.updateCategoryCallCount, 0)
            XCTAssertEqual(mockRepository.validateCategoryNameCallCount, 0)
        } catch {
            XCTFail("Expected CategoryUpdateError.emptyName but got \(error)")
        }
    }
    
    func test_execute_withWhitespaceOnlyName_throwsEmptyNameError() async {
        // Given
        let category = CategoryDTO(
            name: "   \n\t   ",
            iconName: "fork.knife",
            transactionType: .variableExpense
        )
        
        // When & Then
        do {
            try await useCase.execute(category)
            XCTFail("Expected CategoryUpdateError.emptyName")
        } catch let error as CategoryUpdateError {
            XCTAssertEqual(error, .emptyName)
            XCTAssertEqual(mockRepository.updateCategoryCallCount, 0)
        } catch {
            XCTFail("Expected CategoryUpdateError.emptyName but got \(error)")
        }
    }
    
    func test_execute_withEmptyIconName_throwsEmptyIconNameError() async {
        // Given
        let category = CategoryDTO(
            name: "유효한 이름",
            iconName: "",
            transactionType: .variableExpense
        )
        
        // When & Then
        do {
            try await useCase.execute(category)
            XCTFail("Expected CategoryUpdateError.emptyIconName")
        } catch let error as CategoryUpdateError {
            XCTAssertEqual(error, .emptyIconName)
            XCTAssertEqual(mockRepository.updateCategoryCallCount, 0)
            XCTAssertEqual(mockRepository.validateCategoryNameCallCount, 0)
        } catch {
            XCTFail("Expected CategoryUpdateError.emptyIconName but got \(error)")
        }
    }
    
    func test_execute_withDuplicateName_throwsDuplicateNameError() async {
        // Given
        let category = CategoryDTO(
            name: "중복된 이름",
            iconName: "fork.knife",
            transactionType: .variableExpense
        )
        mockRepository.validateCategoryNameResult = false // 중복 이름
        
        // When & Then
        do {
            try await useCase.execute(category)
            XCTFail("Expected CategoryUpdateError.duplicateName")
        } catch let error as CategoryUpdateError {
            XCTAssertEqual(error, .duplicateName)
            XCTAssertEqual(mockRepository.validateCategoryNameCallCount, 1)
            XCTAssertEqual(mockRepository.updateCategoryCallCount, 0)
        } catch {
            XCTFail("Expected CategoryUpdateError.duplicateName but got \(error)")
        }
    }
    
    // MARK: - Test Methods - Repository Error Cases
    
    func test_execute_whenRepositoryValidationThrows_propagatesError() async {
        // Given
        let category = CategoryDTO(
            name: "유효한 이름",
            iconName: "fork.knife",
            transactionType: .variableExpense
        )
        mockRepository.validateCategoryNameError = NSError(domain: "TestError", code: 500)
        
        // When & Then
        do {
            try await useCase.execute(category)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).domain, "TestError")
            XCTAssertEqual((error as NSError).code, 500)
            XCTAssertEqual(mockRepository.updateCategoryCallCount, 0)
        }
    }
    
    func test_execute_whenRepositoryUpdateThrows_propagatesError() async {
        // Given
        let category = CategoryDTO(
            name: "유효한 이름",
            iconName: "fork.knife",
            transactionType: .variableExpense
        )
        mockRepository.validateCategoryNameResult = true
        mockRepository.updateCategoryError = NSError(domain: "UpdateError", code: 400)
        
        // When & Then
        do {
            try await useCase.execute(category)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).domain, "UpdateError")
            XCTAssertEqual((error as NSError).code, 400)
            XCTAssertEqual(mockRepository.updateCategoryCallCount, 1)
        }
    }
    
    // MARK: - Test Methods - Error Descriptions
    
    func test_categoryUpdateError_errorDescriptions() {
        XCTAssertEqual(CategoryUpdateError.emptyName.errorDescription, "카테고리명을 입력해주세요.")
        XCTAssertEqual(CategoryUpdateError.emptyIconName.errorDescription, "아이콘을 선택해주세요.")
        XCTAssertEqual(CategoryUpdateError.duplicateName.errorDescription, "같은 거래 유형에 이미 존재하는 카테고리명입니다.")
        XCTAssertEqual(CategoryUpdateError.categoryNotFound.errorDescription, "수정할 카테고리를 찾을 수 없습니다.")
        XCTAssertEqual(CategoryUpdateError.invalidData.errorDescription, "유효하지 않은 데이터입니다.")
    }
    
    // MARK: - Test Methods - Data Integrity
    
    func test_execute_preservesOriginalCategoryProperties() async throws {
        // Given
        let originalId = UUID()
        let category = CategoryDTO(
            id: originalId,
            name: "수정된 이름",
            iconName: "new.icon",
            transactionType: .income,
            isActive: false,
            orderIndex: 5,
            subCategories: [SubCategoryDTO.mockSalary]
        )
        mockRepository.validateCategoryNameResult = true
        
        // When
        try await useCase.execute(category)
        
        // Then
        let updatedCategory = mockRepository.lastUpdatedCategory
        XCTAssertEqual(updatedCategory?.id, originalId)
        XCTAssertEqual(updatedCategory?.name, "수정된 이름")
        XCTAssertEqual(updatedCategory?.iconName, "new.icon")
        XCTAssertEqual(updatedCategory?.transactionType, .income)
        XCTAssertEqual(updatedCategory?.isActive, false)
        XCTAssertEqual(updatedCategory?.orderIndex, 5)
        XCTAssertEqual(updatedCategory?.subCategories.count, 1)
        XCTAssertEqual(updatedCategory?.subCategories.first?.id, SubCategoryDTO.mockSalary.id)
    }
}

// MARK: - Mock CategoryRepository

private class MockCategoryRepository: CategoryRepository {

    var updateCategoryCallCount = 0
    var validateCategoryNameCallCount = 0
    
    var lastUpdatedCategory: CategoryDTO?
    var lastValidatedName: String?
    var lastValidatedType: TransactionType?
    var lastExcludingId: UUID?
    
    var updateCategoryError: Error?
    var validateCategoryNameError: Error?
    var validateCategoryNameResult: Bool = true
    
    func reset() {
        updateCategoryCallCount = 0
        validateCategoryNameCallCount = 0
        lastUpdatedCategory = nil
        lastValidatedName = nil
        lastValidatedType = nil
        lastExcludingId = nil
        updateCategoryError = nil
        validateCategoryNameError = nil
        validateCategoryNameResult = true
    }
    
    func updateCategory(_ category: CategoryDTO) async throws {
        updateCategoryCallCount += 1
        lastUpdatedCategory = category
        
        if let error = updateCategoryError {
            throw error
        }
    }
    
    func validateCategoryName(_ name: String, type: TransactionType, excludingId: UUID?) async throws -> Bool {
        validateCategoryNameCallCount += 1
        lastValidatedName = name
        lastValidatedType = type
        lastExcludingId = excludingId
        
        if let error = validateCategoryNameError {
            throw error
        }
        
        return validateCategoryNameResult
    }
    
    // MARK: - Unused CategoryRepository methods (required by protocol)
    func fetchCategories() async throws -> [CategoryDTO] { [] }
    func fetchCategory(id: UUID) async throws -> CategoryDTO? { nil }
    func fetchCategoryWithSubCategories(id: UUID) async throws -> CategoryDTO? { nil }
    func fetchActiveCategories() async throws -> [CategoryDTO] { [] }
    func fetchCategoriesByType(_ type: TransactionType) async throws -> [CategoryDTO] { [] }
    func insertCategory(_ category: CategoryDTO) async throws {}
    func deactivateCategory(id: UUID) async throws {}
    func activateCategory(id: UUID) async throws {}
    func hasTransactions(categoryId: UUID) async throws -> Bool { true }
    func createCategory(_ category: CategoryDTO) async throws { }
    func getCategories(by type: TransactionType) async throws -> [CategoryDTO] { return [] }
    func deleteCategory(id: UUID) async throws { }
    func createSubCategory(_ subCategory: SubCategoryDTO) async throws { }
    func updateSubCategory(_ subCategory: SubCategoryDTO) async throws { }
    func deleteSubCategory(_ subCategoryId: UUID) async throws { }
    func importRecommendedCategories() async throws { }
}
