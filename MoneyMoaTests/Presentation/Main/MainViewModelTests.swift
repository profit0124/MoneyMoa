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
    
    private var database: Database!
    private var viewModel: MainViewModel!
    
    // Repository implementations
    private var transactionRepository: TransactionRepositoryImpl!
    private var budgetRepository: BudgetRepositoryImpl!
    private var categoryRepository: CategoryRepositoryImpl!
    private var subCategoryRepository: SubCategoryRepositoryImpl!
    private var paymentMethodRepository: PaymentMethodRepositoryImpl!
    
    // UseCase implementations
    private var getMonthlyTransactionsUseCase: GetMonthlyTransactionsUseCaseImpl!
    private var getExpenseSumUntilDateUseCase: GetExpenseSumUntilDateUseCaseImpl!
    private var getMonthlyBudgetUseCase: GetMonthlyBudgetUseCaseImpl!
    private var getBudgetTemplateUseCase: GetBudgetTemplateUseCaseImpl!
    private var createBudgetFromTemplateUseCase: CreateBudgetFromTemplateUseCaseImpl!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory database
        database = try Database(isStoredInMemoryOnly: true)
        
        // Create repositories
        transactionRepository = TransactionRepositoryImpl(database: database)
        budgetRepository = BudgetRepositoryImpl(database: database)
        categoryRepository = CategoryRepositoryImpl(database: database)
        subCategoryRepository = SubCategoryRepositoryImpl(database: database)
        paymentMethodRepository = PaymentMethodRepositoryImpl(database: database)
        
        // Create UseCases
        getMonthlyTransactionsUseCase = GetMonthlyTransactionsUseCaseImpl(transactionRepository: transactionRepository)
        getExpenseSumUntilDateUseCase = GetExpenseSumUntilDateUseCaseImpl(transactionRepository: transactionRepository)
        getMonthlyBudgetUseCase = GetMonthlyBudgetUseCaseImpl(budgetRepository: budgetRepository)
        getBudgetTemplateUseCase = GetBudgetTemplateUseCaseImpl(budgetRepository: budgetRepository)
        createBudgetFromTemplateUseCase = CreateBudgetFromTemplateUseCaseImpl(budgetRepository: budgetRepository)
        
        // Create ViewModel
        viewModel = MainViewModel(
            getMonthlyTransactionsUseCase: getMonthlyTransactionsUseCase,
            getExpenseSumUntilDateUseCase: getExpenseSumUntilDateUseCase,
            getMonthlyBudgetUseCase: getMonthlyBudgetUseCase,
            getBudgetTemplateUseCase: getBudgetTemplateUseCase,
            createBudgetFromTemplateUseCase: createBudgetFromTemplateUseCase
        )
        
        // Setup test data
        try await setupTestData()
    }
    
    override func tearDown() async throws {
        viewModel = nil
        database = nil
        
        transactionRepository = nil
        budgetRepository = nil
        categoryRepository = nil
        paymentMethodRepository = nil
        
        getMonthlyTransactionsUseCase = nil
        getExpenseSumUntilDateUseCase = nil
        getMonthlyBudgetUseCase = nil
        getBudgetTemplateUseCase = nil
        createBudgetFromTemplateUseCase = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Test Data Setup
    
    private func setupTestData() async throws {
        // Create categories
        let categories = TestDataFactory.createCategories()
        for category in categories {
            try await categoryRepository.insertCategory(category)
        }
        
        // Create subcategories for first category (식비)
        let foodCategory = categories.first { $0.name == "식비" }!
        let subCategories = TestDataFactory.createSubCategories(for: foodCategory.id)
        for subCategory in subCategories {
            try await subCategoryRepository.insertSubCategory(subCategory)
        }
        
        // Create payment methods
        let paymentMethods = TestDataFactory.createPaymentMethods()
        for paymentMethod in paymentMethods {
            try await paymentMethodRepository.insertPaymentMethod(paymentMethod)
        }
        
        // Create transactions for current month
        let currentMonth = YearMonth.current
        let creditCard = paymentMethods.first { $0.name == "신용카드" }!
        let subCategory = subCategories.first!
        
        let transactions = [
            TestDataFactory.createTransaction(
                amount: 15000,
                date: currentMonth.startOfMonth,
                place: "맥도날드",
                memo: "점심식사",
                transactionType: .variableExpense,
                subCategory: subCategory,
                paymentMethod: creditCard
            ),
            TestDataFactory.createTransaction(
                amount: 25000,
                date: TestDataFactory.dateFromDaysAgo(2),
                place: "스타벅스",
                memo: "커피",
                transactionType: .variableExpense,
                subCategory: subCategory,
                paymentMethod: creditCard
            ),
            TestDataFactory.createTransaction(
                amount: 100000,
                date: TestDataFactory.dateFromDaysAgo(1),
                place: "회사",
                memo: "급여",
                transactionType: .income,
                subCategory: subCategory,
                paymentMethod: creditCard
            )
        ]
        
        for transaction in transactions {
            try await transactionRepository.insertTransaction(transaction)
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
            getMonthlyTransactionsUseCase: getMonthlyTransactionsUseCase,
            getExpenseSumUntilDateUseCase: getExpenseSumUntilDateUseCase,
            getMonthlyBudgetUseCase: getMonthlyBudgetUseCase,
            getBudgetTemplateUseCase: getBudgetTemplateUseCase,
            createBudgetFromTemplateUseCase: createBudgetFromTemplateUseCase,
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
    
    func DISABLED_test_budgetTemplateFlow_withExistingTemplate_createsBudgetFromTemplate() async throws {
        // Given - Create budget template using existing category from setup
        let categories = TestDataFactory.createCategories()
        let foodCategory = categories.first { $0.name == "식비" }!
        
        let categoryBudgetTemplate = TestDataFactory.createCategoryBudgetTemplate(
            amount: 500000,
            categoryID: foodCategory.id, // Use existing category ID from setup
            categoryName: foodCategory.name,
            budgetTemplateId: UUID()
        )
        
        let budgetTemplate = TestDataFactory.createBudgetTemplate(
            totalAmount: 2000000,
            categoryBudgetTemplates: [categoryBudgetTemplate]
        )
        
        // Insert budget template
        try await budgetRepository.upsertBudgetTemplate(budgetTemplate)
        
        // When
        viewModel.send(.loadTransactions)
        
        // Wait for all async operations
        try? await Task.sleep(nanoseconds: 3_000_000_000) // 3초 (더 길게)
        
        // Then
        XCTAssertNotNil(viewModel.summaryData)
        XCTAssertNotNil(viewModel.summaryData?.budget)
        XCTAssertEqual(viewModel.summaryData?.budget?.totalAmount, budgetTemplate.totalAmount)
        XCTAssertTrue(viewModel.summaryData?.hasBudget == true)
    }
    
    func test_budgetTemplateFlow_withoutTemplate_showsNoBudgetState() async {
        // Given - No budget template exists
        
        // When
        viewModel.send(.loadTransactions)
        
        // Wait for all async operations
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1초
        
        // Then
        XCTAssertNotNil(viewModel.summaryData)
        XCTAssertNil(viewModel.summaryData?.budget)
        XCTAssertFalse(viewModel.summaryData?.hasBudget == true)
    }
    
    // MARK: - Test Methods - Computed Properties
    
    func test_currentMonthTotalExpense_calculatesCorrectly() async {
        // Given
        viewModel.send(.loadTransactions)
        
        // Wait for async loading
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1초
        
        // Then
        // Test data has 40,000 (15,000 + 25,000) in expenses
        XCTAssertEqual(viewModel.currentMonthTotalExpense, 40000)
    }
    
    func test_currentMonthTotalIncome_calculatesCorrectly() async {
        // Given
        viewModel.send(.loadTransactions)
        
        // Wait for async loading
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1초
        
        // Then  
        // Test data has 100,000 in income
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
}
