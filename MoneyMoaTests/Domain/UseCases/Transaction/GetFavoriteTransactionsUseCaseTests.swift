//
//  GetFavoriteTransactionsUseCaseTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 8/19/25.
//

import XCTest
@testable import MoneyMoa

final class GetFavoriteTransactionsUseCaseTests: XCTestCase {
    
    // MARK: - Properties
    
    private var mockRepository: MockTransactionRepository!
    private var useCase: GetFavoriteTransactionsUseCaseImpl!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockRepository = MockTransactionRepository(scenario: .empty)
        useCase = GetFavoriteTransactionsUseCaseImpl(transactionReader: mockRepository)
    }
    
    override func tearDown() {
        mockRepository = nil
        useCase = nil
        super.tearDown()
    }
    
    // MARK: - Test Methods - Successful Execution
    
    func test_execute_withFavoriteTransactions_returnsFavoriteTransactionsOnly() async throws {
        // Given
        let favoriteTransaction = TransactionDTO(
            amount: 15000,
            place: "맥도날드",
            memo: "점심식사",
            transactionType: .variableExpense,
            isFavorite: true,
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCreditCard
        )
        
        let normalTransaction = TransactionDTO(
            amount: 5000,
            place: "카페",
            memo: "커피",
            transactionType: .variableExpense,
            isFavorite: false,
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCash
        )
        
        let anotherFavoriteTransaction = TransactionDTO(
            amount: 50000,
            place: "부모님",
            memo: "용돈",
            transactionType: .income,
            isFavorite: true,
            subCategory: SubCategoryDTO.mockIncomeAllowance,
            paymentMethod: PaymentMethodDTO.mockCash
        )
        
        try await mockRepository.insertTransaction(favoriteTransaction)
        try await mockRepository.insertTransaction(normalTransaction)
        try await mockRepository.insertTransaction(anotherFavoriteTransaction)
        
        // When
        let favoriteTransactions = try await useCase.execute()
        
        // Then
        XCTAssertEqual(favoriteTransactions.count, 2)
        XCTAssertTrue(favoriteTransactions.allSatisfy { $0.isFavorite })
        
        let transactionIds = Set(favoriteTransactions.map { $0.id })
        XCTAssertTrue(transactionIds.contains(favoriteTransaction.id))
        XCTAssertTrue(transactionIds.contains(anotherFavoriteTransaction.id))
        XCTAssertFalse(transactionIds.contains(normalTransaction.id))
    }
    
    func test_execute_withNoFavoriteTransactions_returnsEmptyArray() async throws {
        // Given
        let normalTransaction = TransactionDTO(
            amount: 5000,
            place: "카페",
            memo: "커피",
            transactionType: .variableExpense,
            isFavorite: false,
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCash
        )
        
        try await mockRepository.insertTransaction(normalTransaction)
        
        // When
        let favoriteTransactions = try await useCase.execute()
        
        // Then
        XCTAssertEqual(favoriteTransactions.count, 0)
    }
    
    func test_execute_returnsVariousTransactionTypes() async throws {
        // Given
        let favoriteExpense = TransactionDTO(
            amount: 15000,
            place: "맥도날드",
            memo: "점심식사",
            transactionType: .variableExpense,
            isFavorite: true,
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: SubCategoryDTO.mockFoodExpense.id == PaymentMethodDTO.mockCreditCard.id ? PaymentMethodDTO.mockCreditCard : PaymentMethodDTO.mockCash
        )
        
        let favoriteIncome = TransactionDTO(
            amount: 50000,
            place: "부모님",
            memo: "용돈",
            transactionType: .income,
            isFavorite: true,
            subCategory: SubCategoryDTO.mockIncomeAllowance,
            paymentMethod: PaymentMethodDTO.mockCash
        )
        
        let favoriteFixedExpense = TransactionDTO(
            amount: 100000,
            place: "전세",
            memo: "월세",
            transactionType: .fixedExpense,
            isFavorite: true,
            subCategory: SubCategoryDTO.mockFoodExpense, // Mock 카테고리 사용
            paymentMethod: PaymentMethodDTO.mockCash
        )
        
        try await mockRepository.insertTransaction(favoriteExpense)
        try await mockRepository.insertTransaction(favoriteIncome)
        try await mockRepository.insertTransaction(favoriteFixedExpense)
        
        // When
        let favoriteTransactions = try await useCase.execute()
        
        // Then
        XCTAssertEqual(favoriteTransactions.count, 3)
        let transactionTypes = Set(favoriteTransactions.map { $0.transactionType })
        XCTAssertTrue(transactionTypes.contains(.variableExpense))
        XCTAssertTrue(transactionTypes.contains(.income))
        XCTAssertTrue(transactionTypes.contains(.fixedExpense))
    }
    
    func test_execute_returnsDifferentPaymentMethods() async throws {
        // Given
        let favoriteWithCard = TransactionDTO(
            amount: 15000,
            place: "카드결제",
            memo: "카드",
            transactionType: .variableExpense,
            isFavorite: true,
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCreditCard
        )
        
        let favoriteWithCash = TransactionDTO(
            amount: 50000,
            place: "현금결제",
            memo: "현금",
            transactionType: .income,
            isFavorite: true,
            subCategory: SubCategoryDTO.mockIncomeAllowance,
            paymentMethod: PaymentMethodDTO.mockCash
        )
        
        try await mockRepository.insertTransaction(favoriteWithCard)
        try await mockRepository.insertTransaction(favoriteWithCash)
        
        // When
        let favoriteTransactions = try await useCase.execute()
        
        // Then
        XCTAssertEqual(favoriteTransactions.count, 2)
        let paymentMethods = favoriteTransactions.map { $0.paymentMethod }
        XCTAssertTrue(paymentMethods.contains(PaymentMethodDTO.mockCreditCard))
        XCTAssertTrue(paymentMethods.contains(PaymentMethodDTO.mockCash))
    }
    
    // MARK: - Test Methods - Error Cases
    
    func test_execute_withRepositoryFailure_throwsError() async {
        // Given
        mockRepository.shouldFail = true
        
        // When & Then
        do {
            _ = try await useCase.execute()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is MockError)
        }
    }
    
    // MARK: - Test Methods - Data Consistency
    
    func test_execute_multipleCallsReturnConsistentData() async throws {
        // Given
        let favoriteTransaction = TransactionDTO(
            amount: 15000,
            place: "맥도날드",
            memo: "점심식사",
            transactionType: .variableExpense,
            isFavorite: true,
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCreditCard
        )
        
        try await mockRepository.insertTransaction(favoriteTransaction)
        
        // When
        let firstCall = try await useCase.execute()
        let secondCall = try await useCase.execute()
        
        // Then
        XCTAssertEqual(firstCall.count, secondCall.count)
        XCTAssertEqual(firstCall.count, 1)
        XCTAssertEqual(firstCall[0].id, secondCall[0].id)
        XCTAssertEqual(firstCall[0].amount, secondCall[0].amount)
    }
    
    // MARK: - Test Methods - Business Logic Validation
    
    func test_execute_validatesBusinessRules() async throws {
        // Given
        let favoriteTransaction = TransactionDTO(
            amount: 100000,
            place: "Business Rule Test",
            memo: "Testing business logic validation",
            transactionType: .variableExpense,
            isFavorite: true,
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCreditCard
        )
        
        try await mockRepository.insertTransaction(favoriteTransaction)
        
        // When
        let result = try await useCase.execute()
        
        // Then
        XCTAssertEqual(result.count, 1, "실제 UseCase 비즈니스 로직이 실행되어 즐겨찾기 거래를 반환해야 함")
        XCTAssertTrue(result[0].isFavorite, "즐겨찾기 필터링 로직이 올바르게 동작해야 함")
        XCTAssertEqual(result[0].place, "Business Rule Test")
    }
}
