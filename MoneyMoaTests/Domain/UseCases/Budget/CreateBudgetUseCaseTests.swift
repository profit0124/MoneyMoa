//
//  CreateBudgetUseCaseTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 8/22/25.
//

import XCTest
@testable import MoneyMoa

final class CreateBudgetUseCaseTests: XCTestCase {
    
    private var sut: CreateBudgetUseCaseImpl!
    private var mockRepository: MockBudgetRepository!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockBudgetRepository()
        sut = CreateBudgetUseCaseImpl(budgetRepository: mockRepository)
    }
    
    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    func test_execute_whenNoBudgetExists_shouldCreateNewBudgetSuccessfully() async throws {
        // Given
        let budget = makeBudgetDTO()
        let expectedCreatedBudget = makeBudgetDTO(id: UUID()) // Repository에서 반환할 예산
        mockRepository.createBudgetResult = expectedCreatedBudget
        
        // When
        let result = try await sut.execute(budget)
        
        // Then
        XCTAssertEqual(mockRepository.createBudgetCallCount, 1)
        XCTAssertEqual(mockRepository.lastCreateBudgetInput?.totalAmount, budget.totalAmount)
        XCTAssertEqual(mockRepository.lastCreateBudgetInput?.month, budget.month)
        XCTAssertEqual(mockRepository.lastCreateBudgetInput?.categoryBudgets.count, budget.categoryBudgets.count)
        
        // 반환값 검증
        XCTAssertEqual(result.id, expectedCreatedBudget.id)
        XCTAssertEqual(result.totalAmount, expectedCreatedBudget.totalAmount)
        XCTAssertEqual(result.month, expectedCreatedBudget.month)
    }
    
    func test_execute_whenBudgetAlreadyExists_shouldThrowBudgetAlreadyExistsError() async throws {
        // Given
        let budget = makeBudgetDTO()
        mockRepository.shouldThrowError = RepositoryError.budgetAlreadyExists
        
        // When & Then
        do {
            _ = try await sut.execute(budget)
            XCTFail("Expected budgetAlreadyExists error to be thrown")
        } catch let error as RepositoryError {
            switch error {
            case .budgetAlreadyExists:
                XCTAssertTrue(true) // 예상된 에러
            default:
                XCTFail("Expected budgetAlreadyExists error, but got \(error)")
            }
        } catch {
            XCTFail("Expected RepositoryError, but got \(type(of: error)): \(error)")
        }
        
        // Repository 호출 확인
        XCTAssertEqual(mockRepository.createBudgetCallCount, 1)
    }
    
    func test_execute_shouldPassCorrectParametersToRepository() async throws {
        // Given
        let budget = makeBudgetDTOWithCategories()
        mockRepository.createBudgetResult = budget
        
        // When
        _ = try await sut.execute(budget)
        
        // Then
        guard let passedBudget = mockRepository.lastCreateBudgetInput else {
            XCTFail("Repository createBudget should have been called with budget parameter")
            return
        }
        
        // 모든 필드가 정확히 전달되었는지 확인
        XCTAssertEqual(passedBudget.id, budget.id)
        XCTAssertEqual(passedBudget.month, budget.month)
        XCTAssertEqual(passedBudget.totalAmount, budget.totalAmount)
        XCTAssertEqual(passedBudget.categoryBudgets.count, budget.categoryBudgets.count)
        
        // 카테고리별 예산 정보 검증
        for (index, originalCategory) in budget.categoryBudgets.enumerated() {
            let passedCategory = passedBudget.categoryBudgets[index]
            XCTAssertEqual(passedCategory.id, originalCategory.id)
            XCTAssertEqual(passedCategory.amount, originalCategory.amount)
            XCTAssertEqual(passedCategory.categoryID, originalCategory.categoryID)
            XCTAssertEqual(passedCategory.categoryName, originalCategory.categoryName)
        }
    }
    
    func test_execute_shouldReturnRepositoryResult() async throws {
        // Given
        let inputBudget = makeBudgetDTO()
        let repositoryResult = makeBudgetDTO(
            id: UUID(),
            totalAmount: inputBudget.totalAmount + 1000 // 다른 값으로 설정
        )
        mockRepository.createBudgetResult = repositoryResult
        
        // When
        let result = try await sut.execute(inputBudget)
        
        // Then
        // UseCase는 Repository 결과를 그대로 반환해야 함
        XCTAssertEqual(result.id, repositoryResult.id)
        XCTAssertEqual(result.totalAmount, repositoryResult.totalAmount)
        XCTAssertEqual(result.month, repositoryResult.month)
    }
    
    func test_execute_whenRepositoryThrowsOtherError_shouldPropagateError() async throws {
        // Given
        let budget = makeBudgetDTO()
        let expectedError = RepositoryError.databaseError(NSError(domain: "test", code: 500))
        mockRepository.shouldThrowError = expectedError
        
        // When & Then
        do {
            _ = try await sut.execute(budget)
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
    
    func test_execute_withEmptyCategoryBudgets_shouldHandleCorrectly() async throws {
        // Given
        let budget = BudgetDTO(
            id: UUID(),
            month: YearMonth.current,
            totalAmount: 1000000,
            categoryBudgets: [] // 빈 카테고리 배열
        )
        mockRepository.createBudgetResult = budget
        
        // When
        let result = try await sut.execute(budget)
        
        // Then
        XCTAssertEqual(mockRepository.createBudgetCallCount, 1)
        XCTAssertEqual(result.categoryBudgets.count, 0)
        XCTAssertEqual(mockRepository.lastCreateBudgetInput?.categoryBudgets.count, 0)
    }
    
    // MARK: - Helper Methods
    
    private func makeBudgetDTO(id: UUID? = nil, totalAmount: Decimal = 1000000) -> BudgetDTO {
        return BudgetDTO(
            id: id ?? UUID(),
            month: YearMonth.current,
            totalAmount: totalAmount,
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
}

// MARK: - Mock Repository

private class MockBudgetRepository: BudgetRepository {
    
    // MARK: - Tracking Properties
    
    var createBudgetCallCount = 0
    var lastCreateBudgetInput: BudgetDTO?
    var createBudgetResult: BudgetDTO?
    var shouldThrowError: Error?
    
    // MARK: - CreateBudget Method (테스트 대상)
    
    func createBudget(_ budget: BudgetDTO) async throws -> BudgetDTO {
        createBudgetCallCount += 1
        lastCreateBudgetInput = budget
        
        if let error = shouldThrowError {
            throw error
        }
        
        return createBudgetResult ?? budget
    }
    
    // MARK: - Unused Protocol Methods (Stub Implementation)
    
    func fetchBudgetTemplate() async throws -> BudgetTemplateDTO? { return nil }
    func fetchBudgetTemplateWithCategories() async throws -> BudgetTemplateDTO? { return nil }
    func upsertBudgetTemplate(_ template: BudgetTemplateDTO) async throws { }
    func createBudgetTemplate(_ template: BudgetTemplateDTO) async throws -> BudgetTemplateDTO { return template }
    func updateBudgetTemplate(_ template: BudgetTemplateDTO) async throws -> BudgetTemplateDTO { return template }
    func updateCategoryBudgetTemplates(_ categoryBudgetTemplates: [CategoryBudgetTemplateDTO]) async throws { }
    func fetchBudget(for month: YearMonth) async throws -> BudgetDTO? { return nil }
    func fetchBudgetWithCategories(for month: YearMonth) async throws -> BudgetDTO? { return nil }
    func fetchCurrentBudget() async throws -> BudgetDTO { return BudgetDTO(id: UUID(), month: .current, totalAmount: 0, categoryBudgets: []) }
    func fetchCurrentBudgetWithCategories() async throws -> BudgetDTO { return BudgetDTO(id: UUID(), month: .current, totalAmount: 0, categoryBudgets: []) }
    func ensureBudgetExists(for month: YearMonth) async throws -> BudgetDTO { return BudgetDTO(id: UUID(), month: month, totalAmount: 0, categoryBudgets: []) }
    func createBudget(for month: YearMonth, budget: BudgetDTO) async throws { }
    func fetchRecentBudgets(months: Int) async throws -> [BudgetDTO] { return [] }
    func updateBudget(for month: YearMonth, budget: BudgetDTO) async throws { }
    func updateBudgetTotalAmount(for month: YearMonth, totalAmount: Decimal) async throws { }
    func updateCategoryBudgets(for month: YearMonth, categoryBudgets: [CategoryBudgetDTO]) async throws { }
    func updateCategoryBudget(categoryId: UUID, amount: Decimal, for month: YearMonth) async throws { }
}
