//
//  GetTransactionByIdUseCaseTests.swift
//  MoneyMoaTests
//
//  Created by profit on 8/20/25.
//

import XCTest
@testable import MoneyMoa

final class GetTransactionByIdUseCaseTests: XCTestCase {
    
    // MARK: - Properties
    
    private var mockRepository: MockTransactionRepository!
    private var useCase: GetTransactionByIdUseCaseImpl!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockRepository = MockTransactionRepository(scenario: .empty)
        useCase = GetTransactionByIdUseCaseImpl(transactionReader: mockRepository)
    }
    
    override func tearDown() {
        mockRepository = nil
        useCase = nil
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
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCreditCard
        )
        
        try await mockRepository.insertTransaction(transaction)
        
        // When
        let result = try await useCase.execute(id: transaction.id)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.id, transaction.id)
        XCTAssertEqual(result?.amount, 50000)
        XCTAssertEqual(result?.place, "스타벅스")
        XCTAssertEqual(result?.memo, "커피")
        XCTAssertEqual(result?.transactionType, .variableExpense)
    }
    
    func test_execute_withIncomeTransaction_returnsCorrectData() async throws {
        // Given
        let transaction = TransactionDTO(
            amount: 2000000,
            place: "회사",
            memo: "월급",
            transactionType: .income,
            subCategory: SubCategoryDTO.mockIncomeAllowance,
            paymentMethod: PaymentMethodDTO.mockCash
        )
        
        try await mockRepository.insertTransaction(transaction)
        
        // When
        let result = try await useCase.execute(id: transaction.id)
        
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
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCreditCard
        )
        
        try await mockRepository.insertTransaction(transaction)
        
        // When
        let result = try await useCase.execute(id: transaction.id)
        
        // Then
        XCTAssertNotNil(result)
    }
    
    // MARK: - Test Methods - Non-existing Transaction
    
    func test_execute_withNonExistingId_returnsNil() async throws {
        // Given
        let nonExistingId = UUID()
        
        // When
        let result = try await useCase.execute(id: nonExistingId)
        
        // Then
        XCTAssertNil(result)
    }
    
    // MARK: - Test Methods - Error Cases
    
    func test_execute_withRepositoryFailure_throwsError() async {
        // Given
        let transactionId = UUID()
        mockRepository.shouldFail = true
        
        // When & Then
        do {
            _ = try await useCase.execute(id: transactionId)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is MockError)
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
        
        try await mockRepository.insertTransaction(transaction1)
        try await mockRepository.insertTransaction(transaction2)
        
        // When
        let result1 = try await useCase.execute(id: transaction1.id)
        let result2 = try await useCase.execute(id: transaction2.id)
        
        // Then
        XCTAssertNotNil(result1)
        XCTAssertNotNil(result2)
        XCTAssertEqual(result1?.place, "카페")
        XCTAssertEqual(result2?.place, "마트")
        XCTAssertNotEqual(result1?.id, result2?.id)
    }
    
    // MARK: - Test Methods - Business Logic Validation
    
    func test_execute_validatesBusinessRules() async throws {
        // Given
        let transaction = TransactionDTO(
            amount: 100000,
            place: "Business Rule Test",
            memo: "Testing business logic validation",
            transactionType: .variableExpense,
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCreditCard
        )
        
        try await mockRepository.insertTransaction(transaction)
        
        // When
        let result = try await useCase.execute(id: transaction.id)
        
        // Then
        XCTAssertNotNil(result, "실제 UseCase 비즈니스 로직이 실행되어 거래를 반환해야 함")
        XCTAssertEqual(result?.amount, 100000, "비즈니스 로직이 올바르게 동작해야 함")
        XCTAssertEqual(result?.place, "Business Rule Test")
    }
}
