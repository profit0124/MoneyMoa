//
//  CreateTemplateFromBudgetUseCaseTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 8/22/25.
//

import XCTest
@testable import MoneyMoa

final class CreateTemplateFromBudgetUseCaseTests: XCTestCase {
    
    private var sut: CreateTemplateFromBudgetUseCaseImpl!
    private var mockRepository: MockBudgetRepository!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockBudgetRepository()
        sut = CreateTemplateFromBudgetUseCaseImpl(budgetRepository: mockRepository)
    }
    
    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    func test_execute_shouldConvertBudgetDTOToBudgetTemplateDTO() async throws {
        // Given
        let budget = makeBudgetDTOWithCategories()
        mockRepository.createBudgetTemplateResult = makeBudgetTemplateDTO()
        
        // When
        try await sut.execute(budget)
        
        // Then
        XCTAssertEqual(mockRepository.createBudgetTemplateCallCount, 1)
        
        guard let passedTemplate = mockRepository.lastCreateBudgetTemplateInput else {
            XCTFail("Repository createBudgetTemplate should have been called with template parameter")
            return
        }
        
        // BudgetDTO가 BudgetTemplateDTO로 올바르게 변환되었는지 확인
        XCTAssertEqual(passedTemplate.totalAmount, budget.totalAmount)
        XCTAssertEqual(passedTemplate.categoryBudgetTemplates.count, budget.categoryBudgets.count)
        
        // 카테고리 변환 검증
        for (index, originalCategory) in budget.categoryBudgets.enumerated() {
            let convertedCategory = passedTemplate.categoryBudgetTemplates[index]
            XCTAssertEqual(convertedCategory.amount, originalCategory.amount)
            XCTAssertEqual(convertedCategory.categoryID, originalCategory.categoryID)
            XCTAssertEqual(convertedCategory.categoryName, originalCategory.categoryName)
        }
    }
    
    func test_execute_shouldCallRepositoryCreateBudgetTemplate() async throws {
        // Given
        let budget = makeBudgetDTO()
        mockRepository.createBudgetTemplateResult = makeBudgetTemplateDTO()
        
        // When
        try await sut.execute(budget)
        
        // Then
        XCTAssertEqual(mockRepository.createBudgetTemplateCallCount, 1)
        XCTAssertNotNil(mockRepository.lastCreateBudgetTemplateInput)
    }
    
    func test_execute_whenRepositoryThrowsError_shouldPropagateError() async throws {
        // Given
        let budget = makeBudgetDTO()
        let expectedError = RepositoryError.budgetTemplateNotFound
        mockRepository.shouldThrowError = expectedError
        
        // When & Then
        do {
            try await sut.execute(budget)
            XCTFail("Expected error to be thrown")
        } catch let error as RepositoryError {
            switch error {
            case .budgetTemplateNotFound:
                XCTAssertTrue(true) // 예상된 에러
            default:
                XCTFail("Expected budgetTemplateNotFound error, but got \(error)")
            }
        } catch {
            XCTFail("Expected RepositoryError, but got \(type(of: error)): \(error)")
        }
        
        // Repository 호출 확인
        XCTAssertEqual(mockRepository.createBudgetTemplateCallCount, 1)
    }
    
    func test_execute_withEmptyCategoryBudgets_shouldHandleCorrectly() async throws {
        // Given
        let budget = BudgetDTO(
            id: UUID(),
            month: YearMonth.current,
            totalAmount: 1000000,
            categoryBudgets: [] // 빈 카테고리 배열
        )
        mockRepository.createBudgetTemplateResult = makeBudgetTemplateDTO()
        
        // When
        try await sut.execute(budget)
        
        // Then
        XCTAssertEqual(mockRepository.createBudgetTemplateCallCount, 1)
        
        let passedTemplate = mockRepository.lastCreateBudgetTemplateInput!
        XCTAssertEqual(passedTemplate.categoryBudgetTemplates.count, 0)
        XCTAssertEqual(passedTemplate.totalAmount, budget.totalAmount)
    }
    
    func test_execute_shouldNotReturnValue() async throws {
        // Given
        let budget = makeBudgetDTO()
        mockRepository.createBudgetTemplateResult = makeBudgetTemplateDTO()
        
        // When
        try await sut.execute(budget)
        
        // Then
        // execute 메서드는 void를 반환해야 함 (반환값 없음)
        XCTAssertEqual(mockRepository.createBudgetTemplateCallCount, 1)
    }
    
    func test_execute_shouldPreserveAllBudgetData() async throws {
        // Given
        let originalBudget = BudgetDTO(
            id: UUID(),
            month: YearMonth(year: 2024, month: 6),
            totalAmount: 1500000,
            categoryBudgets: [
                CategoryBudgetDTO(
                    id: UUID(),
                    amount: 500000,
                    categoryID: UUID(),
                    categoryName: "식비",
                    budgetId: UUID()
                ),
                CategoryBudgetDTO(
                    id: UUID(),
                    amount: 300000,
                    categoryID: UUID(),
                    categoryName: "교통비",
                    budgetId: UUID()
                )
            ]
        )
        
        // When
        try await sut.execute(originalBudget)
        
        // Then
        let convertedTemplate = mockRepository.lastCreateBudgetTemplateInput!
        
        // 총액 보존 확인
        XCTAssertEqual(convertedTemplate.totalAmount, originalBudget.totalAmount)
        
        // 모든 카테고리 데이터 보존 확인
        XCTAssertEqual(convertedTemplate.categoryBudgetTemplates.count, originalBudget.categoryBudgets.count)
        
        for (index, originalCategory) in originalBudget.categoryBudgets.enumerated() {
            let convertedCategory = convertedTemplate.categoryBudgetTemplates[index]
            XCTAssertEqual(convertedCategory.amount, originalCategory.amount)
            XCTAssertEqual(convertedCategory.categoryID, originalCategory.categoryID)
            XCTAssertEqual(convertedCategory.categoryName, originalCategory.categoryName)
        }
    }
    
    // MARK: - Helper Methods
    
    private func makeBudgetDTO() -> BudgetDTO {
        return BudgetDTO(
            id: UUID(),
            month: YearMonth.current,
            totalAmount: 1000000,
            categoryBudgets: []
        )
    }
    
    private func makeBudgetDTOWithCategories() -> BudgetDTO {
        let categoryBudgets = [
            CategoryBudgetDTO(
                id: UUID(),
                amount: 300000,
                categoryID: UUID(),
                categoryName: "식비",
                budgetId: UUID()
            ),
            CategoryBudgetDTO(
                id: UUID(),
                amount: 200000,
                categoryID: UUID(),
                categoryName: "교통비",
                budgetId: UUID()
            )
        ]
        
        return BudgetDTO(
            id: UUID(),
            month: YearMonth.current,
            totalAmount: 500000,
            categoryBudgets: categoryBudgets
        )
    }
    
    private func makeBudgetTemplateDTO() -> BudgetTemplateDTO {
        return BudgetTemplateDTO(
            id: UUID(),
            totalAmount: 1000000,
            categoryBudgetTemplates: []
        )
    }
}

// MARK: - Mock Repository

private class MockBudgetRepository: BudgetRepository {
    
    // MARK: - Tracking Properties
    
    var createBudgetTemplateCallCount = 0
    var lastCreateBudgetTemplateInput: BudgetTemplateDTO?
    var createBudgetTemplateResult: BudgetTemplateDTO?
    var shouldThrowError: Error?
    
    // MARK: - CreateBudgetTemplate Method (테스트 대상)
    
    func createBudgetTemplate(_ template: BudgetTemplateDTO) async throws -> BudgetTemplateDTO {
        createBudgetTemplateCallCount += 1
        lastCreateBudgetTemplateInput = template
        
        if let error = shouldThrowError {
            throw error
        }
        
        return createBudgetTemplateResult ?? template
    }
    
    // MARK: - Unused Protocol Methods (Stub Implementation)
    
    func fetchBudgetTemplate() async throws -> BudgetTemplateDTO? { return nil }
    func fetchBudgetTemplateWithCategories() async throws -> BudgetTemplateDTO? { return nil }
    func upsertBudgetTemplate(_ template: BudgetTemplateDTO) async throws { }
    func updateBudgetTemplate(_ template: BudgetTemplateDTO) async throws -> BudgetTemplateDTO { return template }
    func updateCategoryBudgetTemplates(_ categoryBudgetTemplates: [CategoryBudgetTemplateDTO]) async throws { }
    func fetchBudget(for month: YearMonth) async throws -> BudgetDTO? { return nil }
    func fetchBudgetWithCategories(for month: YearMonth) async throws -> BudgetDTO? { return nil }
    func fetchCurrentBudget() async throws -> BudgetDTO { return BudgetDTO(id: UUID(), month: .current, totalAmount: 0, categoryBudgets: []) }
    func fetchCurrentBudgetWithCategories() async throws -> BudgetDTO { return BudgetDTO(id: UUID(), month: .current, totalAmount: 0, categoryBudgets: []) }
    func ensureBudgetExists(for month: YearMonth) async throws -> BudgetDTO { return BudgetDTO(id: UUID(), month: month, totalAmount: 0, categoryBudgets: []) }
    func createBudget(for month: YearMonth, budget: BudgetDTO) async throws { }
    func createBudget(_ budget: BudgetDTO) async throws -> BudgetDTO { return budget }
    func fetchRecentBudgets(months: Int) async throws -> [BudgetDTO] { return [] }
    func updateBudget(for month: YearMonth, budget: BudgetDTO) async throws { }
    func updateBudgetTotalAmount(for month: YearMonth, totalAmount: Decimal) async throws { }
    func updateCategoryBudgets(for month: YearMonth, categoryBudgets: [CategoryBudgetDTO]) async throws { }
    func updateCategoryBudget(categoryId: UUID, amount: Decimal, for month: YearMonth) async throws { }
}
