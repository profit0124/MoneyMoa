//
//  UpdateTransactionUseCaseTests.swift
//  MoneyMoaTests
//
//  Created by profit on 8/20/25.
//

import XCTest
@testable import MoneyMoa

final class UpdateTransactionUseCaseTests: XCTestCase {
    
    // MARK: - Properties
    
    private var mockRepository: MockTransactionRepository!
    private var useCase: UpdateTransactionUseCaseImpl!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockRepository = MockTransactionRepository(scenario: .empty)
        useCase = UpdateTransactionUseCaseImpl(transactionWriter: mockRepository)
    }
    
    override func tearDown() {
        mockRepository = nil
        useCase = nil
        super.tearDown()
    }
    
    // MARK: - Test Methods - Successful Update
    
    func test_execute_withValidTransaction_updatesSuccessfully() async throws {
        // Given
        let originalTransaction = TransactionFactory.sample()
        try await mockRepository.insertTransaction(originalTransaction)
        
        let updatedTransaction = TransactionDTO(
            id: originalTransaction.id,
            amount: 75000,  // Changed from original
            date: originalTransaction.date,
            place: "Updated Place",  // Changed from original
            memo: "Updated Memo",    // Changed from original
            transactionType: originalTransaction.transactionType,
            isFavorite: true,        // Changed from original
            subCategory: originalTransaction.subCategory,
            paymentMethod: originalTransaction.paymentMethod
        )
        
        // When
        try await useCase.execute(updatedTransaction)
        
        // Then
        let storedTransaction = try await mockRepository.fetchTransaction(id: originalTransaction.id)
        XCTAssertNotNil(storedTransaction)
        XCTAssertEqual(storedTransaction?.amount, 75000)
        XCTAssertEqual(storedTransaction?.place, "Updated Place")
        XCTAssertEqual(storedTransaction?.memo, "Updated Memo")
        XCTAssertTrue(storedTransaction?.isFavorite ?? false)
    }
    
    // MARK: - Test Methods - Error Cases
    
    func test_execute_withInvalidAmount_throwsError() async {
        // Given
        let transaction = TransactionDTO(
            amount: 0,  // Invalid amount
            place: "Test Place",
            memo: "Test Memo",
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
            XCTAssertTrue(error is TransactionUpdateError)
        }
    }
    
    func test_execute_withNegativeAmount_throwsError() async {
        // Given
        let transaction = TransactionDTO(
            amount: -1000,  // Negative amount
            place: "Test Place", 
            memo: "Test Memo",
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
            XCTAssertTrue(error is TransactionUpdateError)
        }
    }
    
    func test_execute_withRepositoryFailure_propagatesError() async {
        // Given
        let transaction = TransactionFactory.sample()
        mockRepository.shouldFail = true
        
        // When & Then
        do {
            try await useCase.execute(transaction)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is MockError)
        }
    }
    
    // MARK: - Test Methods - Business Logic Validation
    
    func test_execute_validatesBusinessRules() async throws {
        // Given
        let originalTransaction = TransactionFactory.sample()
        try await mockRepository.insertTransaction(originalTransaction)
        
        let validTransaction = TransactionDTO(
            id: originalTransaction.id,
            amount: 150000,  // Valid positive amount
            date: originalTransaction.date,
            place: "Business Rule Test",
            memo: "Testing business logic validation",
            transactionType: originalTransaction.transactionType,
            isFavorite: originalTransaction.isFavorite,
            subCategory: originalTransaction.subCategory,
            paymentMethod: originalTransaction.paymentMethod
        )
        
        // When
        try await useCase.execute(validTransaction)
        
        // Then
        let updatedTransaction = try await mockRepository.fetchTransaction(id: originalTransaction.id)
        XCTAssertNotNil(updatedTransaction, "실제 UseCase 비즈니스 로직이 실행되어 거래가 업데이트되어야 함")
        XCTAssertEqual(updatedTransaction?.amount, 150000, "금액 검증 로직이 올바르게 동작해야 함")
        XCTAssertEqual(updatedTransaction?.place, "Business Rule Test")
    }
}
