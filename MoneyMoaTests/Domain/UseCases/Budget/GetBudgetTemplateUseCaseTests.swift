//
//  GetBudgetTemplateUseCaseTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 8/5/25.
//

import XCTest
@testable import MoneyMoa

// MARK: - GetBudgetTemplateUseCaseImplTests

final class GetBudgetTemplateUseCaseImplTests: XCTestCase {
    
    // MARK: - Properties
    
    private var database: Database!
    private var budgetRepository: BudgetRepositoryImpl!
    private var useCase: GetBudgetTemplateUseCaseImpl!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory database
        database = try Database(isStoredInMemoryOnly: true)
        
        // Create real repository
        budgetRepository = BudgetRepositoryImpl(database: database)
        
        // Create real UseCase
        useCase = GetBudgetTemplateUseCaseImpl(budgetRepository: budgetRepository)
    }
    
    override func tearDown() async throws {
        useCase = nil
        budgetRepository = nil
        database = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Test Methods
    
    func test_execute_withExistingTemplate_returnsTemplate() async throws {
        // Given
        let expectedTemplate = BudgetTemplateDTO.mockStandard
        
        // Save template to database
        try await budgetRepository.upsertBudgetTemplate(expectedTemplate)
        
        // When
        let result = try await useCase.execute()
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.totalAmount, expectedTemplate.totalAmount)
        XCTAssertEqual(result?.categoryBudgetTemplates.count, expectedTemplate.categoryBudgetTemplates.count)
        
        // Verify category budget templates match (order independent)
        for expectedCategoryBudget in expectedTemplate.categoryBudgetTemplates {
            let matchingCategoryBudget = result?.categoryBudgetTemplates.first { 
                $0.id == expectedCategoryBudget.id
            }
            XCTAssertNotNil(matchingCategoryBudget)
            XCTAssertEqual(matchingCategoryBudget?.amount, expectedCategoryBudget.amount)
            XCTAssertEqual(matchingCategoryBudget?.categoryName, expectedCategoryBudget.categoryName)
        }
    }
    
    func test_execute_withNoTemplate_returnsNil() async throws {
        // Given - No template saved to database (clean database)
        
        // When
        let result = try await useCase.execute()
        
        // Then
        XCTAssertNil(result)
    }
    
    func test_execute_withEmptyTemplate_returnsEmptyTemplate() async throws {
        // Given
        let emptyTemplate = BudgetTemplateDTO.mockSimple
        
        // Save empty template to database
        try await budgetRepository.upsertBudgetTemplate(emptyTemplate)
        
        // When
        let result = try await useCase.execute()
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.totalAmount, emptyTemplate.totalAmount)
        XCTAssertEqual(result?.categoryBudgetTemplates.count, 1)
    }
    
}

// MARK: - MockGetBudgetTemplateUseCaseTests

final class MockGetBudgetTemplateUseCaseTests: XCTestCase {
    
    // MARK: - Properties
    
    private var mockUseCase: MockGetBudgetTemplateUseCase!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockUseCase = MockGetBudgetTemplateUseCase()
    }
    
    override func tearDown() {
        mockUseCase = nil
        super.tearDown()
    }
    
    // MARK: - Test Methods
    
    func test_execute_withDefaultConfiguration_returnsTemplate() async throws {
        // Given - 기본 설정은 템플릿 있음
        
        // When
        let result = try await mockUseCase.execute()
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.totalAmount, Decimal(2_000_000))
        XCTAssertEqual(result?.categoryBudgetTemplates.count, 4)
    }
    
    func test_execute_withNoTemplateScenario_returnsNil() async throws {
        // Given
        mockUseCase.configureNoTemplateScenario()
        
        // When
        let result = try await mockUseCase.execute()
        
        // Then
        XCTAssertNil(result)
    }
    
    func test_execute_withCustomTemplate_returnsCustomTemplate() async throws {
        // Given
        let customTemplate = BudgetTemplateDTO.mockLarge
        mockUseCase.setMockTemplate(customTemplate)
        
        // When
        let result = try await mockUseCase.execute()
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.totalAmount, Decimal(3_000_000))
        XCTAssertEqual(result?.categoryBudgetTemplates.count, 4)
        XCTAssertTrue(result?.categoryBudgetTemplates.contains { $0.categoryName == "식비" } ?? false)
    }
    
    func test_setMockDelay_affectsExecutionTime() async throws {
        // Given
        let customDelay: UInt64 = 200_000_000 // 0.2초
        mockUseCase.setMockDelay(nanoseconds: customDelay)
        
        // When
        let startTime = Date()
        _ = try await mockUseCase.execute()
        let endTime = Date()
        
        // Then
        let executionTime = endTime.timeIntervalSince(startTime)
        XCTAssertGreaterThanOrEqual(executionTime, 0.15) // 최소 0.15초 (여유 고려)
    }
}
