//
//  CreateTransactionUseCaseTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 8/19/25.
//

import XCTest
@testable import MoneyMoa

// MARK: - CreateTransactionUseCaseTests

final class CreateTransactionUseCaseTests: XCTestCase {
    
    // MARK: - Properties

    private var mockRepository: MockTransactionRepository!
    private var mockTemplateRepository: MockTransactionTemplateRepository!
    private var useCase: CreateTransactionUseCaseImpl!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockRepository = MockTransactionRepository(scenario: .empty)
        mockTemplateRepository = MockTransactionTemplateRepository(scenario: .empty)
        useCase = CreateTransactionUseCaseImpl(
            transactionWriter: mockRepository,
            templateWriter: mockTemplateRepository
        )
    }
    
    override func tearDown() {
        mockRepository = nil
        mockTemplateRepository = nil
        useCase = nil
        super.tearDown()
    }
    
    // MARK: - Test Methods - Successful Transaction Creation
    
    func test_execute_withValidTransaction_createsTransactionSuccessfully() async throws {
        // Given
        let transaction = TransactionDTO(
            amount: 50000,
            place: "스타벅스",
            memo: "커피",
            transactionType: .variableExpense,
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCreditCard
        )
        
        // When
        try await useCase.execute(transaction)
        
        // Then
        let storedTransaction = try await mockRepository.fetchTransaction(id: transaction.id)
        XCTAssertNotNil(storedTransaction)
        XCTAssertEqual(storedTransaction?.amount, 50000)
        XCTAssertEqual(storedTransaction?.place, "스타벅스")
        XCTAssertEqual(storedTransaction?.memo, "커피")
        XCTAssertEqual(storedTransaction?.transactionType, .variableExpense)
    }
    
    func test_execute_withIncomeTransaction_createsTransactionSuccessfully() async throws {
        // Given
        let transaction = TransactionDTO(
            amount: 2000000,
            place: "회사",
            memo: "월급",
            transactionType: .income,
            subCategory: SubCategoryDTO.mockIncomeAllowance,
            paymentMethod: PaymentMethodDTO.mockCash
        )
        
        // When
        try await useCase.execute(transaction)
        
        // Then
        let storedTransaction = try await mockRepository.fetchTransaction(id: transaction.id)
        XCTAssertNotNil(storedTransaction)
        XCTAssertEqual(storedTransaction?.transactionType, .income)
        XCTAssertEqual(storedTransaction?.amount, 2000000)
    }
    
    func test_execute_withFixedExpenseTransaction_createsTransactionSuccessfully() async throws {
        // Given
        let transaction = TransactionDTO(
            amount: 300000,
            place: "통신사",
            memo: "휴대폰 요금",
            transactionType: .fixedExpense,
            subCategory: SubCategoryDTO.mockTransportBus,
            paymentMethod: PaymentMethodDTO.mockCreditCard
        )
        
        // When
        try await useCase.execute(transaction)
        
        // Then
        let storedTransaction = try await mockRepository.fetchTransaction(id: transaction.id)
        XCTAssertNotNil(storedTransaction)
        XCTAssertEqual(storedTransaction?.transactionType, .fixedExpense)
    }
    
    // MARK: - Template Creation Tests

    func test_execute_withRecurrencePeriod_createsTemplateAndTransaction() async throws {
        // Given
        let transaction = TransactionDTO(
            amount: 15000,
            place: "맥도날드",
            memo: "점심식사",
            transactionType: .variableExpense,
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCreditCard
        )

        // When
        try await useCase.execute(transaction, with: .weekly)

        // Then
        let storedTransaction = try await mockRepository.fetchTransaction(id: transaction.id)
        XCTAssertNotNil(storedTransaction)
        XCTAssertNotNil(storedTransaction?.transactionTemplate, "템플릿이 생성되고 거래에 연결되어야 함")

        // Template이 실제로 생성되었는지 확인
        let templates = try await mockTemplateRepository.fetchTemplates()
        XCTAssertEqual(templates.count, 1, "템플릿이 1개 생성되어야 함")
        XCTAssertEqual(templates.first?.recurrencePeriod, .weekly)
    }

    func test_execute_withMonthlyRecurrence_createsMonthlyTemplate() async throws {
        // Given
        let transaction = TransactionDTO(
            amount: 50000,
            place: "임대료",
            memo: "월세",
            transactionType: .fixedExpense,
            subCategory: SubCategoryDTO.mockTransportBus,
            paymentMethod: PaymentMethodDTO.mockCreditCard
        )

        // When
        try await useCase.execute(transaction, with: .monthly)

        // Then
        let templates = try await mockTemplateRepository.fetchTemplates()
        XCTAssertEqual(templates.count, 1)
        XCTAssertEqual(templates.first?.recurrencePeriod, .monthly)
        XCTAssertEqual(templates.first?.amount, 50000)
    }

    func test_execute_withoutRecurrencePeriod_doesNotCreateTemplate() async throws {
        // Given
        let transaction = TransactionDTO(
            amount: 5000,
            place: "일회성 구매",
            memo: "테스트",
            transactionType: .variableExpense,
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCash
        )

        // When
        try await useCase.execute(transaction, with: nil)

        // Then
        let storedTransaction = try await mockRepository.fetchTransaction(id: transaction.id)
        XCTAssertNotNil(storedTransaction)
        XCTAssertNil(storedTransaction?.transactionTemplate, "템플릿이 생성되지 않아야 함")

        let templates = try await mockTemplateRepository.fetchTemplates()
        XCTAssertEqual(templates.count, 0, "템플릿이 생성되지 않아야 함")
    }
    
    // MARK: - Test Methods - Error Cases
    
    func test_execute_withInvalidAmount_throwsError() async {
        // Given
        let transaction = TransactionDTO(
            amount: 0, // Invalid amount
            place: "테스트",
            memo: "테스트",
            transactionType: .variableExpense,
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCreditCard
        )
        
        // When & Then
        do {
            try await useCase.execute(transaction)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is TransactionCreationError)
        }
    }
    
    func test_execute_withNegativeAmount_throwsError() async {
        // Given
        let transaction = TransactionDTO(
            amount: -1000, // Negative amount
            place: "테스트",
            memo: "테스트",
            transactionType: .variableExpense,
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCreditCard
        )
        
        // When & Then
        do {
            try await useCase.execute(transaction)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is TransactionCreationError)
        }
    }
    
    func test_execute_withFailureConfiguration_throwsError() async {
        // Given
        let transaction = TransactionDTO(
            amount: 50000,
            place: "테스트",
            memo: "테스트",
            transactionType: .variableExpense,
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCreditCard
        )
        
        mockRepository.shouldFail = true
        
        // When & Then
        do {
            try await useCase.execute(transaction)
            XCTFail("Expected error to be thrown")
        } catch {
            // Repository failure should propagate
            XCTAssertTrue(error is MockError)
        }
    }
    
    // MARK: - Test Methods - Multiple Transactions
    
    func test_execute_multipleTransactions_storesAllTransactions() async throws {
        // Given
        let transaction1 = TransactionDTO(
            amount: 10000,
            place: "카페",
            memo: "커피",
            transactionType: .variableExpense,
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCreditCard
        )
        
        let transaction2 = TransactionDTO(
            amount: 50000,
            place: "마트",
            memo: "장보기",
            transactionType: .variableExpense,
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCash
        )
        
        // When
        try await useCase.execute(transaction1)
        try await useCase.execute(transaction2)
        
        // Then
        let storedTransaction1 = try await mockRepository.fetchTransaction(id: transaction1.id)
        let storedTransaction2 = try await mockRepository.fetchTransaction(id: transaction2.id)
        
        XCTAssertNotNil(storedTransaction1)
        XCTAssertNotNil(storedTransaction2)
        XCTAssertEqual(storedTransaction1?.place, "카페")
        XCTAssertEqual(storedTransaction2?.place, "마트")
    }
    
    // MARK: - Test Methods - Business Logic Validation

    func test_execute_validatesBusinessRules() async throws {
        // Given
        let transaction = TransactionDTO(
            amount: 100000,
            place: "비즈니스 로직 테스트",
            memo: "실제 UseCase 로직이 실행되는지 확인",
            transactionType: .variableExpense,
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCreditCard
        )

        // When
        try await useCase.execute(transaction)

        // Then
        let storedTransaction = try await mockRepository.fetchTransaction(id: transaction.id)
        XCTAssertNotNil(storedTransaction, "실제 UseCase 비즈니스 로직이 실행되어 거래가 저장되어야 함")
        XCTAssertEqual(storedTransaction?.amount, 100000, "금액 검증 로직이 올바르게 동작해야 함")
    }

    // MARK: - Atomicity Tests

    func test_execute_withTemplate_maintainsAtomicity() async throws {
        // Given
        let transaction = TransactionDTO(
            amount: 25000,
            place: "원자성 테스트",
            memo: "템플릿과 거래가 함께 저장되어야 함",
            transactionType: .variableExpense,
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCreditCard
        )

        // When
        try await useCase.execute(transaction, with: .weekly)

        // Then - 템플릿과 거래가 모두 저장되어야 함
        let storedTransaction = try await mockRepository.fetchTransaction(id: transaction.id)
        let templates = try await mockTemplateRepository.fetchTemplates()

        XCTAssertNotNil(storedTransaction, "거래가 저장되어야 함")
        XCTAssertEqual(templates.count, 1, "템플릿이 저장되어야 함")
        XCTAssertNotNil(storedTransaction?.transactionTemplate, "거래에 템플릿이 연결되어야 함")
        XCTAssertEqual(storedTransaction?.transactionTemplate?.id, templates.first?.id, "연결된 템플릿 ID가 일치해야 함")
    }

    func test_execute_templateCreationFailure_propagatesError() async {
        // Given
        let transaction = TransactionDTO(
            amount: 30000,
            place: "실패 테스트",
            memo: "템플릿 생성 실패 시 에러가 전파되어야 함",
            transactionType: .variableExpense,
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCreditCard
        )

        mockTemplateRepository.shouldFail = true

        // When & Then
        do {
            try await useCase.execute(transaction, with: .monthly)
            XCTFail("템플릿 생성 실패 시 에러가 발생해야 함")
        } catch {
            // Then - 템플릿 생성 실패 에러가 전파되어야 함
            XCTAssertTrue(error is MockError, "MockError가 전파되어야 함")
        }
    }
}
