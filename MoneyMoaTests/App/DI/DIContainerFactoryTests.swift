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
        XCTAssertTrue(useCase is GetMonthlyTransactionsUseCaseImpl)
    }
    
    func test_makeGetExpenseSumUntilDateUseCase_returnsMockUseCase() {
        // Given & When
        let useCase = container.makeGetExpenseSumUntilDateUseCase()
        
        // Then
        XCTAssertTrue(useCase is GetExpenseSumUntilDateUseCaseImpl)
    }
    
    // MARK: - Test Methods - TransactionForm ViewModels
    
    func test_makeAmountPlacePaymentMethodFormViewModel_returnsValidViewModel() {
        // Given & When
        let viewModel = container.makeAmountPlacePaymentMethodFormViewModel()
        
        // Then
        XCTAssertNotNil(viewModel)
        XCTAssertNil(viewModel.amount)
        XCTAssertEqual(viewModel.place, "")
        XCTAssertNil(viewModel.selectedPaymentMethod)
        XCTAssertTrue(viewModel.paymentMethodOptions.isEmpty)
    }
    
    func test_makeTransactionTypeCategoryFormViewModel_returnsValidViewModel() {
        // Given & When
        let viewModel = container.makeTransactionTypeCategoryFormViewModel()
        
        // Then
        XCTAssertNotNil(viewModel)
        XCTAssertEqual(viewModel.selectedTransactionType, .variableExpense)
        XCTAssertNil(viewModel.selectedSubCategory)
        XCTAssertNotNil(viewModel.categoryListViewModel)
    }
    
    func test_makeDateAdditionalFormViewModel_returnsValidViewModel() {
        // Given & When
        let viewModel = container.makeDateAdditionalFormViewModel()
        
        // Then
        XCTAssertNotNil(viewModel)
        XCTAssertEqual(viewModel.memo, "")
        XCTAssertFalse(viewModel.isFavorite)
        
        // selectedDate는 현재 날짜와 거의 같아야 함
        let currentDate = Date()
        let timeDifference = abs(viewModel.selectedDate.timeIntervalSince(currentDate))
        XCTAssertLessThan(timeDifference, 5.0)
    }
    
    // MARK: - Test Methods - Transaction ViewModels
    
    func test_makeAddTransactionViewModel_returnsValidViewModel() {
        // Given & When
        let viewModel = container.makeAddTransactionViewModel()
        
        // Then
        XCTAssertNotNil(viewModel)
        XCTAssertEqual(viewModel.currentStep, .amountPlacePaymentMethod)
        XCTAssertTrue(viewModel.filteredCompletedStep.isEmpty)
        XCTAssertFalse(viewModel.isValid)
        XCTAssertNotNil(viewModel.amountPlacePaymentViewModel)
        XCTAssertNotNil(viewModel.transactionTypeSelectionViewModel)
        XCTAssertNotNil(viewModel.dateAdditionalFormViewModel)
    }
    
    // MARK: - Test Methods - Transaction UseCases
    
    func test_makeCreateTransactionUseCase_returnsMockUseCase() {
        // Given & When
        let useCase = container.makeCreateTransactionUseCase()
        
        // Then
        XCTAssertTrue(useCase is CreateTransactionUseCaseImpl)
    }
    
    func test_makeGetFavoriteTransactionsUseCase_returnsMockUseCase() {
        // Given & When
        let useCase = container.makeGetFavoriteTransactionsUseCase()
        
        // Then
        XCTAssertTrue(useCase is GetFavoriteTransactionsUseCaseImpl)
    }
    
    // MARK: - Test Methods - TransactionEventPublisher
    
    func test_makeTransactionEventPublisher_returnsValidPublisher() {
        // Given & When
        let publisher = container.makeTransactionEventPublisher()
        
        // Then
        XCTAssertNotNil(publisher)
        XCTAssertTrue(publisher is DefaultTransactionEventPublisher)
    }
    
    // MARK: - Test Methods - PaymentMethod UseCases
    
    func test_makeGetActivePaymentMethodsUseCase_returnsValidUseCase() {
        // Given & When
        let useCase = container.makeGetActivePaymentMethodsUseCase()
        
        // Then
        XCTAssertNotNil(useCase)
        XCTAssertTrue(useCase is GetActivePaymentMethodsUseCaseImpl)
    }
    
    func test_makeCreatePaymentMethodUseCase_returnsValidUseCase() {
        // Given & When
        let useCase = container.makeCreatePaymentMethodUseCase()
        
        // Then
        XCTAssertNotNil(useCase)
        XCTAssertTrue(useCase is CreatePaymentMethodUseCaseImpl)
    }
    
    func test_mockPaymentMethodRepository_isAccessible() {
        // Given & When
        let mockRepository = container.mockPaymentMethodRepository
        
        // Then
        XCTAssertNotNil(mockRepository)    }
    
    func test_mockPaymentMethodRepository_hasNormalScenario() async throws {
        // Given
        let mockRepository = container.mockPaymentMethodRepository
        
        // When
        let paymentMethods = try await mockRepository.fetchPaymentMethods()
        
        // Then
        XCTAssertGreaterThan(paymentMethods.count, 0)
    }
    
    func test_paymentMethodUseCases_shareSameRepository() async throws {
        // Given
        let getActiveUseCase = container.makeGetActivePaymentMethodsUseCase()
        let createUseCase = container.makeCreatePaymentMethodUseCase()
        
        // When: Create a new payment method
        let newPaymentMethod = PaymentMethodFactory.create(
            name: "테스트카드",
            kind: .credit
        )
        try await createUseCase.execute(newPaymentMethod)
        
        // Then: Should be available through get use case
        let activePaymentMethods = try await getActiveUseCase.execute()
        XCTAssertTrue(activePaymentMethods.contains { $0.name == "테스트카드" })
    }
}
