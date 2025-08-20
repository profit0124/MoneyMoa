//
//  GetTransactionByIdUseCaseTests.swift
//  MoneyMoaTests
//
//  Created by profit on 8/20/25.
//

import XCTest
@testable import MoneyMoa

// MARK: - MockGetTransactionByIdUseCaseTests

final class MockGetTransactionByIdUseCaseTests: XCTestCase {
    
    // MARK: - Properties
    
    private var mockUseCase: MockGetTransactionByIdUseCase!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockUseCase = MockGetTransactionByIdUseCase()
    }
    
    override func tearDown() {
        mockUseCase = nil
        super.tearDown()
    }
    
    // MARK: - Test Methods - Successful Transaction Retrieval
    
    func test_execute_withExistingId_returnsTransaction() async throws {
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
        
        mockUseCase.setMockTransaction(transaction)
        
        // When
        let result = try await mockUseCase.execute(id: transaction.id)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.id, transaction.id)
        XCTAssertEqual(result?.amount, 50000)
        XCTAssertEqual(result?.place, "스타벅스")
        XCTAssertEqual(result?.memo, "커피")
        XCTAssertEqual(result?.transactionType, .variableExpense)
        XCTAssertFalse(result?.isFavorite ?? true)
    }
    
    func test_execute_withIncomeTransaction_returnsCorrectData() async throws {
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
        
        mockUseCase.setMockTransaction(transaction)
        
        // When
        let result = try await mockUseCase.execute(id: transaction.id)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.transactionType, .income)
        XCTAssertEqual(result?.amount, 2000000)
        XCTAssertEqual(result?.place, "회사")
    }
    
    func test_execute_withFavoriteTransaction_returnsCorrectFavoriteStatus() async throws {
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
        
        mockUseCase.setMockTransaction(transaction)
        
        // When
        let result = try await mockUseCase.execute(id: transaction.id)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertTrue(result?.isFavorite ?? false)
    }
    
    // MARK: - Test Methods - Non-existing Transaction
    
    func test_execute_withNonExistingId_returnsNil() async throws {
        // Given
        let nonExistingId = UUID()
        
        // When
        let result = try await mockUseCase.execute(id: nonExistingId)
        
        // Then
        XCTAssertNil(result)
    }
    
    // MARK: - Test Methods - Error Cases
    
    func test_execute_withFailureConfiguration_throwsError() async {
        // Given
        let transactionId = UUID()
        mockUseCase.shouldFail = true
        
        // When & Then
        do {
            _ = try await mockUseCase.execute(id: transactionId)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is GetTransactionByIdError)
        }
    }
    
    // MARK: - Test Methods - Multiple Transactions
    
    func test_execute_withMultipleTransactions_returnsCorrectTransaction() async throws {
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
        
        mockUseCase.setMockTransaction(transaction1)
        mockUseCase.setMockTransaction(transaction2)
        
        // When
        let result1 = try await mockUseCase.execute(id: transaction1.id)
        let result2 = try await mockUseCase.execute(id: transaction2.id)
        
        // Then
        XCTAssertNotNil(result1)
        XCTAssertNotNil(result2)
        XCTAssertEqual(result1?.place, "카페")
        XCTAssertEqual(result2?.place, "마트")
        XCTAssertNotEqual(result1?.id, result2?.id)
    }
    
    // MARK: - Test Methods - Reset Functionality
    
    func test_reset_clearsStoredTransactions() async throws {
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
        
        mockUseCase.setMockTransaction(transaction)
        let resultBefore = try await mockUseCase.execute(id: transaction.id)
        XCTAssertNotNil(resultBefore)
        
        // When
        mockUseCase.reset()
        
        // Then
        let resultAfter = try await mockUseCase.execute(id: transaction.id)
        XCTAssertNil(resultAfter)
        XCTAssertFalse(mockUseCase.shouldFail)
    }
}
