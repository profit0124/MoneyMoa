//
//  CreateTransactionUseCaseTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 8/19/25.
//

import XCTest
@testable import MoneyMoa

// MARK: - MockCreateTransactionUseCaseTests

final class MockCreateTransactionUseCaseTests: XCTestCase {
    
    // MARK: - Properties
    
    private var mockUseCase: MockCreateTransactionUseCase!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockUseCase = MockCreateTransactionUseCase()
    }
    
    override func tearDown() {
        mockUseCase = nil
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
        try await mockUseCase.execute(transaction)
        
        // Then
        XCTAssertEqual(mockUseCase.createdTransactions.count, 1)
        XCTAssertEqual(mockUseCase.createdTransactions.first?.amount, 50000)
        XCTAssertEqual(mockUseCase.createdTransactions.first?.place, "스타벅스")
        XCTAssertEqual(mockUseCase.createdTransactions.first?.memo, "커피")
        XCTAssertEqual(mockUseCase.createdTransactions.first?.transactionType, .variableExpense)
        XCTAssertFalse(mockUseCase.createdTransactions.first?.isFavorite ?? true)
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
        try await mockUseCase.execute(transaction)
        
        // Then
        XCTAssertEqual(mockUseCase.createdTransactions.count, 1)
        XCTAssertEqual(mockUseCase.createdTransactions.first?.transactionType, .income)
        XCTAssertEqual(mockUseCase.createdTransactions.first?.amount, 2000000)
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
        try await mockUseCase.execute(transaction)
        
        // Then
        XCTAssertEqual(mockUseCase.createdTransactions.count, 1)
        XCTAssertEqual(mockUseCase.createdTransactions.first?.transactionType, .fixedExpense)
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
        try await mockUseCase.execute(transaction)
        
        // Then
        XCTAssertEqual(mockUseCase.createdTransactions.count, 1)
        XCTAssertTrue(mockUseCase.createdTransactions.first?.isFavorite ?? false)
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
            try await mockUseCase.execute(transaction)
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
            try await mockUseCase.execute(transaction)
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
        
        mockUseCase.shouldFail = true
        
        // When & Then
        do {
            try await mockUseCase.execute(transaction)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is TransactionCreationError)
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
        try await mockUseCase.execute(transaction1)
        try await mockUseCase.execute(transaction2)
        
        // Then
        XCTAssertEqual(mockUseCase.createdTransactions.count, 2)
        XCTAssertEqual(mockUseCase.createdTransactions[0].place, "카페")
        XCTAssertEqual(mockUseCase.createdTransactions[1].place, "마트")
    }
    
    // MARK: - Test Methods - Reset Functionality
    
    func test_reset_clearsCreatedTransactions() async throws {
        // Given
        let transaction = TransactionDTO(
            amount: 10000,
            place: "테스트",
            memo: "테스트",
            transactionType: .variableExpense,
            isFavorite: false,
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCreditCard
        )
        
        try await mockUseCase.execute(transaction)
        XCTAssertEqual(mockUseCase.createdTransactions.count, 1)
        
        // When
        mockUseCase.reset()
        
        // Then
        XCTAssertEqual(mockUseCase.createdTransactions.count, 0)
        XCTAssertFalse(mockUseCase.shouldFail)
    }
}
