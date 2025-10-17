//
//  UpdateSubCategoryUseCaseTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 8/27/25.
//

import XCTest
@testable import MoneyMoa

// MARK: - UpdateSubCategoryUseCaseTests

@MainActor
final class UpdateSubCategoryUseCaseTests: XCTestCase {
    
    // MARK: - Properties
    
    private var useCase: UpdateSubCategoryUseCaseImpl!
    private var mockRepository: MockCategoryRepository!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        
        mockRepository = MockCategoryRepository()
        useCase = UpdateSubCategoryUseCaseImpl(categoryRepository: mockRepository)
    }
    
    override func tearDown() {
        useCase = nil
        mockRepository = nil
        super.tearDown()
    }
    
    // MARK: - Test Methods - Success Cases
    
    func test_execute_withValidSubCategory_updatesSubCategory() async throws {
        // Given
        let subCategory = SubCategoryDTO(
            name: "업데이트된 외식비",
            transactionType: .variableExpense,
            categoryId: UUID(),
            categoryName: "식비",
            categoryIconName: "fork.knife"
        )
        mockRepository.validateSubCategoryNameResult = true
        
        // When
        try await useCase.execute(subCategory)
        
        // Then
        XCTAssertEqual(mockRepository.updateSubCategoryCallCount, 1)
        XCTAssertEqual(mockRepository.lastUpdatedSubCategory?.name, "업데이트된 외식비")
        XCTAssertEqual(mockRepository.lastUpdatedSubCategory?.transactionType, .variableExpense)
        XCTAssertEqual(mockRepository.lastUpdatedSubCategory?.categoryId, subCategory.categoryId)
        
        XCTAssertEqual(mockRepository.validateSubCategoryNameCallCount, 1)
        XCTAssertEqual(mockRepository.lastValidatedName, "업데이트된 외식비")
        XCTAssertEqual(mockRepository.lastValidatedCategoryId, subCategory.categoryId)
        XCTAssertEqual(mockRepository.lastExcludingId, subCategory.id)
    }
    
    func test_execute_withWhitespaceInName_trimsAndUpdates() async throws {
        // Given
        let subCategory = SubCategoryDTO(
            name: "  공백이 있는 서브카테고리  ",
            transactionType: .income,
            categoryId: UUID(),
            categoryName: "수입",
            categoryIconName: "plus.circle.fill"
        )
        mockRepository.validateSubCategoryNameResult = true
        
        // When
        try await useCase.execute(subCategory)
        
        // Then
        XCTAssertEqual(mockRepository.updateSubCategoryCallCount, 1)
        XCTAssertEqual(mockRepository.lastValidatedName, "공백이 있는 서브카테고리")
    }
    
    func test_execute_withDifferentTransactionTypes_callsCorrectValidation() async throws {
        // Test Income
        let incomeSubCategory = SubCategoryDTO(
            name: "보너스수정",
            transactionType: .income,
            categoryId: UUID(),
            categoryName: "수입",
            categoryIconName: "banknote"
        )
        mockRepository.validateSubCategoryNameResult = true
        
        try await useCase.execute(incomeSubCategory)
        
        XCTAssertEqual(mockRepository.lastUpdatedSubCategory?.transactionType, .income)
        
        // Test Fixed Expense
        mockRepository.reset()
        let fixedExpenseSubCategory = SubCategoryDTO(
            name: "관리비수정",
            transactionType: .fixedExpense,
            categoryId: UUID(),
            categoryName: "주거비",
            categoryIconName: "house.fill"
        )
        mockRepository.validateSubCategoryNameResult = true
        
        try await useCase.execute(fixedExpenseSubCategory)
        
        XCTAssertEqual(mockRepository.lastUpdatedSubCategory?.transactionType, .fixedExpense)
    }
    
    // MARK: - Test Methods - Validation Error Cases
    
    func test_execute_withEmptyName_throwsEmptyNameError() async {
        // Given
        let subCategory = SubCategoryDTO(
            name: "",
            transactionType: .variableExpense,
            categoryId: UUID(),
            categoryName: "식비",
            categoryIconName: "fork.knife"
        )
        
        // When & Then
        do {
            try await useCase.execute(subCategory)
            XCTFail("Expected SubCategoryUpdateError.emptyName")
        } catch let error as SubCategoryUpdateError {
            XCTAssertEqual(error, .emptyName)
            XCTAssertEqual(mockRepository.updateSubCategoryCallCount, 0)
            XCTAssertEqual(mockRepository.validateSubCategoryNameCallCount, 0)
        } catch {
            XCTFail("Expected SubCategoryUpdateError.emptyName but got \(error)")
        }
    }
    
    func test_execute_withWhitespaceOnlyName_throwsEmptyNameError() async {
        // Given
        let subCategory = SubCategoryDTO(
            name: "   \n\t   ",
            transactionType: .variableExpense,
            categoryId: UUID(),
            categoryName: "식비",
            categoryIconName: "fork.knife"
        )
        
        // When & Then
        do {
            try await useCase.execute(subCategory)
            XCTFail("Expected SubCategoryUpdateError.emptyName")
        } catch let error as SubCategoryUpdateError {
            XCTAssertEqual(error, .emptyName)
            XCTAssertEqual(mockRepository.updateSubCategoryCallCount, 0)
        } catch {
            XCTFail("Expected SubCategoryUpdateError.emptyName but got \(error)")
        }
    }
    
    func test_execute_withDuplicateName_throwsDuplicateNameError() async {
        // Given
        let subCategory = SubCategoryDTO(
            name: "중복된 서브카테고리",
            transactionType: .variableExpense,
            categoryId: UUID(),
            categoryName: "식비",
            categoryIconName: "fork.knife"
        )
        mockRepository.validateSubCategoryNameResult = false // 중복 이름
        
        // When & Then
        do {
            try await useCase.execute(subCategory)
            XCTFail("Expected SubCategoryUpdateError.duplicateName")
        } catch let error as SubCategoryUpdateError {
            XCTAssertEqual(error, .duplicateName)
            XCTAssertEqual(mockRepository.validateSubCategoryNameCallCount, 1)
            XCTAssertEqual(mockRepository.updateSubCategoryCallCount, 0)
        } catch {
            XCTFail("Expected SubCategoryUpdateError.duplicateName but got \(error)")
        }
    }
    
    // MARK: - Test Methods - Repository Error Cases
    
    func test_execute_whenRepositoryValidationThrows_propagatesError() async {
        // Given
        let subCategory = SubCategoryDTO(
            name: "유효한 서브카테고리",
            transactionType: .variableExpense,
            categoryId: UUID(),
            categoryName: "식비",
            categoryIconName: "fork.knife"
        )
        mockRepository.validateSubCategoryNameError = NSError(domain: "TestError", code: 500)
        
        // When & Then
        do {
            try await useCase.execute(subCategory)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).domain, "TestError")
            XCTAssertEqual((error as NSError).code, 500)
            XCTAssertEqual(mockRepository.updateSubCategoryCallCount, 0)
        }
    }
    
    func test_execute_whenRepositoryUpdateThrows_propagatesError() async {
        // Given
        let subCategory = SubCategoryDTO(
            name: "유효한 서브카테고리",
            transactionType: .variableExpense,
            categoryId: UUID(),
            categoryName: "식비",
            categoryIconName: "fork.knife"
        )
        mockRepository.validateSubCategoryNameResult = true
        mockRepository.updateSubCategoryError = NSError(domain: "UpdateError", code: 400)
        
        // When & Then
        do {
            try await useCase.execute(subCategory)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).domain, "UpdateError")
            XCTAssertEqual((error as NSError).code, 400)
            XCTAssertEqual(mockRepository.updateSubCategoryCallCount, 1)
        }
    }
    
    // MARK: - Test Methods - Error Descriptions
    
    func test_subCategoryUpdateError_errorDescriptions() {
        XCTAssertEqual(SubCategoryUpdateError.emptyName.errorDescription, "서브카테고리명을 입력해주세요.")
        XCTAssertEqual(SubCategoryUpdateError.duplicateName.errorDescription, "같은 카테고리에 이미 존재하는 서브카테고리명입니다.")
        XCTAssertEqual(SubCategoryUpdateError.subCategoryNotFound.errorDescription, "수정할 서브카테고리를 찾을 수 없습니다.")
        XCTAssertEqual(SubCategoryUpdateError.categoryNotFound.errorDescription, "상위 카테고리를 찾을 수 없습니다.")
        XCTAssertEqual(SubCategoryUpdateError.invalidData.errorDescription, "유효하지 않은 데이터입니다.")
    }
    
    // MARK: - Test Methods - Data Integrity
    
    func test_execute_preservesOriginalSubCategoryProperties() async throws {
        // Given
        let originalId = UUID()
        let categoryId = UUID()
        let subCategory = SubCategoryDTO(
            id: originalId,
            name: "수정된 서브카테고리",
            transactionType: .fixedExpense,
            isActive: false,
            orderIndex: 3,
            categoryId: categoryId,
            categoryName: "주거비",
            categoryIconName: "house.fill"
        )
        mockRepository.validateSubCategoryNameResult = true
        
        // When
        try await useCase.execute(subCategory)
        
        // Then
        let updatedSubCategory = mockRepository.lastUpdatedSubCategory
        XCTAssertEqual(updatedSubCategory?.id, originalId)
        XCTAssertEqual(updatedSubCategory?.name, "수정된 서브카테고리")
        XCTAssertEqual(updatedSubCategory?.transactionType, .fixedExpense)
        XCTAssertEqual(updatedSubCategory?.isActive, false)
        XCTAssertEqual(updatedSubCategory?.orderIndex, 3)
        XCTAssertEqual(updatedSubCategory?.categoryId, categoryId)
        XCTAssertEqual(updatedSubCategory?.categoryName, "주거비")
        XCTAssertEqual(updatedSubCategory?.categoryIconName, "house.fill")
    }
    
    // MARK: - Test Methods - Category Relationship
    
    func test_execute_withDifferentCategoryIds_callsCorrectValidation() async throws {
        // Given
        let categoryId1 = UUID()
        let categoryId2 = UUID()
        
        let subCategory1 = SubCategoryDTO(
            name: "서브카테고리1",
            transactionType: .variableExpense,
            categoryId: categoryId1,
            categoryName: "카테고리1",
            categoryIconName: "icon1"
        )
        
        mockRepository.validateSubCategoryNameResult = true
        try await useCase.execute(subCategory1)
        
        XCTAssertEqual(mockRepository.lastValidatedCategoryId, categoryId1)
        
        // Reset and test with different category
        mockRepository.reset()
        let subCategory2 = SubCategoryDTO(
            name: "서브카테고리2",
            transactionType: .income,
            categoryId: categoryId2,
            categoryName: "카테고리2",
            categoryIconName: "icon2"
        )
        
        mockRepository.validateSubCategoryNameResult = true
        try await useCase.execute(subCategory2)
        
        XCTAssertEqual(mockRepository.lastValidatedCategoryId, categoryId2)
    }
}

// MARK: - Mock CategoryRepository

private class MockCategoryRepository: CategoryRepository {

    var updateSubCategoryCallCount = 0
    var validateSubCategoryNameCallCount = 0
    
    var lastUpdatedSubCategory: SubCategoryDTO?
    var lastValidatedName: String?
    var lastValidatedCategoryId: UUID?
    var lastExcludingId: UUID?
    
    var updateSubCategoryError: Error?
    var validateSubCategoryNameError: Error?
    var validateSubCategoryNameResult: Bool = true
    
    func reset() {
        updateSubCategoryCallCount = 0
        validateSubCategoryNameCallCount = 0
        lastUpdatedSubCategory = nil
        lastValidatedName = nil
        lastValidatedCategoryId = nil
        lastExcludingId = nil
        updateSubCategoryError = nil
        validateSubCategoryNameError = nil
        validateSubCategoryNameResult = true
    }
    
    func updateSubCategory(_ subCategory: SubCategoryDTO) async throws {
        updateSubCategoryCallCount += 1
        lastUpdatedSubCategory = subCategory
        
        if let error = updateSubCategoryError {
            throw error
        }
    }
    
    func validateSubCategoryName(_ name: String, categoryId: UUID, excludingId: UUID?) async throws -> Bool {
        validateSubCategoryNameCallCount += 1
        lastValidatedName = name
        lastValidatedCategoryId = categoryId
        lastExcludingId = excludingId
        
        if let error = validateSubCategoryNameError {
            throw error
        }
        
        return validateSubCategoryNameResult
    }
    
    // MARK: - Unused CategoryRepository methods (required by protocol)
    func fetchCategories() async throws -> [CategoryDTO] { [] }
    func fetchCategoriesByType(_ type: TransactionType) async throws -> [CategoryDTO] { [] }
    func validateCategoryName(_ name: String, type: TransactionType, excludingId: UUID?) async throws -> Bool { true }
    func fetchSubCategories(categoryId: UUID) async throws -> [SubCategoryDTO] { [] }
    func insertCategory(_ category: CategoryDTO) async throws {}
    func updateCategory(_ category: CategoryDTO) async throws {}
    func insertSubCategory(_ subCategory: SubCategoryDTO) async throws {}
    func deleteCategory(_ id: UUID) async throws { }
    func deleteSubCategory(_ id: UUID) async throws { }
}
