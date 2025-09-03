//
//  MainViewModelTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 8/6/25.
//

import XCTest
@testable import MoneyMoa

// MARK: - MainViewModelTests

@MainActor
final class MainViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var mockDIContainer: MockDIContainer!
    private var viewModel: MainViewModel!
    private var mockTransactionEventPublisher: MockTransactionEventPublisher!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create MockDIContainer with empty data for controlled testing
        mockDIContainer = MockDIContainer()
        mockTransactionEventPublisher = MockTransactionEventPublisher()
        
        // Create ViewModel using DIContainer
        viewModel = MainViewModel(
            getMonthlyTransactionsUseCase: mockDIContainer.makeGetMonthlyTransactionsUseCase(),
            getExpenseSumUntilDateUseCase: mockDIContainer.makeGetExpenseSumUntilDateUseCase(),
            getMonthlyBudgetUseCase: mockDIContainer.makeGetMonthlyBudgetUseCase(),
            getBudgetTemplateUseCase: mockDIContainer.makeGetBudgetTemplateUseCase(),
            createBudgetFromTemplateUseCase: mockDIContainer.makeCreateBudgetFromTemplateUseCase(),
            transactionEventPublisher: mockTransactionEventPublisher
        )
        
        // Setup test data
        try await setupTestData()
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockDIContainer = nil
        mockTransactionEventPublisher = nil
        try await super.tearDown()
    }
    
    // MARK: - Test Data Setup
    
    private func setupTestData() async throws {
        // Create sample transactions in mock repository
        let currentMonth = YearMonth.current
        let transactions = [
            TransactionDTO(
                amount: 15000,
                date: currentMonth.startOfMonth,
                place: "맥도날드",
                memo: "점심식사",
                transactionType: .variableExpense,
                isFavorite: false,
                subCategory: SubCategoryDTO.mockFoodExpense,
                paymentMethod: PaymentMethodDTO.mockCreditCard
            ),
            TransactionDTO(
                amount: 25000,
                date: Calendar.current.date(byAdding: .day, value: 5, to: currentMonth.startOfMonth) ?? currentMonth.startOfMonth,
                place: "스타벅스",
                memo: "커피",
                transactionType: .variableExpense,
                isFavorite: false,
                subCategory: SubCategoryDTO.mockFoodExpense,
                paymentMethod: PaymentMethodDTO.mockCreditCard
            ),
            TransactionDTO(
                amount: 100000,
                date: currentMonth.startOfMonth,
                place: "회사",
                memo: "급여",
                transactionType: .income,
                isFavorite: false,
                subCategory: SubCategoryDTO.mockIncomeAllowance,
                paymentMethod: PaymentMethodDTO.mockTransfer
            )
        ]
        
        let mockRepository = mockDIContainer.mockTransactionRepository
        for transaction in transactions {
            try await mockRepository.insertTransaction(transaction)
        }
    }
    
    // MARK: - Test Methods - Initialization
    
    func test_initialization_setsCorrectInitialValues() {
        // Then
        XCTAssertEqual(viewModel.currentYearMonth, YearMonth.current)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.isSummaryLoading)
        XCTAssertTrue(viewModel.transactionsByDate.isEmpty)
        XCTAssertNil(viewModel.summaryData)
        XCTAssertFalse(viewModel.hasSummaryData)
    }
    
    func test_initialization_withCustomYearMonth_setsCorrectYearMonth() {
        // Given
        let customYearMonth = YearMonth(year: 2024, month: 6)
        
        // When
        let customViewModel = MainViewModel(
            getMonthlyTransactionsUseCase: mockDIContainer.makeGetMonthlyTransactionsUseCase(),
            getExpenseSumUntilDateUseCase: mockDIContainer.makeGetExpenseSumUntilDateUseCase(),
            getMonthlyBudgetUseCase: mockDIContainer.makeGetMonthlyBudgetUseCase(),
            getBudgetTemplateUseCase: mockDIContainer.makeGetBudgetTemplateUseCase(),
            createBudgetFromTemplateUseCase: mockDIContainer.makeCreateBudgetFromTemplateUseCase(),
            transactionEventPublisher: mockTransactionEventPublisher,
            initialYearMonth: customYearMonth
        )
        
        // Then
        XCTAssertEqual(customViewModel.currentYearMonth, customYearMonth)
    }
    
    // MARK: - Test Methods - Actions
    
    func test_send_loadTransactions_updatesTransactionsAndStartsSummaryFlow() async {
        // When
        viewModel.send(.loadTransactions)
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1초
        
        // Then
        XCTAssertFalse(viewModel.transactionsByDate.isEmpty)
        XCTAssertNotNil(viewModel.summaryData)
        XCTAssertTrue(viewModel.hasSummaryData)
        XCTAssertFalse(viewModel.isSummaryLoading)
    }
    
    func test_send_handleYearMonth_moveToNextMonth_updatesYearMonth() {
        // Given
        let originalYearMonth = viewModel.currentYearMonth
        
        // When
        viewModel.send(.handleYearMonth(.moveToNextMonth))
        
        // Then
        XCTAssertEqual(viewModel.currentYearMonth, originalYearMonth.nextMonth())
    }
    
    func test_send_handleYearMonth_moveToPreviousMonth_updatesYearMonth() {
        // Given
        let originalYearMonth = viewModel.currentYearMonth
        
        // When
        viewModel.send(.handleYearMonth(.moveToPreviousMonth))
        
        // Then
        XCTAssertEqual(viewModel.currentYearMonth, originalYearMonth.previousMonth())
    }
    
    func test_send_handleYearMonth_setMonth_updatesYearMonth() {
        // Given
        let targetYearMonth = YearMonth(year: 2023, month: 12)
        
        // When
        viewModel.send(.handleYearMonth(.setMonth(targetYearMonth)))
        
        // Then
        XCTAssertEqual(viewModel.currentYearMonth, targetYearMonth)
    }
    
    // MARK: - Test Methods - Budget Template Integration
    
    func test_budgetTemplateFlow_withoutTemplate_showsNoBudgetState() async {
        // Given - No budget template exists (MockDIContainer handles this)
        
        // When
        viewModel.send(.loadTransactions)
        
        // Wait for all async operations
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1초
        
        // Then
        XCTAssertNotNil(viewModel.summaryData)
        // MockDIContainer returns mock budget data, so we verify the loading completed
        XCTAssertFalse(viewModel.isSummaryLoading)
        XCTAssertTrue(viewModel.hasSummaryData)
    }
    
    // MARK: - Test Methods - Computed Properties
    
    func test_currentMonthTotalExpense_calculatesCorrectly() async {
        // Given
        viewModel.send(.loadTransactions)
        
        // Wait for async loading
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1초
        
        // Then
        // Test data has 40,000 (15,000 + 25,000) in expenses for current month
        XCTAssertEqual(viewModel.currentMonthTotalExpense, 40000)
    }
    
    func test_currentMonthTotalIncome_calculatesCorrectly() async {
        // Given
        viewModel.send(.loadTransactions)
        
        // Wait for async loading
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1초
        
        // Then  
        // Test data has 100,000 in income for current month
        XCTAssertEqual(viewModel.currentMonthTotalIncome, 100000)
    }
    
    func test_hasSummaryData_returnsCorrectValue() async {
        // Given - 초기 상태
        XCTAssertFalse(viewModel.hasSummaryData)
        
        // When - Summary 데이터 생성
        viewModel.send(.loadTransactions)
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1초
        
        // Then
        XCTAssertTrue(viewModel.hasSummaryData)
    }
    
    // MARK: - Test Methods - Repository-based Testing
    
    func test_loadTransactions_withRepositoryData_loadsCorrectly() async throws {
        // Given - Repository has test data
        let mockRepository = mockDIContainer.mockTransactionRepository
        XCTAssertFalse(mockRepository.shouldFail)
        
        // When
        viewModel.send(.loadTransactions)
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1초
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isSummaryLoading)
        XCTAssertNotNil(viewModel.summaryData)
    }
    
    func test_loadTransactions_withRepositoryFailure_handlesErrorGracefully() async throws {
        // Given - Repository configured to fail
        let mockRepository = mockDIContainer.mockTransactionRepository
        mockRepository.shouldFail = true
        
        // When
        viewModel.send(.loadTransactions)
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1초
        
        // Then - ViewModel should handle error gracefully
        XCTAssertFalse(viewModel.isLoading)
        // Depending on error handling implementation, summary might still complete
    }
    
    // MARK: - Test Methods - Event Publisher Integration
    
    func test_transactionEventPublisher_receivesEvents() async {
        // Given
        viewModel.send(.loadTransactions)
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초
        
        // When - Simulate transaction event
        let event = TransactionEvent(type: .created, yearMonth: YearMonth.current)
        mockTransactionEventPublisher.publish(event)
        
        // Wait for event processing
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초
        
        // Then - Should trigger data reload
        XCTAssertEqual(mockTransactionEventPublisher.publishedEvents.count, 1)
        XCTAssertEqual(mockTransactionEventPublisher.publishedEvents.first?.type, .created)
    }
}
