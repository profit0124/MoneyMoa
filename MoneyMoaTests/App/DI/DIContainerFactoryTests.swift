//
//  DIContainerFactoryTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 8/5/25.
//

import XCTest
@testable import MoneyMoa

// MARK: - DIContainerFactoryTests

final class DIContainerFactoryTests: XCTestCase {
    
    // MARK: - Test Methods
    
    func test_create_withMockType_returnsMockDIContainer() {
        // Given
        let containerType = DIContainerFactory.ContainerType.mock
        
        // When
        let container = DIContainerFactory.create(type: containerType)
        
        // Then
        XCTAssertTrue(container is MockDIContainer)
    }
    
    func test_create_withProductionType_andValidDatabase_returnsAppDIContainer() async throws {
        // Given
        let database = try Database(isStoredInMemoryOnly: true)
        let containerType = DIContainerFactory.ContainerType.production
        
        // When
        let container = DIContainerFactory.create(type: containerType, database: database)
        
        // Then
        XCTAssertTrue(container is AppDIContainer)
    }
    
    func test_createDefault_inDebugMode_returnsMockContainer() {
        // Given & When
        let container = DIContainerFactory.createDefault()
        
        // Then
        // DEBUG 모드에서는 항상 Mock Container 반환
        XCTAssertTrue(container is MockDIContainer)
    }
    
    func test_createForPreview_returnsMockContainer() {
        // Given & When
        let container = DIContainerFactory.createForPreview()
        
        // Then
        XCTAssertTrue(container is MockDIContainer)
    }
}

// MARK: - MockDIContainerTests

final class MockDIContainerTests: XCTestCase {
    
    // MARK: - Properties
    
    private var container: MockDIContainer!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        container = MockDIContainer()
    }
    
    override func tearDown() {
        container = nil
        super.tearDown()
    }
    
    // MARK: - Test Methods
    
    func test_makeMainViewModel_returnsValidMainViewModel() {
        // Given & When
        let viewModel = container.makeMainViewModel()
        
        // Then
        XCTAssertNotNil(viewModel)
        XCTAssertTrue(viewModel.currentYearMonth == YearMonth.current)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.isSummaryLoading) // initial value
    }
    
    func test_makeGetMonthlyTransactionsUseCase_returnsMockUseCase() {
        // Given & When
        let useCase = container.makeGetMonthlyTransactionsUseCase()
        
        // Then
        XCTAssertTrue(useCase is MockGetMonthlyTransactionsUseCase)
    }
    
    func test_makeGetExpenseSumUntilDateUseCase_returnsMockUseCase() {
        // Given & When
        let useCase = container.makeGetExpenseSumUntilDateUseCase()
        
        // Then
        XCTAssertTrue(useCase is MockGetExpenseSumUntilDateUseCase)
    }
    
    func test_makeGetMonthlyBudgetUseCase_returnsMockUseCase() {
        // Given & When
        let useCase = container.makeGetMonthlyBudgetUseCase()
        
        // Then
        XCTAssertTrue(useCase is MockGetMonthlyBudgetUseCase)
    }
    
    func test_makeGetBudgetTemplateUseCase_returnsMockUseCase() {
        // Given & When
        let useCase = container.makeGetBudgetTemplateUseCase()
        
        // Then
        XCTAssertTrue(useCase is MockGetBudgetTemplateUseCase)
    }
    
    func test_makeCreateBudgetFromTemplateUseCase_returnsMockUseCase() {
        // Given & When
        let useCase = container.makeCreateBudgetFromTemplateUseCase()
        
        // Then
        XCTAssertTrue(useCase is MockCreateBudgetFromTemplateUseCase)
    }
}
