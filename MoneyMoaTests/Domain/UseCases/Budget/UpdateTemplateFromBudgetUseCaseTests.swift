//
//  UpdateTemplateFromBudgetUseCaseTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 8/22/25.
//

import XCTest
@testable import MoneyMoa

final class UpdateTemplateFromBudgetUseCaseTests: XCTestCase {
    
    private var sut: UpdateTemplateFromBudgetUseCaseImpl!
    private var mockRepository: MockBudgetRepository!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockBudgetRepository()
        sut = UpdateTemplateFromBudgetUseCaseImpl(budgetRepository: mockRepository)
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
        mockRepository.updateBudgetTemplateResult = makeBudgetTemplateDTO()
        
        // When
        try await sut.execute(budget)
        
        // Then
        XCTAssertEqual(mockRepository.updateBudgetTemplateCallCount, 1)
        
        guard let passedTemplate = mockRepository.lastUpdateBudgetTemplateInput else {
            XCTFail("Repository updateBudgetTemplate should have been called with template parameter")
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
    
    func test_execute_shouldCallRepositoryUpdateBudgetTemplate() async throws {
        // Given
        let budget = makeBudgetDTO()
        mockRepository.updateBudgetTemplateResult = makeBudgetTemplateDTO()
        
        // When
        try await sut.execute(budget)
        
        // Then
        XCTAssertEqual(mockRepository.updateBudgetTemplateCallCount, 1)
        XCTAssertNotNil(mockRepository.lastUpdateBudgetTemplateInput)
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
        XCTAssertEqual(mockRepository.updateBudgetTemplateCallCount, 1)
    }
    
    func test_execute_withEmptyCategoryBudgets_shouldHandleCorrectly() async throws {
        // Given
        let budget = BudgetDTO(
            id: UUID(),
            month: YearMonth.current,
            totalAmount: 1000000,
            categoryBudgets: [] // 빈 카테고리 배열
        )
        mockRepository.updateBudgetTemplateResult = makeBudgetTemplateDTO()
        
        // When
        try await sut.execute(budget)
        
        // Then
        XCTAssertEqual(mockRepository.updateBudgetTemplateCallCount, 1)
        
        let passedTemplate = mockRepository.lastUpdateBudgetTemplateInput!
        XCTAssertEqual(passedTemplate.categoryBudgetTemplates.count, 0)
        XCTAssertEqual(passedTemplate.totalAmount, budget.totalAmount)
    }
    
    func test_execute_shouldNotReturnValue() async throws {
        // Given
        let budget = makeBudgetDTO()
        mockRepository.updateBudgetTemplateResult = makeBudgetTemplateDTO()
        
        // When
        try await sut.execute(budget)
        
        // Then
        // execute 메서드는 void를 반환해야 함 (반환값 없음)
        XCTAssertEqual(mockRepository.updateBudgetTemplateCallCount, 1)
    }
    
    func test_execute_shouldPreserveAllBudgetData() async throws {
        // Given
        let originalBudget = BudgetDTO(
            id: UUID(),
            month: YearMonth(year: 2024, month: 8),
            totalAmount: 2000000,
            categoryBudgets: [
                CategoryBudgetDTO(
                    id: UUID(),
                    amount: 800000,
                    categoryID: UUID(),
                    categoryName: "식비",
                    budgetId: UUID()
                ),
                CategoryBudgetDTO(
                    id: UUID(),
                    amount: 400000,
                    categoryID: UUID(),
                    categoryName: "교통비",
                    budgetId: UUID()
                ),
                CategoryBudgetDTO(
                    id: UUID(),
                    amount: 600000,
                    categoryID: UUID(),
                    categoryName: "쇼핑",
                    budgetId: UUID()
                )
            ]
        )
        
        // When
        try await sut.execute(originalBudget)
        
        // Then
        let convertedTemplate = mockRepository.lastUpdateBudgetTemplateInput!
        
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
    
    func test_execute_whenRepositoryThrowsDatabaseError_shouldPropagateError() async throws {
        // Given
        let budget = makeBudgetDTO()
        let expectedError = RepositoryError.databaseError(NSError(domain: "test", code: 500))
        mockRepository.shouldThrowError = expectedError
        
        // When & Then
        do {
            try await sut.execute(budget)
            XCTFail("Expected error to be thrown")
        } catch let error as RepositoryError {
            switch error {
            case .databaseError:
                XCTAssertTrue(true) // 예상된 에러
            default:
                XCTFail("Expected databaseError, but got \(error)")
            }
        } catch {
            XCTFail("Expected RepositoryError, but got \(type(of: error)): \(error)")
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
    
    var updateBudgetTemplateCallCount = 0
    var lastUpdateBudgetTemplateInput: BudgetTemplateDTO?
    var updateBudgetTemplateResult: BudgetTemplateDTO?
    var shouldThrowError: Error?
    
    // MARK: - UpdateBudgetTemplate Method (테스트 대상)
    
    func updateBudgetTemplate(_ template: BudgetTemplateDTO) async throws -> BudgetTemplateDTO {
        updateBudgetTemplateCallCount += 1
        lastUpdateBudgetTemplateInput = template
        
        if let error = shouldThrowError {
            throw error
        }
        
        return updateBudgetTemplateResult ?? template
    }
    
    // MARK: - Unused Protocol Methods (Stub Implementation)
    
    func fetchBudgetTemplate() async throws -> BudgetTemplateDTO? { return nil }
    func fetchBudgetTemplateWithCategories() async throws -> BudgetTemplateDTO? { return nil }
    func upsertBudgetTemplate(_ template: BudgetTemplateDTO) async throws { }
    func createBudgetTemplate(_ template: BudgetTemplateDTO) async throws -> BudgetTemplateDTO { return template }
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
