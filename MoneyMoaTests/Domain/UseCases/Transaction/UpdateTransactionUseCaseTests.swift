//
//  UpdateTransactionUseCaseTests.swift
//  MoneyMoaTests
//
//  Created by profit on 8/20/25.
//

import XCTest
@testable import MoneyMoa

// MARK: - MockUpdateTransactionUseCaseTests

final class MockUpdateTransactionUseCaseTests: XCTestCase {
    
    // MARK: - Properties
    
    private var mockUseCase: MockUpdateTransactionUseCase!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockUseCase = MockUpdateTransactionUseCase()
    }
    
    override func tearDown() {
        mockUseCase = nil
        super.tearDown()
    }
    
    // MARK: - Test Methods - Successful Transaction Update
    
    func test_execute_withValidTransaction_updatesTransactionSuccessfully() async throws {
        // Given
        let transaction = TransactionDTO(
            amount: 75000,
            place: "스타벅스",
            memo: "커피 수정됨",
            transactionType: .variableExpense,
            isFavorite: false,
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCreditCard
        )
        
        // When
        try await mockUseCase.execute(transaction)
        
        // Then
        XCTAssertEqual(mockUseCase.updatedTransactions.count, 1)
        XCTAssertEqual(mockUseCase.updatedTransactions.first?.amount, 75000)
        XCTAssertEqual(mockUseCase.updatedTransactions.first?.place, "스타벅스")
        XCTAssertEqual(mockUseCase.updatedTransactions.first?.memo, "커피 수정됨")
        XCTAssertEqual(mockUseCase.updatedTransactions.first?.transactionType, .variableExpense)
        XCTAssertFalse(mockUseCase.updatedTransactions.first?.isFavorite ?? true)
    }
    
    func test_execute_withIncomeTransaction_updatesTransactionSuccessfully() async throws {
        // Given
        let transaction = TransactionDTO(
            amount: 2500000,
            place: "회사",
            memo: "월급 인상",
            transactionType: .income,
            isFavorite: false,
            subCategory: SubCategoryDTO.mockIncomeAllowance,
            paymentMethod: PaymentMethodDTO.mockCash
        )
        
        // When
        try await mockUseCase.execute(transaction)
        
        // Then
        XCTAssertEqual(mockUseCase.updatedTransactions.count, 1)
        XCTAssertEqual(mockUseCase.updatedTransactions.first?.transactionType, .income)
        XCTAssertEqual(mockUseCase.updatedTransactions.first?.amount, 2500000)
        XCTAssertEqual(mockUseCase.updatedTransactions.first?.memo, "월급 인상")
    }
    
    func test_execute_withFixedExpenseTransaction_updatesTransactionSuccessfully() async throws {
        // Given
        let transaction = TransactionDTO(
            amount: 350000,
            place: "통신사",
            memo: "휴대폰 요금 변경",
            transactionType: .fixedExpense,
            isFavorite: false,
            subCategory: SubCategoryDTO.mockTransportBus,
            paymentMethod: PaymentMethodDTO.mockCreditCard
        )
        
        // When
        try await mockUseCase.execute(transaction)
        
        // Then
        XCTAssertEqual(mockUseCase.updatedTransactions.count, 1)
        XCTAssertEqual(mockUseCase.updatedTransactions.first?.transactionType, .fixedExpense)
        XCTAssertEqual(mockUseCase.updatedTransactions.first?.amount, 350000)
    }
    
    func test_execute_withFavoriteStatusChange_updatesCorrectly() async throws {
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
        XCTAssertEqual(mockUseCase.updatedTransactions.count, 1)
        XCTAssertTrue(mockUseCase.updatedTransactions.first?.isFavorite ?? false)
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
            XCTAssertTrue(error is TransactionUpdateError)
            if case TransactionUpdateError.invalidAmount = error {
                // Expected error
            } else {
                XCTFail("Expected invalidAmount error")
            }
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
            XCTAssertTrue(error is TransactionUpdateError)
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
            XCTAssertTrue(error is TransactionUpdateError)
        }
    }
    
    func test_execute_withNotFoundConfiguration_throwsTransactionNotFoundError() async {
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
        
        mockUseCase.shouldFailWithNotFound = true
        
        // When & Then
        do {
            try await mockUseCase.execute(transaction)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is TransactionUpdateError)
            if case TransactionUpdateError.transactionNotFound = error {
                // Expected error
            } else {
                XCTFail("Expected transactionNotFound error")
            }
        }
    }
    
    // MARK: - Test Methods - Multiple Transactions
    
    func test_execute_multipleTransactions_storesAllUpdatedTransactions() async throws {
        // Given
        let transaction1 = TransactionDTO(
            amount: 12000,
            place: "카페",
            memo: "커피 수정",
            transactionType: .variableExpense,
            isFavorite: false,
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCreditCard
        )
        
        let transaction2 = TransactionDTO(
            amount: 60000,
            place: "마트",
            memo: "장보기 수정",
            transactionType: .variableExpense,
            isFavorite: true,
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCash
        )
        
        // When
        try await mockUseCase.execute(transaction1)
        try await mockUseCase.execute(transaction2)
        
        // Then
        XCTAssertEqual(mockUseCase.updatedTransactions.count, 2)
        XCTAssertEqual(mockUseCase.updatedTransactions[0].place, "카페")
        XCTAssertEqual(mockUseCase.updatedTransactions[1].place, "마트")
        XCTAssertFalse(mockUseCase.updatedTransactions[0].isFavorite)
        XCTAssertTrue(mockUseCase.updatedTransactions[1].isFavorite)
    }
    
    // MARK: - Test Methods - Reset Functionality
    
    func test_reset_clearsUpdatedTransactions() async throws {
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
        XCTAssertEqual(mockUseCase.updatedTransactions.count, 1)
        
        mockUseCase.shouldFail = true
        mockUseCase.shouldFailWithNotFound = true
        
        // When
        mockUseCase.reset()
        
        // Then
        XCTAssertEqual(mockUseCase.updatedTransactions.count, 0)
        XCTAssertFalse(mockUseCase.shouldFail)
        XCTAssertFalse(mockUseCase.shouldFailWithNotFound)
    }
}
