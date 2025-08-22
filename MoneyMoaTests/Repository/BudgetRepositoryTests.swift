//
//  BudgetRepositoryTests.swift
//  MoneyMoaTests
//
//  Created by Sooik Kim on 7/28/25.
//

import XCTest
import SwiftData
@testable import MoneyMoa

final class BudgetRepositoryTests: XCTestCase {
    
    private var database: Database!
    private var repository: BudgetRepositoryImpl!
    
    override func setUpWithError() throws {
        database = try Database(isStoredInMemoryOnly: true)
        repository = BudgetRepositoryImpl(database: database)
    }
    
    override func tearDownWithError() throws {
        database = nil
        repository = nil
    }
    
    // MARK: - Helper Methods
    
    private func createTemplateWithBudget() async throws -> YearMonth {
        let template = BudgetTemplateDTO.mockSimple
        try await repository.upsertBudgetTemplate(template)
        
        let month = YearMonth(year: 2025, month: 1)
        _ = try await repository.ensureBudgetExists(for: month)
        return month
    }
    
    private func assertRepositoryError<T>(_ expectedError: RepositoryError, in block: () async throws -> T) async {
        do {
            _ = try await block()
            XCTFail("Expected \(expectedError) error to be thrown")
        } catch let error as RepositoryError {
            switch (expectedError, error) {
            case (.budgetTemplateNotFound, .budgetTemplateNotFound),
                 (.budgetNotFound, .budgetNotFound),
                 (.budgetAlreadyExists, .budgetAlreadyExists),
                 (.categoryBudgetNotFound, .categoryBudgetNotFound),
                 (.categoryBudgetsExceedTotalAmount, .categoryBudgetsExceedTotalAmount):
                break
            default:
                XCTFail("Expected \(expectedError), but got \(error)")
            }
        } catch {
            XCTFail("Expected RepositoryError, but got \(type(of: error)): \(error)")
        }
    }
    
    // MARK: - Template 관리 테스트 (Template Management)
    
    func testFetchBudgetTemplate_EmptyDatabase() async throws {
        // Given: 빈 데이터베이스
        
        // When: 예산 템플릿 조회
        let template = try await repository.fetchBudgetTemplate()
        
        // Then: nil 반환
        XCTAssertNil(template)
    }
    
    func testUpsertBudgetTemplate_CreateNew() async throws {
        // Given: 새로운 예산 템플릿
        let template = BudgetTemplateDTO.mockStandard
        
        // When: 템플릿 생성
        try await repository.upsertBudgetTemplate(template)
        
        // Then: 템플릿이 저장됨
        let savedTemplate = try await repository.fetchBudgetTemplate()
        XCTAssertNotNil(savedTemplate)
        XCTAssertEqual(savedTemplate?.totalAmount, 2_000_000)
        XCTAssertEqual(savedTemplate?.categoryBudgetTemplates.count, 0) // includeCategoryBudgets: false
        
        // 카테고리 포함 조회
        let templateWithCategories = try await repository.fetchBudgetTemplateWithCategories()
        XCTAssertEqual(templateWithCategories?.categoryBudgetTemplates.count, 4)
        XCTAssertTrue(templateWithCategories?.categoryBudgetTemplates.contains { $0.categoryName == "식비" } ?? false)
        XCTAssertTrue(templateWithCategories?.categoryBudgetTemplates.contains { $0.categoryName == "교통비" } ?? false)
    }
    
    func testUpsertBudgetTemplate_ReplaceExisting() async throws {
        // Given: 기존 템플릿 생성
        let originalTemplate = BudgetTemplateDTO.mockSimple
        try await repository.upsertBudgetTemplate(originalTemplate)
        
        // When: 다른 값으로 새 템플릿 업서트
        let updatedTemplate = BudgetTemplateDTO.mockLarge
        try await repository.upsertBudgetTemplate(updatedTemplate)
        
        // Then: 기존 템플릿이 업데이트됨 (ID는 유지, 값은 변경)
        let savedTemplate = try await repository.fetchBudgetTemplate()
        XCTAssertNotNil(savedTemplate)
        XCTAssertEqual(savedTemplate?.totalAmount, 3_000_000) // 새로운 값으로 업데이트
        XCTAssertEqual(savedTemplate?.id, originalTemplate.id) // 기존 ID 유지
        
        // 카테고리 개수도 확인
        let templateWithCategories = try await repository.fetchBudgetTemplateWithCategories()
        XCTAssertEqual(templateWithCategories?.categoryBudgetTemplates.count, 4) // mockLarge의 카테고리 개수
    }
    
    func testUpdateCategoryBudgetTemplates_Success() async throws {
        // Given: 기존 템플릿 생성
        let template = BudgetTemplateDTO.mockSimple
        try await repository.upsertBudgetTemplate(template)
        
        // When: 카테고리별 예산 템플릿 업데이트
        let categoryBudgetTemplates = [
            CategoryBudgetTemplateDTO.mockFood,
            CategoryBudgetTemplateDTO.mockTransport
        ]
        try await repository.updateCategoryBudgetTemplates(categoryBudgetTemplates)
        
        // Then: 카테고리별 예산 템플릿이 업데이트됨
        let updatedTemplate = try await repository.fetchBudgetTemplateWithCategories()
        XCTAssertEqual(updatedTemplate?.categoryBudgetTemplates.count, 2)
        XCTAssertEqual(updatedTemplate?.totalAmount, 1_000_000) // 총액은 변경되지 않음
    }
    
    func testUpdateCategoryBudgetTemplates_NoTemplate() async throws {
        let categoryBudgetTemplates = [CategoryBudgetTemplateDTO.mockFood]
        
        await assertRepositoryError(.budgetTemplateNotFound) {
            try await repository.updateCategoryBudgetTemplates(categoryBudgetTemplates)
        }
    }
    
    // MARK: - Budget 관리 테스트 (Monthly Budget Management)
    
    func testFetchBudget_NonExisting() async throws {
        // Given: 빈 데이터베이스
        let month = YearMonth(year: 2025, month: 1)
        
        // When: 특정 월 예산 조회
        let budget = try await repository.fetchBudget(for: month)
        
        // Then: nil 반환
        XCTAssertNil(budget)
    }
    
    func testEnsureBudgetExists_CreateFromTemplate() async throws {
        // Given: 템플릿 생성
        let template = BudgetTemplateDTO.mockStandard
        try await repository.upsertBudgetTemplate(template)
        
        // When: 특정 월 예산 자동 생성
        let month = YearMonth(year: 2025, month: 1)
        let budget = try await repository.ensureBudgetExists(for: month)
        
        // Then: 템플릿 기반으로 예산 생성됨
        XCTAssertEqual(budget.month, month)
        XCTAssertEqual(budget.totalAmount, 2_000_000)
        XCTAssertEqual(budget.categoryBudgets.count, 0) // includeCategoryBudgets: false
        
        // 카테고리 포함 조회로 확인
        let budgetWithCategories = try await repository.fetchBudgetWithCategories(for: month)
        XCTAssertEqual(budgetWithCategories?.categoryBudgets.count, 4)
        XCTAssertTrue(budgetWithCategories?.categoryBudgets.contains { $0.categoryName == "식비" } ?? false)
    }
    
    func testEnsureBudgetExists_ReturnExisting() async throws {
        // Given: 템플릿과 기존 예산 생성
        let template = BudgetTemplateDTO.mockSimple
        try await repository.upsertBudgetTemplate(template)
        
        let month = YearMonth(year: 2025, month: 1)
        let originalBudget = try await repository.ensureBudgetExists(for: month)
        
        // When: 동일한 월에 대해 다시 호출
        let budget = try await repository.ensureBudgetExists(for: month)
        
        // Then: 기존 예산 반환
        XCTAssertEqual(budget.id, originalBudget.id)
        XCTAssertEqual(budget.month, month)
        XCTAssertEqual(budget.totalAmount, 1_000_000)
    }
    
    func testEnsureBudgetExists_NoTemplate() async throws {
        let month = YearMonth(year: 2025, month: 1)
        
        await assertRepositoryError(.budgetTemplateNotFound) {
            try await repository.ensureBudgetExists(for: month)
        }
    }
    
    func testFetchCurrentBudget_AutoCreate() async throws {
        let template = BudgetTemplateDTO.mockStandard
        try await repository.upsertBudgetTemplate(template)
        
        let budget = try await repository.fetchCurrentBudget()
        XCTAssertEqual(budget.month, YearMonth.current)
        XCTAssertEqual(budget.totalAmount, 2_000_000)
        
        let budgetWithCategories = try await repository.fetchCurrentBudgetWithCategories()
        XCTAssertEqual(budgetWithCategories.categoryBudgets.count, 4)
    }
    
    func testFetchRecentBudgets() async throws {
        let template = BudgetTemplateDTO.mockSimple
        try await repository.upsertBudgetTemplate(template)
        
        for month in 1...5 {
            let yearMonth = YearMonth(year: 2025, month: month)
            _ = try await repository.ensureBudgetExists(for: yearMonth)
        }
        
        let allBudgets = try await repository.fetchRecentBudgets(months: 12)
        let limitedBudgets = try await repository.fetchRecentBudgets(months: 3)
        
        XCTAssertEqual(allBudgets.count, 5)
        XCTAssertEqual(limitedBudgets.count, 3)
        XCTAssertEqual(limitedBudgets[0].month, YearMonth(year: 2025, month: 5))
    }
    
    // MARK: - 예산 수정 테스트 (Budget Updates)
    
    func testUpdateBudget_Success() async throws {
        // Given: 기존 예산 생성
        let template = BudgetTemplateDTO.mockSimple
        try await repository.upsertBudgetTemplate(template)
        
        let month = YearMonth(year: 2025, month: 1)
        _ = try await repository.ensureBudgetExists(for: month)
        
        // When: 예산 전체 정보 수정
        let categoryBudgets = [CategoryBudgetDTO.mockFood]
        let updatedBudget = BudgetDTO(
            month: month,
            totalAmount: 1_200_000,
            categoryBudgets: categoryBudgets
        )
        
        try await repository.updateBudget(for: month, budget: updatedBudget)
        
        // Then: 예산이 업데이트됨
        let budget = try await repository.fetchBudgetWithCategories(for: month)
        XCTAssertEqual(budget?.totalAmount, 1_200_000)
        XCTAssertEqual(budget?.categoryBudgets.count, 1)
        XCTAssertEqual(budget?.categoryBudgets.first?.amount, 800_000)
    }
    
    func testUpdateBudget_CategoryBudgetsExceedTotal() async throws {
        let month = try await createTemplateWithBudget()
        let categoryBudgets = [CategoryBudgetDTO.mockFood] // 800,000
        let updatedBudget = BudgetDTO(month: month, totalAmount: 500_000, categoryBudgets: categoryBudgets)
        
        await assertRepositoryError(.categoryBudgetsExceedTotalAmount) {
            try await repository.updateBudget(for: month, budget: updatedBudget)
        }
    }
    
    func testUpdateBudgetTotalAmount_Success() async throws {
        // Given: 기존 예산 생성
        let template = BudgetTemplateDTO.mockSimple
        try await repository.upsertBudgetTemplate(template)
        
        let month = YearMonth(year: 2025, month: 1)
        _ = try await repository.ensureBudgetExists(for: month)
        
        // When: 총 예산 금액만 수정
        try await repository.updateBudgetTotalAmount(for: month, totalAmount: 1_500_000)
        
        // Then: 총 예산 금액만 변경됨
        let budget = try await repository.fetchBudget(for: month)
        XCTAssertEqual(budget?.totalAmount, 1_500_000)
    }
    
    func testUpdateBudgetTotalAmount_ExceedsExistingCategoryBudgets() async throws {
        let template = BudgetTemplateDTO.mockStandard
        try await repository.upsertBudgetTemplate(template)
        let month = YearMonth(year: 2025, month: 1)
        _ = try await repository.ensureBudgetExists(for: month)
        
        await assertRepositoryError(.categoryBudgetsExceedTotalAmount) {
            try await repository.updateBudgetTotalAmount(for: month, totalAmount: 500_000)
        }
    }
    
    func testUpdateCategoryBudgets_Success() async throws {
        // Given: 기존 예산 생성
        let template = BudgetTemplateDTO.mockSimple
        try await repository.upsertBudgetTemplate(template)
        
        let month = YearMonth(year: 2025, month: 1)
        _ = try await repository.ensureBudgetExists(for: month)
        
        // When: 카테고리별 예산 수정
        let categoryBudgets = [
            CategoryBudgetDTO.mockWith(name: "식비", amount: 400_000),
            CategoryBudgetDTO.mockWith(name: "교통비", amount: 200_000)
        ]
        
        try await repository.updateCategoryBudgets(for: month, categoryBudgets: categoryBudgets)
        
        // Then: 카테고리별 예산이 업데이트됨 (총 예산은 유지)
        let budget = try await repository.fetchBudgetWithCategories(for: month)
        XCTAssertEqual(budget?.totalAmount, 1_000_000) // 총 예산은 변경되지 않음
        XCTAssertEqual(budget?.categoryBudgets.count, 2)
        XCTAssertTrue(budget?.categoryBudgets.contains { $0.categoryName == "식비" && $0.amount == 400_000 } ?? false)
        XCTAssertTrue(budget?.categoryBudgets.contains { $0.categoryName == "교통비" && $0.amount == 200_000 } ?? false)
    }
    
    func testUpdateCategoryBudgets_ExceedsTotalAmount() async throws {
        let month = try await createTemplateWithBudget()
        let categoryBudgets = [CategoryBudgetDTO.mockWith(name: "식비", amount: 1_200_000)]
        
        await assertRepositoryError(.categoryBudgetsExceedTotalAmount) {
            try await repository.updateCategoryBudgets(for: month, categoryBudgets: categoryBudgets)
        }
    }
    
    func testUpdateCategoryBudget_Success() async throws {
        // Given: 카테고리별 예산이 있는 기존 예산 생성
        let template = BudgetTemplateDTO.mockStandard
        try await repository.upsertBudgetTemplate(template)
        
        let month = YearMonth(year: 2025, month: 1)
        _ = try await repository.ensureBudgetExists(for: month)
        
        let categoryId = CategoryDTO.mockExpense.id
        
        // When: 특정 카테고리 예산 수정
        try await repository.updateCategoryBudget(categoryId: categoryId, amount: 500_000, for: month)
        
        // Then: 해당 카테고리 예산만 변경됨
        let budget = try await repository.fetchBudgetWithCategories(for: month)
        XCTAssertEqual(budget?.totalAmount, 2_000_000) // 총 예산은 변경되지 않음
        XCTAssertGreaterThan(budget?.categoryBudgets.count ?? 0, 0)
    }
    
    func testUpdateCategoryBudget_ExceedsTotalAmount() async throws {
        let template = BudgetTemplateDTO.mockStandard
        try await repository.upsertBudgetTemplate(template)
        let month = YearMonth(year: 2025, month: 1)
        _ = try await repository.ensureBudgetExists(for: month)
        let categoryId = CategoryDTO.mockExpense.id
        
        await assertRepositoryError(.categoryBudgetsExceedTotalAmount) {
            try await repository.updateCategoryBudget(categoryId: categoryId, amount: 3_000_000, for: month)
        }
    }
    
    func testUpdateCategoryBudget_NonExistingBudget() async throws {
        let month = YearMonth(year: 2025, month: 1)
        let categoryId = CategoryDTO.mockExpense.id
        
        await assertRepositoryError(.budgetNotFound) {
            try await repository.updateCategoryBudget(categoryId: categoryId, amount: 300_000, for: month)
        }
    }
    
    func testUpdateCategoryBudget_NonExistingCategoryBudget() async throws {
        let month = try await createTemplateWithBudget()
        let nonExistingCategoryId = UUID()
        
        await assertRepositoryError(.categoryBudgetNotFound) {
            try await repository.updateCategoryBudget(categoryId: nonExistingCategoryId, amount: 300_000, for: month)
        }
    }
    
    // MARK: - CreateBudget 테스트 (Direct Budget Creation)
    
    func testCreateBudget_NewBudget_Success() async throws {
        // Given: 새로운 예산 DTO
        let month = YearMonth(year: 2025, month: 6)
        let categoryBudgets = [
            CategoryBudgetDTO.mockWith(name: "식비", amount: 400_000),
            CategoryBudgetDTO.mockWith(name: "교통비", amount: 300_000)
        ]
        let budget = BudgetDTO(
            id: UUID(),
            month: month,
            totalAmount: 1_000_000,
            categoryBudgets: categoryBudgets
        )
        
        // When: 예산 생성
        let createdBudget = try await repository.createBudget(budget)
        
        // Then: 예산이 성공적으로 생성됨
        XCTAssertEqual(createdBudget.month, month)
        XCTAssertEqual(createdBudget.totalAmount, 1_000_000)
        XCTAssertEqual(createdBudget.categoryBudgets.count, 2)
        
        // 실제로 저장되었는지 확인
        let savedBudget = try await repository.fetchBudgetWithCategories(for: month)
        XCTAssertNotNil(savedBudget)
        XCTAssertEqual(savedBudget?.totalAmount, 1_000_000)
        XCTAssertEqual(savedBudget?.categoryBudgets.count, 2)
        XCTAssertTrue(savedBudget?.categoryBudgets.contains { $0.categoryName == "식비" && $0.amount == 400_000 } ?? false)
        XCTAssertTrue(savedBudget?.categoryBudgets.contains { $0.categoryName == "교통비" && $0.amount == 300_000 } ?? false)
    }
    
    func testCreateBudget_WithEmptyCategories_Success() async throws {
        // Given: 카테고리가 없는 예산 DTO
        let month = YearMonth(year: 2025, month: 7)
        let budget = BudgetDTO(
            id: UUID(),
            month: month,
            totalAmount: 500_000,
            categoryBudgets: []
        )
        
        // When: 예산 생성
        let createdBudget = try await repository.createBudget(budget)
        
        // Then: 예산이 성공적으로 생성됨
        XCTAssertEqual(createdBudget.month, month)
        XCTAssertEqual(createdBudget.totalAmount, 500_000)
        XCTAssertEqual(createdBudget.categoryBudgets.count, 0)
        
        // 실제로 저장되었는지 확인
        let savedBudget = try await repository.fetchBudgetWithCategories(for: month)
        XCTAssertNotNil(savedBudget)
        XCTAssertEqual(savedBudget?.totalAmount, 500_000)
        XCTAssertEqual(savedBudget?.categoryBudgets.count, 0)
    }
    
    func testCreateBudget_BudgetAlreadyExists_ThrowsError() async throws {
        let month = YearMonth(year: 2025, month: 8)
        let existingBudget = BudgetDTO(id: UUID(), month: month, totalAmount: 800_000, categoryBudgets: [])
        _ = try await repository.createBudget(existingBudget)
        
        let newBudget = BudgetDTO(id: UUID(), month: month, totalAmount: 1_200_000, categoryBudgets: [])
        
        await assertRepositoryError(.budgetAlreadyExists) {
            try await repository.createBudget(newBudget)
        }
        
        let savedBudget = try await repository.fetchBudget(for: month)
        XCTAssertEqual(savedBudget?.totalAmount, 800_000)
    }
    
    func testCreateBudget_PreservesAllBudgetData() async throws {
        let month = YearMonth(year: 2025, month: 9)
        let categoryBudgets = [
            CategoryBudgetDTO.mockWith(name: "식비", amount: 600_000),
            CategoryBudgetDTO.mockWith(name: "교통비", amount: 200_000)
        ]
        let originalBudget = BudgetDTO(id: UUID(), month: month, totalAmount: 1_500_000, categoryBudgets: categoryBudgets)
        
        let createdBudget = try await repository.createBudget(originalBudget)
        
        XCTAssertEqual(createdBudget.month, originalBudget.month)
        XCTAssertEqual(createdBudget.totalAmount, originalBudget.totalAmount)
        XCTAssertEqual(createdBudget.categoryBudgets.count, originalBudget.categoryBudgets.count)
        
        let savedBudget = try await repository.fetchBudgetWithCategories(for: month)!
        XCTAssertEqual(savedBudget.totalAmount, 1_500_000)
        XCTAssertEqual(savedBudget.categoryBudgets.count, 2)
    }
}
