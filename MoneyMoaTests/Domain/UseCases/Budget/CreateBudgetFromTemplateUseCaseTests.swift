//
//  CreateBudgetFromTemplateUseCaseTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 8/6/25.
//

import XCTest
@testable import MoneyMoa

// MARK: - CreateBudgetFromTemplateUseCaseImplTests

final class CreateBudgetFromTemplateUseCaseImplTests: XCTestCase {
    
    // MARK: - Properties
    
    private var database: Database!
    private var budgetRepository: BudgetRepositoryImpl!
    private var useCase: CreateBudgetFromTemplateUseCaseImpl!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory database
        database = try Database(isStoredInMemoryOnly: true)
        
        // Create real repository
        budgetRepository = BudgetRepositoryImpl(database: database)
        
        // Create real UseCase
        useCase = CreateBudgetFromTemplateUseCaseImpl(budgetRepository: budgetRepository)
    }
    
    override func tearDown() async throws {
        useCase = nil
        budgetRepository = nil
        database = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Test Methods
    
    func test_execute_withValidTemplate_createsBudgetSuccessfully() async throws {
        // Given
        let template = TestDataFactory.createBudgetTemplate(
            totalAmount: 2_500_000,
            categoryBudgetTemplates: [
                TestDataFactory.createCategoryBudgetTemplate(
                    amount: 1_000_000,
                    categoryID: UUID(),
                    categoryName: "식비",
                    budgetTemplateId: UUID()
                ),
                TestDataFactory.createCategoryBudgetTemplate(
                    amount: 500_000,
                    categoryID: UUID(),
                    categoryName: "교통비",
                    budgetTemplateId: UUID()
                ),
                TestDataFactory.createCategoryBudgetTemplate(
                    amount: 1_000_000,
                    categoryID: UUID(),
                    categoryName: "생활용품",
                    budgetTemplateId: UUID()
                )
            ]
        )
        
        let yearMonth = YearMonth.current
        
        // When
        let result = try await useCase.execute(template: template, yearMonth: yearMonth)
        
        // Then - 기본 정보 검증
        XCTAssertEqual(result.month, yearMonth)
        XCTAssertEqual(result.totalAmount, template.totalAmount)
        XCTAssertEqual(result.categoryBudgets.count, template.categoryBudgetTemplates.count)
        
        // Then - 카테고리별 예산 상세 검증 (순서 독립적)
        for templateBudget in template.categoryBudgetTemplates {
            let matchingCategoryBudget = result.categoryBudgets.first { 
                $0.categoryID == templateBudget.categoryID 
            }
            XCTAssertNotNil(matchingCategoryBudget, "Template category budget not found in result")
            XCTAssertEqual(matchingCategoryBudget?.amount, templateBudget.amount)
            XCTAssertEqual(matchingCategoryBudget?.categoryID, templateBudget.categoryID)
            XCTAssertEqual(matchingCategoryBudget?.categoryName, templateBudget.categoryName)
        }
        
        // Then - 실제 데이터베이스에 저장되었는지 검증
        let savedBudget = try await budgetRepository.fetchBudgetWithCategories(for: yearMonth)
        XCTAssertNotNil(savedBudget)
        XCTAssertEqual(savedBudget?.totalAmount, template.totalAmount)
    }
    
    func test_execute_withEmptyTemplate_createsBudgetWithNoCategories() async throws {
        // Given
        let template = TestDataFactory.createBudgetTemplate(
            totalAmount: 1_000_000,
            categoryBudgetTemplates: [] // 빈 카테고리 템플릿
        )
        let yearMonth = YearMonth(year: 2024, month: 6)
        
        // When
        let result = try await useCase.execute(template: template, yearMonth: yearMonth)
        
        // Then
        XCTAssertEqual(result.month, yearMonth)
        XCTAssertEqual(result.totalAmount, template.totalAmount)
        XCTAssertEqual(result.categoryBudgets.count, 0)
        
        // Then - 실제 데이터베이스 검증
        let savedBudget = try await budgetRepository.fetchBudgetWithCategories(for: yearMonth)
        XCTAssertNotNil(savedBudget)
        XCTAssertEqual(savedBudget?.categoryBudgets.count, 0)
    }
    
    func test_execute_overwritesExistingBudget() async throws {
        // Given - 기존 예산 생성
        let existingBudget = TestDataFactory.createBudget(
            month: YearMonth.current,
            totalAmount: 1_500_000
        )
        try await budgetRepository.createBudget(for: YearMonth.current, budget: existingBudget)
        
        // Given - 새 템플릿
        let newTemplate = TestDataFactory.createBudgetTemplate(
            totalAmount: 3_000_000,
            categoryBudgetTemplates: [
                TestDataFactory.createCategoryBudgetTemplate(
                    amount: 1_500_000,
                    categoryID: UUID(),
                    categoryName: "주거비",
                    budgetTemplateId: UUID()
                )
            ]
        )
        
        // When
        let result = try await useCase.execute(template: newTemplate, yearMonth: YearMonth.current)
        
        // Then - 새 템플릿으로 덮어써졌는지 검증
        XCTAssertEqual(result.totalAmount, newTemplate.totalAmount)
        XCTAssertEqual(result.categoryBudgets.count, 1)
        XCTAssertEqual(result.categoryBudgets.first?.categoryName, "주거비")
        
        // Then - 데이터베이스에 올바르게 업데이트되었는지 검증
        let savedBudget = try await budgetRepository.fetchBudgetWithCategories(for: YearMonth.current)
        XCTAssertEqual(savedBudget?.totalAmount, newTemplate.totalAmount)
    }
    
    func test_execute_withDifferentMonths_createsMultipleBudgets() async throws {
        // Given
        let template = TestDataFactory.createBudgetTemplate(totalAmount: 2_000_000)
        let month1 = YearMonth(year: 2024, month: 1)
        let month2 = YearMonth(year: 2024, month: 2)
        
        // When
        let budget1 = try await useCase.execute(template: template, yearMonth: month1)
        let budget2 = try await useCase.execute(template: template, yearMonth: month2)
        
        // Then
        XCTAssertEqual(budget1.month, month1)
        XCTAssertEqual(budget2.month, month2)
        XCTAssertEqual(budget1.totalAmount, budget2.totalAmount)
        
        // Then - 두 예산 모두 데이터베이스에 저장되었는지 검증
        let savedBudget1 = try await budgetRepository.fetchBudget(for: month1)
        let savedBudget2 = try await budgetRepository.fetchBudget(for: month2)
        XCTAssertNotNil(savedBudget1)
        XCTAssertNotNil(savedBudget2)
    }
}

// MARK: - MockCreateBudgetFromTemplateUseCaseTests (Preview/Simulator 용)

final class MockCreateBudgetFromTemplateUseCaseTests: XCTestCase {
    
    // MARK: - Properties
    
    private var mockUseCase: MockCreateBudgetFromTemplateUseCase!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockUseCase = MockCreateBudgetFromTemplateUseCase()
    }
    
    override func tearDown() {
        mockUseCase = nil
        super.tearDown()
    }
    
    // MARK: - Test Methods
    
    func test_execute_withDefaultConfiguration_createsBudgetSuccessfully() async throws {
        // Given
        let template = TestDataFactory.createBudgetTemplate()
        let yearMonth = YearMonth.current
        
        // When
        let result = try await mockUseCase.execute(template: template, yearMonth: yearMonth)
        
        // Then
        XCTAssertEqual(result.month, yearMonth)
        XCTAssertEqual(result.totalAmount, template.totalAmount)
        XCTAssertEqual(result.categoryBudgets.count, template.categoryBudgetTemplates.count)
    }
    
    func test_execute_withFailureConfiguration_throwsError() async {
        // Given
        let template = TestDataFactory.createBudgetTemplate()
        let yearMonth = YearMonth.current
        
        mockUseCase.configureFailureScenario()
        
        // When & Then
        do {
            _ = try await mockUseCase.execute(template: template, yearMonth: yearMonth)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is RepositoryError)
        }
    }
}