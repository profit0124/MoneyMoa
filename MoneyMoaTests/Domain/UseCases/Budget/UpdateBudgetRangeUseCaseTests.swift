//
//  UpdateBudgetRangeUseCaseTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 8/22/25.
//

import XCTest
@testable import MoneyMoa

final class UpdateBudgetRangeUseCaseTests: XCTestCase {
    
    private var sut: UpdateBudgetRangeUseCaseImpl!
    private var mockRepository: MockBudgetRepository!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockBudgetRepository()
        sut = UpdateBudgetRangeUseCaseImpl(budgetRepository: mockRepository)
    }
    
    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    func test_execute_whenStartMonthEqualsCurrent_shouldUpdateOnlyCurrentMonth() async throws {
        // Given
        let currentMonth = YearMonth.current
        let budget = makeBudgetDTO(for: currentMonth)
        
        // When
        try await sut.execute(from: currentMonth, budget: budget)
        
        // Then
        XCTAssertEqual(mockRepository.updateBudgetCallCount, 1)
        XCTAssertEqual(mockRepository.lastUpdateBudgetMonth, currentMonth)
        XCTAssertEqual(mockRepository.lastUpdateBudgetData?.totalAmount, budget.totalAmount)
    }
    
    func test_execute_whenStartMonthIsThreeMonthsAgo_shouldUpdateThreeMonths() async throws {
        // Given
        let currentMonth = YearMonth.current
        let startMonth = currentMonth.previousMonth().previousMonth() // 2개월 전
        let budget = makeBudgetDTO(for: startMonth)
        
        // When
        try await sut.execute(from: startMonth, budget: budget)
        
        // Then
        XCTAssertEqual(mockRepository.updateBudgetCallCount, 3) // 2개월 전, 1개월 전, 현재월
        
        // 호출된 월들 확인
        let expectedMonths = [
            startMonth,
            startMonth.nextMonth(),
            currentMonth
        ]
        XCTAssertEqual(mockRepository.updateBudgetCalledMonths, expectedMonths)
    }
    
    func test_execute_whenStartMonthIsInPast_shouldUpdateFromStartToCurrentMonth() async throws {
        // Given
        let startMonth = YearMonth.current.previousMonth().previousMonth().previousMonth()
        let budget = makeBudgetDTO(for: startMonth)
        
        // When
        try await sut.execute(from: startMonth, budget: budget)
        
        // Then
        let calledMonths = mockRepository.updateBudgetCalledMonths
        
        // 최소 1개월 이상 업데이트되어야 함
        XCTAssertGreaterThanOrEqual(mockRepository.updateBudgetCallCount, 1)
        XCTAssertGreaterThanOrEqual(calledMonths.count, 1)
        
        // 첫 번째 호출이 시작 월이어야 함
        XCTAssertEqual(calledMonths.first, startMonth)
        
        // 마지막 호출이 현재 월이어야 함 (YearMonth.current)
        XCTAssertEqual(calledMonths.last, YearMonth.current)
        
        // 모든 월이 연속적이어야 함 (배열이 비어있지 않은 경우에만)
        guard calledMonths.count > 1 else {
            return // 1개월만 호출된 경우 (startMonth == current)
        }
        
        for i in 1..<calledMonths.count {
            XCTAssertEqual(calledMonths[i], calledMonths[i-1].nextMonth())
        }
    }
    
    func test_execute_shouldCreateUniqueBudgetDTOForEachMonth() async throws {
        // Given
        let currentMonth = YearMonth.current
        let startMonth = currentMonth.previousMonth() // 1개월 전
        let budget = makeBudgetDTO(for: startMonth)
        
        // When
        try await sut.execute(from: startMonth, budget: budget)
        
        // Then
        XCTAssertEqual(mockRepository.updateBudgetCallCount, 2) // 지난달, 이번달
        
        // 각 호출마다 다른 BudgetDTO 인스턴스가 전달되었는지 확인
        let calledBudgets = mockRepository.updateBudgetCalledBudgets
        XCTAssertEqual(calledBudgets.count, 2)
        
        // 각 예산의 월이 다른지 확인
        XCTAssertEqual(calledBudgets[0].month, startMonth)
        XCTAssertEqual(calledBudgets[1].month, currentMonth)
        
        // 각 예산의 ID가 다른지 확인 (새로 생성되므로)
        XCTAssertNotEqual(calledBudgets[0].id, calledBudgets[1].id)
        
        // 하지만 내용(totalAmount, categoryBudgets)은 같아야 함
        XCTAssertEqual(calledBudgets[0].totalAmount, budget.totalAmount)
        XCTAssertEqual(calledBudgets[1].totalAmount, budget.totalAmount)
        XCTAssertEqual(calledBudgets[0].categoryBudgets.count, budget.categoryBudgets.count)
        XCTAssertEqual(calledBudgets[1].categoryBudgets.count, budget.categoryBudgets.count)
    }
    
    func test_execute_shouldPreserveCategoryBudgetData() async throws {
        // Given
        let currentMonth = YearMonth.current
        let budget = makeBudgetDTOWithCategories(for: currentMonth)
        
        // When
        try await sut.execute(from: currentMonth, budget: budget)
        
        // Then
        let calledBudget = mockRepository.lastUpdateBudgetData!
        
        // 카테고리 개수가 동일한지 확인
        XCTAssertEqual(calledBudget.categoryBudgets.count, budget.categoryBudgets.count)
        
        // 각 카테고리의 내용이 보존되었는지 확인
        for (index, originalCategory) in budget.categoryBudgets.enumerated() {
            let updatedCategory = calledBudget.categoryBudgets[index]
            XCTAssertEqual(updatedCategory.amount, originalCategory.amount)
            XCTAssertEqual(updatedCategory.categoryID, originalCategory.categoryID)
            XCTAssertEqual(updatedCategory.categoryName, originalCategory.categoryName)
            // ID는 새로 생성되므로 다를 수 있음
        }
    }
    
    func test_execute_whenRepositoryThrowsError_shouldPropagateError() async throws {
        // Given
        let currentMonth = YearMonth.current
        let budget = makeBudgetDTO(for: currentMonth)
        let expectedError = RepositoryError.budgetNotFound
        mockRepository.shouldThrowError = expectedError
        
        // When & Then
        do {
            try await sut.execute(from: currentMonth, budget: budget)
            XCTFail("Expected error to be thrown, but execution succeeded")
        } catch let error as RepositoryError {
            // Switch case로 에러 타입 검증
            switch error {
            case .budgetNotFound:
                XCTAssertTrue(true) // 예상된 에러
            default:
                XCTFail("Expected budgetNotFound error, but got \(error)")
            }
        } catch {
            XCTFail("Expected RepositoryError, but got \(type(of: error)): \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func makeBudgetDTO(for month: YearMonth) -> BudgetDTO {
        return BudgetDTO(
            id: UUID(),
            month: month,
            totalAmount: 1000000,
            categoryBudgets: []
        )
    }
    
    private func makeBudgetDTOWithCategories(for month: YearMonth) -> BudgetDTO {
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
            month: month,
            totalAmount: 500000,
            categoryBudgets: categoryBudgets
        )
    }
}

// MARK: - Mock Repository

private class MockBudgetRepository: BudgetRepository {
    
    // MARK: - Tracking Properties
    
    var updateBudgetCallCount = 0
    var updateBudgetCalledMonths: [YearMonth] = []
    var updateBudgetCalledBudgets: [BudgetDTO] = []
    var lastUpdateBudgetMonth: YearMonth?
    var lastUpdateBudgetData: BudgetDTO?
    var shouldThrowError: Error?
    
    // MARK: - UpdateBudget Method (테스트 대상)
    
    func updateBudget(for month: YearMonth, budget: BudgetDTO) async throws {
        if let error = shouldThrowError {
            throw error
        }
        
        updateBudgetCallCount += 1
        updateBudgetCalledMonths.append(month)
        updateBudgetCalledBudgets.append(budget)
        lastUpdateBudgetMonth = month
        lastUpdateBudgetData = budget
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
    func createBudget(_ budget: BudgetDTO) async throws -> BudgetDTO { return budget }
    func fetchRecentBudgets(months: Int) async throws -> [BudgetDTO] { return [] }
    func updateBudgetTotalAmount(for month: YearMonth, totalAmount: Decimal) async throws { }
    func updateCategoryBudgets(for month: YearMonth, categoryBudgets: [CategoryBudgetDTO]) async throws { }
    func updateCategoryBudget(categoryId: UUID, amount: Decimal, for month: YearMonth) async throws { }
}
