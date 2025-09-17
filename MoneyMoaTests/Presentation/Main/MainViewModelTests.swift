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
                subCategory: SubCategoryDTO.mockFoodExpense,
                paymentMethod: PaymentMethodDTO.mockCreditCard
            ),
            TransactionDTO(
                amount: 25000,
                date: Calendar.current.date(byAdding: .day, value: 5, to: currentMonth.startOfMonth) ?? currentMonth.startOfMonth,
                place: "스타벅스",
                memo: "커피",
                transactionType: .variableExpense,
                subCategory: SubCategoryDTO.mockFoodExpense,
                paymentMethod: PaymentMethodDTO.mockCreditCard
            ),
            TransactionDTO(
                amount: 100000,
                date: currentMonth.startOfMonth,
                place: "회사",
                memo: "급여",
                transactionType: .income,
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
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초
        
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
    
    // MARK: - Test Methods - Budget Loading Scenarios
    
    func test_loadCurrentMonthBudget_withBudgetExists_setsBudget() async {
        // Given - Setup budget in mock repository
        let currentMonth = YearMonth.current
        let testBudget = BudgetDTO(
            id: UUID(),
            month: currentMonth,
            totalAmount: 1000000,
            categoryBudgets: []
        )
        mockDIContainer.mockBudgetRepository.addBudget(testBudget)
        
        // When
        viewModel.send(.loadTransactions)
        
        // Wait for all async operations
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초
        
        // Then
        XCTAssertNotNil(viewModel.summaryData)
        XCTAssertNotNil(viewModel.summaryData?.budget)
        XCTAssertEqual(viewModel.summaryData?.budget?.totalAmount, 1000000)
        XCTAssertFalse(viewModel.isSummaryLoading)
    }
    
    func test_loadCurrentMonthBudget_withNoBudget_setsNil() async {
        // Given - No budget exists (MockDIContainer empty scenario)
        mockDIContainer.mockBudgetRepository.clearData()
        
        // When
        viewModel.send(.loadTransactions)
        
        // Wait for all async operations
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초
        
        // Then
        XCTAssertNotNil(viewModel.summaryData)
        XCTAssertNil(viewModel.summaryData?.budget)
        XCTAssertFalse(viewModel.isSummaryLoading)
        XCTAssertTrue(viewModel.hasSummaryData)
    }
    
    func test_setBudget_withValidBudget_updatesSummary() async {
        // Given
        let testBudget = BudgetDTO(
            id: UUID(),
            month: YearMonth.current,
            totalAmount: 500000,
            categoryBudgets: []
        )
        
        // Setup transactions first
        viewModel.send(.loadTransactions)
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05초
        
        // When
        viewModel.send(.setBudget(testBudget))
        
        // Wait for summary update
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05초
        
        // Then
        XCTAssertNotNil(viewModel.summaryData)
        XCTAssertNotNil(viewModel.summaryData?.budget)
        XCTAssertEqual(viewModel.summaryData?.budget?.totalAmount, 500000)
    }
    
    func test_setBudget_withNilBudget_updatesSummary() async {
        // Given - Load transactions first
        viewModel.send(.loadTransactions)
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05초
        
        // When
        viewModel.send(.setBudget(nil))
        
        // Wait for summary update
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05초
        
        // Then
        XCTAssertNotNil(viewModel.summaryData)
        XCTAssertNil(viewModel.summaryData?.budget)
        XCTAssertNil(viewModel.summaryData?.remainingBudget)
        XCTAssertNil(viewModel.summaryData?.budgetUsagePercentage)
    }
    
    func test_budgetLoading_withRepositoryError_handlesGracefully() async {
        // Given - Configure budget repository to fail
        mockDIContainer.mockBudgetRepository.shouldFail = true
        
        // When
        viewModel.send(.loadTransactions)
        
        // Wait for all async operations
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초
        
        // Then - Should still complete with nil budget
        XCTAssertNotNil(viewModel.summaryData)
        XCTAssertNil(viewModel.summaryData?.budget)
        XCTAssertFalse(viewModel.isSummaryLoading)
    }
    
    // MARK: - Test Methods - Computed Properties
    
    func test_currentMonthTotalExpense_calculatesCorrectly() async {
        // Given
        viewModel.send(.loadTransactions)
        
        // Wait for async loading
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초
        
        // Then
        // Test data has 40,000 (15,000 + 25,000) in expenses for current month
        XCTAssertEqual(viewModel.currentMonthTotalExpense, 40000)
    }
    
    func test_currentMonthTotalIncome_calculatesCorrectly() async {
        // Given
        viewModel.send(.loadTransactions)
        
        // Wait for async loading
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초
        
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
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초
        
        // Then
        XCTAssertTrue(viewModel.hasSummaryData)
    }
    
    // MARK: - Test Methods - Basic Error Handling
    
    func test_loadTransactions_withRepositoryFailure_handlesErrorGracefully() async {
        // Given - Repository configured to fail
        mockDIContainer.mockTransactionRepository.shouldFail = true
        
        // When
        viewModel.send(.loadTransactions)
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초
        
        // Then - ViewModel should handle error gracefully
        XCTAssertFalse(viewModel.isLoading)
        // Should still complete summary flow
        XCTAssertNotNil(viewModel.summaryData)
    }
    
    // MARK: - Test Methods - Event Publisher Integration
    
    func test_transactionEventPublisher_receivesCurrentMonthEvents() async {
        // Given
        viewModel.send(.loadTransactions)
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05초
        
        // When - Simulate transaction event for current month
        let event = TransactionEvent(type: .created, yearMonth: YearMonth.current)
        mockTransactionEventPublisher.publish(event)
        
        // Wait for event processing
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05초
        
        // Then - Should trigger data reload
        XCTAssertEqual(mockTransactionEventPublisher.publishedEvents.count, 1)
        XCTAssertEqual(mockTransactionEventPublisher.publishedEvents.first?.type, .created)
    }
    
}
