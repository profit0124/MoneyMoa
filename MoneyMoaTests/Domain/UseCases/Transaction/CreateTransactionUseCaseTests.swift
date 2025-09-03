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
    private var useCase: CreateTransactionUseCaseImpl!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockRepository = MockTransactionRepository(scenario: .empty)
        useCase = CreateTransactionUseCaseImpl(transactionWriter: mockRepository)
    }
    
    override func tearDown() {
        mockRepository = nil
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
            isFavorite: false,
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
        XCTAssertFalse(storedTransaction?.isFavorite ?? true)
    }
    
    func test_execute_withIncomeTransaction_createsTransactionSuccessfully() async throws {
        // Given
        let transaction = TransactionDTO(
            amount: 2000000,
            place: "회사",
            memo: "월급",
            transactionType: .income,
            isFavorite: false,
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
            isFavorite: false,
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
    
    func test_execute_withFavoriteTransaction_createsFavoriteSuccessfully() async throws {
        // Given
        let transaction = TransactionDTO(
            amount: 15000,
            place: "맥도날드",
            memo: "점심식사",
            transactionType: .variableExpense,
            isFavorite: true,
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCreditCard
        )
        
        // When
        try await useCase.execute(transaction)
        
        // Then
        let storedTransaction = try await mockRepository.fetchTransaction(id: transaction.id)
        XCTAssertNotNil(storedTransaction)
        XCTAssertTrue(storedTransaction?.isFavorite ?? false)
    }
    
    // MARK: - Test Methods - Error Cases
    
    func test_execute_withInvalidAmount_throwsError() async {
        // Given
        let transaction = TransactionDTO(
            amount: 0, // Invalid amount
            place: "테스트",
            memo: "테스트",
            transactionType: .variableExpense,
            isFavorite: false,
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
            isFavorite: false,
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
            isFavorite: false,
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
            isFavorite: false,
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCreditCard
        )
        
        let transaction2 = TransactionDTO(
            amount: 50000,
            place: "마트",
            memo: "장보기",
            transactionType: .variableExpense,
            isFavorite: false,
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
            isFavorite: false,
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
}
