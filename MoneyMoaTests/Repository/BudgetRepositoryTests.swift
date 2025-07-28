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
        // 각 테스트마다 새로운 인메모리 데이터베이스 생성
        database = try Database(isStoredInMemoryOnly: true)
        repository = BudgetRepositoryImpl(database: database)
    }
    
    override func tearDownWithError() throws {
        database = nil
        repository = nil
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
        let categoryId1 = UUID()
        let categoryId2 = UUID()
        let categoryBudgetTemplates = [
            TestDataFactory.createCategoryBudgetTemplate(
                amount: 300000,
                categoryID: categoryId1,
                categoryName: "식비",
                budgetTemplateId: UUID()
            ),
            TestDataFactory.createCategoryBudgetTemplate(
                amount: 200000,
                categoryID: categoryId2,
                categoryName: "교통비", 
                budgetTemplateId: UUID()
            )
        ]
        let template = TestDataFactory.createBudgetTemplate(
            totalAmount: 1000000,
            categoryBudgetTemplates: categoryBudgetTemplates
        )
        
        // When: 템플릿 생성
        try await repository.upsertBudgetTemplate(template)
        
        // Then: 템플릿이 저장됨
        let savedTemplate = try await repository.fetchBudgetTemplate()
        XCTAssertNotNil(savedTemplate)
        XCTAssertEqual(savedTemplate?.totalAmount, 1000000)
        XCTAssertEqual(savedTemplate?.categoryBudgetTemplates.count, 0) // includeCategoryBudgets: false
        
        // 카테고리 포함 조회
        let templateWithCategories = try await repository.fetchBudgetTemplateWithCategories()
        XCTAssertEqual(templateWithCategories?.categoryBudgetTemplates.count, 2)
        XCTAssertTrue(templateWithCategories?.categoryBudgetTemplates.contains { $0.categoryName == "식비" } ?? false)
        XCTAssertTrue(templateWithCategories?.categoryBudgetTemplates.contains { $0.categoryName == "교통비" } ?? false)
    }
    
    func testUpsertBudgetTemplate_ReplaceExisting() async throws {
        // Given: 기존 템플릿 생성
        let originalTemplate = TestDataFactory.createBudgetTemplate(totalAmount: 500000)
        try await repository.upsertBudgetTemplate(originalTemplate)
        
        // When: 새 템플릿으로 교체
        let newTemplate = TestDataFactory.createBudgetTemplate(totalAmount: 1500000)
        try await repository.upsertBudgetTemplate(newTemplate)
        
        // Then: 하나의 템플릿만 존재하며 새 값으로 교체됨
        let savedTemplate = try await repository.fetchBudgetTemplate()
        XCTAssertNotNil(savedTemplate)
        XCTAssertEqual(savedTemplate?.totalAmount, 1500000)
        XCTAssertNotEqual(savedTemplate?.id, originalTemplate.id) // 새로운 ID
    }
    
    func testUpdateCategoryBudgetTemplates_Success() async throws {
        // Given: 기존 템플릿 생성
        let template = TestDataFactory.createBudgetTemplate(totalAmount: 1000000)
        try await repository.upsertBudgetTemplate(template)
        
        // When: 카테고리별 예산 템플릿 업데이트
        let categoryId1 = UUID()
        let categoryId2 = UUID()
        let categoryBudgetTemplates = [
            TestDataFactory.createCategoryBudgetTemplate(
                amount: 400000,
                categoryID: categoryId1,
                categoryName: "식비",
                budgetTemplateId: template.id
            ),
            TestDataFactory.createCategoryBudgetTemplate(
                amount: 150000,
                categoryID: categoryId2,
                categoryName: "교통비",
                budgetTemplateId: template.id
            )
        ]
        try await repository.updateCategoryBudgetTemplates(categoryBudgetTemplates)
        
        // Then: 카테고리별 예산 템플릿이 업데이트됨
        let updatedTemplate = try await repository.fetchBudgetTemplateWithCategories()
        XCTAssertEqual(updatedTemplate?.categoryBudgetTemplates.count, 2)
        XCTAssertEqual(updatedTemplate?.totalAmount, 1000000) // 총액은 변경되지 않음
    }
    
    func testUpdateCategoryBudgetTemplates_NoTemplate() async throws {
        // Given: 템플릿이 없는 상태
        
        // When & Then: 에러 발생
        let categoryBudgetTemplates = [
            TestDataFactory.createCategoryBudgetTemplate(
                amount: 300000,
                categoryID: UUID(),
                categoryName: "식비",
                budgetTemplateId: UUID()
            )
        ]
        
        do {
            try await repository.updateCategoryBudgetTemplates(categoryBudgetTemplates)
            XCTFail("Expected error to be thrown")
        } catch {
            switch error {
            case RepositoryError.budgetTemplateNotFound:
                break // 예상된 에러
            default:
                XCTFail("Expected budgetTemplateNotFound error, but got \(error)")
            }
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
        let categoryId = UUID()
        let categoryBudgetTemplates = [
            TestDataFactory.createCategoryBudgetTemplate(
                amount: 300000,
                categoryID: categoryId,
                categoryName: "식비",
                budgetTemplateId: UUID()
            )
        ]
        let template = TestDataFactory.createBudgetTemplate(
            totalAmount: 1000000,
            categoryBudgetTemplates: categoryBudgetTemplates
        )
        try await repository.upsertBudgetTemplate(template)
        
        // When: 특정 월 예산 자동 생성
        let month = YearMonth(year: 2025, month: 1)
        let budget = try await repository.ensureBudgetExists(for: month)
        
        // Then: 템플릿 기반으로 예산 생성됨
        XCTAssertEqual(budget.month, month)
        XCTAssertEqual(budget.totalAmount, 1000000)
        XCTAssertEqual(budget.categoryBudgets.count, 0) // includeCategoryBudgets: false
        
        // 카테고리 포함 조회로 확인
        let budgetWithCategories = try await repository.fetchBudgetWithCategories(for: month)
        XCTAssertEqual(budgetWithCategories?.categoryBudgets.count, 1)
        XCTAssertEqual(budgetWithCategories?.categoryBudgets.first?.categoryName, "식비")
        XCTAssertEqual(budgetWithCategories?.categoryBudgets.first?.amount, 300000)
    }
    
    func testEnsureBudgetExists_ReturnExisting() async throws {
        // Given: 템플릿과 기존 예산 생성
        let template = TestDataFactory.createBudgetTemplate(totalAmount: 1000000)
        try await repository.upsertBudgetTemplate(template)
        
        let month = YearMonth(year: 2025, month: 1)
        let originalBudget = try await repository.ensureBudgetExists(for: month)
        
        // When: 동일한 월에 대해 다시 호출
        let budget = try await repository.ensureBudgetExists(for: month)
        
        // Then: 기존 예산 반환
        XCTAssertEqual(budget.id, originalBudget.id)
        XCTAssertEqual(budget.month, month)
        XCTAssertEqual(budget.totalAmount, 1000000)
    }
    
    func testEnsureBudgetExists_NoTemplate() async throws {
        // Given: 템플릿이 없는 상태
        let month = YearMonth(year: 2025, month: 1)
        
        // When & Then: 에러 발생
        do {
            _ = try await repository.ensureBudgetExists(for: month)
            XCTFail("Expected error to be thrown")
        } catch {
            switch error {
            case RepositoryError.budgetTemplateNotFound:
                break // 예상된 에러
            default:
                XCTFail("Expected budgetTemplateNotFound error, but got \(error)")
            }
        }
    }
    
    func testFetchCurrentBudget_AutoCreate() async throws {
        // Given: 템플릿 생성
        let template = TestDataFactory.createBudgetTemplate(totalAmount: 1000000)
        try await repository.upsertBudgetTemplate(template)
        
        // When: 현재 월 예산 조회
        let budget = try await repository.fetchCurrentBudget()
        
        // Then: 현재 월 예산이 자동 생성되어 반환됨
        XCTAssertEqual(budget.month, YearMonth.current)
        XCTAssertEqual(budget.totalAmount, 1000000)
    }
    
    func testFetchCurrentBudgetWithCategories_AutoCreate() async throws {
        // Given: 템플릿과 카테고리별 예산 템플릿 생성
        let categoryId = UUID()
        let categoryBudgetTemplates = [
            TestDataFactory.createCategoryBudgetTemplate(
                amount: 300000,
                categoryID: categoryId,
                categoryName: "식비",
                budgetTemplateId: UUID()
            )
        ]
        let template = TestDataFactory.createBudgetTemplate(
            totalAmount: 1000000,
            categoryBudgetTemplates: categoryBudgetTemplates
        )
        try await repository.upsertBudgetTemplate(template)
        
        // When: 카테고리 포함 현재 월 예산 조회
        let budget = try await repository.fetchCurrentBudgetWithCategories()
        
        // Then: 카테고리별 예산 포함하여 반환됨
        XCTAssertEqual(budget.month, YearMonth.current)
        XCTAssertEqual(budget.totalAmount, 1000000)
        XCTAssertEqual(budget.categoryBudgets.count, 1)
        XCTAssertEqual(budget.categoryBudgets.first?.categoryName, "식비")
        XCTAssertEqual(budget.categoryBudgets.first?.amount, 300000)
    }
    
    func testFetchRecentBudgets_WithData() async throws {
        // Given: 템플릿과 여러 월의 예산 생성
        let template = TestDataFactory.createBudgetTemplate(totalAmount: 1000000)
        try await repository.upsertBudgetTemplate(template)
        
        let month1 = YearMonth(year: 2025, month: 1)
        let month2 = YearMonth(year: 2025, month: 2)
        let month3 = YearMonth(year: 2025, month: 3)
        
        _ = try await repository.ensureBudgetExists(for: month1)
        _ = try await repository.ensureBudgetExists(for: month2)
        _ = try await repository.ensureBudgetExists(for: month3)
        
        // When: 최근 예산 목록 조회
        let budgets = try await repository.fetchRecentBudgets(months: 12)
        
        // Then: 최신순으로 정렬되어 반환
        XCTAssertEqual(budgets.count, 3)
        XCTAssertEqual(budgets[0].month, month3) // 가장 최신
        XCTAssertEqual(budgets[1].month, month2)
        XCTAssertEqual(budgets[2].month, month1) // 가장 오래된
    }
    
    func testFetchRecentBudgets_LimitApplied() async throws {
        // Given: 템플릿과 여러 월의 예산 생성
        let template = TestDataFactory.createBudgetTemplate(totalAmount: 1000000)
        try await repository.upsertBudgetTemplate(template)
        
        for month in 1...5 {
            let yearMonth = YearMonth(year: 2025, month: month)
            _ = try await repository.ensureBudgetExists(for: yearMonth)
        }
        
        // When: 제한된 개수로 조회
        let budgets = try await repository.fetchRecentBudgets(months: 3)
        
        // Then: 제한된 개수만 반환
        XCTAssertEqual(budgets.count, 3)
        XCTAssertEqual(budgets[0].month, YearMonth(year: 2025, month: 5)) // 가장 최신
        XCTAssertEqual(budgets[1].month, YearMonth(year: 2025, month: 4))
        XCTAssertEqual(budgets[2].month, YearMonth(year: 2025, month: 3))
    }
    
    // MARK: - 예산 수정 테스트 (Budget Updates)
    
    func testUpdateBudget_Success() async throws {
        // Given: 기존 예산 생성
        let template = TestDataFactory.createBudgetTemplate(totalAmount: 1000000)
        try await repository.upsertBudgetTemplate(template)
        
        let month = YearMonth(year: 2025, month: 1)
        _ = try await repository.ensureBudgetExists(for: month)
        
        // When: 예산 전체 정보 수정
        let categoryId = UUID()
        let categoryBudgets = [
            TestDataFactory.createCategoryBudget(
                amount: 400000,
                categoryID: categoryId,
                categoryName: "식비",
                budgetId: UUID()
            )
        ]
        let updatedBudget = TestDataFactory.createBudget(
            month: month,
            totalAmount: 1200000,
            categoryBudgets: categoryBudgets
        )
        
        try await repository.updateBudget(for: month, budget: updatedBudget)
        
        // Then: 예산이 업데이트됨
        let budget = try await repository.fetchBudgetWithCategories(for: month)
        XCTAssertEqual(budget?.totalAmount, 1200000)
        XCTAssertEqual(budget?.categoryBudgets.count, 1)
        XCTAssertEqual(budget?.categoryBudgets.first?.amount, 400000)
    }
    
    func testUpdateBudget_CategoryBudgetsExceedTotal() async throws {
        // Given: 기존 예산 생성
        let template = TestDataFactory.createBudgetTemplate(totalAmount: 1000000)
        try await repository.upsertBudgetTemplate(template)
        
        let month = YearMonth(year: 2025, month: 1)
        _ = try await repository.ensureBudgetExists(for: month)
        
        // When & Then: 카테고리 예산 합이 총 예산 초과 시 에러 발생
        let categoryId = UUID()
        let categoryBudgets = [
            TestDataFactory.createCategoryBudget(
                amount: 600000,
                categoryID: categoryId,
                categoryName: "식비",
                budgetId: UUID()
            )
        ]
        let updatedBudget = TestDataFactory.createBudget(
            month: month,
            totalAmount: 500000, // 카테고리 예산(600000)보다 작음
            categoryBudgets: categoryBudgets
        )
        
        do {
            try await repository.updateBudget(for: month, budget: updatedBudget)
            XCTFail("Expected error to be thrown")
        } catch {
            switch error {
            case RepositoryError.categoryBudgetsExceedTotalAmount:
                break // 예상된 에러
            default:
                XCTFail("Expected categoryBudgetsExceedTotalAmount error, but got \(error)")
            }
        }
    }
    
    func testUpdateBudgetTotalAmount_Success() async throws {
        // Given: 기존 예산 생성
        let template = TestDataFactory.createBudgetTemplate(totalAmount: 1000000)
        try await repository.upsertBudgetTemplate(template)
        
        let month = YearMonth(year: 2025, month: 1)
        _ = try await repository.ensureBudgetExists(for: month)
        
        // When: 총 예산 금액만 수정
        try await repository.updateBudgetTotalAmount(for: month, totalAmount: 1500000)
        
        // Then: 총 예산 금액만 변경됨
        let budget = try await repository.fetchBudget(for: month)
        XCTAssertEqual(budget?.totalAmount, 1500000)
    }
    
    func testUpdateBudgetTotalAmount_ExceedsExistingCategoryBudgets() async throws {
        // Given: 카테고리별 예산이 있는 기존 예산 생성
        let categoryId = UUID()
        let categoryBudgetTemplates = [
            TestDataFactory.createCategoryBudgetTemplate(
                amount: 600000,
                categoryID: categoryId,
                categoryName: "식비",
                budgetTemplateId: UUID()
            )
        ]
        let template = TestDataFactory.createBudgetTemplate(
            totalAmount: 1000000,
            categoryBudgetTemplates: categoryBudgetTemplates
        )
        try await repository.upsertBudgetTemplate(template)
        
        let month = YearMonth(year: 2025, month: 1)
        _ = try await repository.ensureBudgetExists(for: month)
        
        // When & Then: 기존 카테고리 예산보다 작은 총 예산으로 수정 시 에러 발생
        do {
            try await repository.updateBudgetTotalAmount(for: month, totalAmount: 500000) // 카테고리 예산(600000)보다 작음
            XCTFail("Expected error to be thrown")
        } catch {
            switch error {
            case RepositoryError.categoryBudgetsExceedTotalAmount:
                break // 예상된 에러
            default:
                XCTFail("Expected categoryBudgetsExceedTotalAmount error, but got \(error)")
            }
        }
    }
    
    func testUpdateCategoryBudgets_Success() async throws {
        // Given: 기존 예산 생성
        let template = TestDataFactory.createBudgetTemplate(totalAmount: 1000000)
        try await repository.upsertBudgetTemplate(template)
        
        let month = YearMonth(year: 2025, month: 1)
        _ = try await repository.ensureBudgetExists(for: month)
        
        // When: 카테고리별 예산 수정
        let categoryId1 = UUID()
        let categoryId2 = UUID()
        let categoryBudgets = [
            TestDataFactory.createCategoryBudget(
                amount: 400000,
                categoryID: categoryId1,
                categoryName: "식비",
                budgetId: UUID()
            ),
            TestDataFactory.createCategoryBudget(
                amount: 200000,
                categoryID: categoryId2,
                categoryName: "교통비",
                budgetId: UUID()
            )
        ]
        
        try await repository.updateCategoryBudgets(for: month, categoryBudgets: categoryBudgets)
        
        // Then: 카테고리별 예산이 업데이트됨 (총 예산은 유지)
        let budget = try await repository.fetchBudgetWithCategories(for: month)
        XCTAssertEqual(budget?.totalAmount, 1000000) // 총 예산은 변경되지 않음
        XCTAssertEqual(budget?.categoryBudgets.count, 2)
        XCTAssertTrue(budget?.categoryBudgets.contains { $0.categoryName == "식비" && $0.amount == 400000 } ?? false)
        XCTAssertTrue(budget?.categoryBudgets.contains { $0.categoryName == "교통비" && $0.amount == 200000 } ?? false)
    }
    
    func testUpdateCategoryBudgets_ExceedsTotalAmount() async throws {
        // Given: 기존 예산 생성
        let template = TestDataFactory.createBudgetTemplate(totalAmount: 1000000)
        try await repository.upsertBudgetTemplate(template)
        
        let month = YearMonth(year: 2025, month: 1)
        _ = try await repository.ensureBudgetExists(for: month)
        
        // When & Then: 카테고리 예산 합이 총 예산 초과 시 에러 발생
        let categoryId = UUID()
        let categoryBudgets = [
            TestDataFactory.createCategoryBudget(
                amount: 1200000, // 총 예산(1000000) 초과
                categoryID: categoryId,
                categoryName: "식비",
                budgetId: UUID()
            )
        ]
        
        do {
            try await repository.updateCategoryBudgets(for: month, categoryBudgets: categoryBudgets)
            XCTFail("Expected error to be thrown")
        } catch {
            switch error {
            case RepositoryError.categoryBudgetsExceedTotalAmount:
                break // 예상된 에러
            default:
                XCTFail("Expected categoryBudgetsExceedTotalAmount error, but got \(error)")
            }
        }
    }
    
    func testUpdateCategoryBudget_Success() async throws {
        // Given: 카테고리별 예산이 있는 기존 예산 생성
        let categoryId = UUID()
        let categoryBudgetTemplates = [
            TestDataFactory.createCategoryBudgetTemplate(
                amount: 300000,
                categoryID: categoryId,
                categoryName: "식비",
                budgetTemplateId: UUID()
            )
        ]
        let template = TestDataFactory.createBudgetTemplate(
            totalAmount: 1000000,
            categoryBudgetTemplates: categoryBudgetTemplates
        )
        try await repository.upsertBudgetTemplate(template)
        
        let month = YearMonth(year: 2025, month: 1)
        _ = try await repository.ensureBudgetExists(for: month)
        
        // When: 특정 카테고리 예산 수정
        try await repository.updateCategoryBudget(categoryId: categoryId, amount: 500000, for: month)
        
        // Then: 해당 카테고리 예산만 변경됨
        let budget = try await repository.fetchBudgetWithCategories(for: month)
        XCTAssertEqual(budget?.totalAmount, 1000000) // 총 예산은 변경되지 않음
        XCTAssertEqual(budget?.categoryBudgets.count, 1)
        XCTAssertEqual(budget?.categoryBudgets.first?.amount, 500000)
    }
    
    func testUpdateCategoryBudget_ExceedsTotalAmount() async throws {
        // Given: 카테고리별 예산이 있는 기존 예산 생성
        let categoryId = UUID()
        let categoryBudgetTemplates = [
            TestDataFactory.createCategoryBudgetTemplate(
                amount: 300000,
                categoryID: categoryId,
                categoryName: "식비",
                budgetTemplateId: UUID()
            )
        ]
        let template = TestDataFactory.createBudgetTemplate(
            totalAmount: 1000000,
            categoryBudgetTemplates: categoryBudgetTemplates
        )
        try await repository.upsertBudgetTemplate(template)
        
        let month = YearMonth(year: 2025, month: 1)
        _ = try await repository.ensureBudgetExists(for: month)
        
        // When & Then: 총 예산을 초과하는 금액으로 수정 시 에러 발생
        do {
            try await repository.updateCategoryBudget(categoryId: categoryId, amount: 1200000, for: month) // 총 예산(1000000) 초과
            XCTFail("Expected error to be thrown")
        } catch {
            switch error {
            case RepositoryError.categoryBudgetsExceedTotalAmount:
                break // 예상된 에러
            default:
                XCTFail("Expected categoryBudgetsExceedTotalAmount error, but got \(error)")
            }
        }
    }
    
    func testUpdateCategoryBudget_NonExistingBudget() async throws {
        // Given: 예산이 없는 상태
        let month = YearMonth(year: 2025, month: 1)
        let categoryId = UUID()
        
        // When & Then: 존재하지 않는 예산에 대해 카테고리 예산 수정 시 에러 발생
        do {
            try await repository.updateCategoryBudget(categoryId: categoryId, amount: 300000, for: month)
            XCTFail("Expected error to be thrown")
        } catch {
            switch error {
            case RepositoryError.budgetNotFound:
                break // 예상된 에러
            default:
                XCTFail("Expected budgetNotFound error, but got \(error)")
            }
        }
    }
    
    func testUpdateCategoryBudget_NonExistingCategoryBudget() async throws {
        // Given: 예산은 있지만 해당 카테고리 예산이 없는 상태
        let template = TestDataFactory.createBudgetTemplate(totalAmount: 1000000)
        try await repository.upsertBudgetTemplate(template)
        
        let month = YearMonth(year: 2025, month: 1)
        _ = try await repository.ensureBudgetExists(for: month)
        
        let nonExistingCategoryId = UUID()
        
        // When & Then: 존재하지 않는 카테고리 예산 수정 시 에러 발생
        do {
            try await repository.updateCategoryBudget(categoryId: nonExistingCategoryId, amount: 300000, for: month)
            XCTFail("Expected error to be thrown")
        } catch {
            switch error {
            case RepositoryError.categoryBudgetNotFound:
                break // 예상된 에러
            default:
                XCTFail("Expected categoryBudgetNotFound error, but got \(error)")
            }
        }
    }
}