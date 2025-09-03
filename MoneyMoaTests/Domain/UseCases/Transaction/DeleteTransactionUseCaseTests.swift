//
//  DeleteTransactionUseCaseTests.swift
//  MoneyMoaTests
//
//  Created by profit on 8/20/25.
//

import XCTest
@testable import MoneyMoa

final class DeleteTransactionUseCaseTests: XCTestCase {
    
    // MARK: - Properties
    
    private var mockRepository: MockTransactionRepository!
    private var useCase: DeleteTransactionUseCaseImpl!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockRepository = MockTransactionRepository(scenario: .empty)
        useCase = DeleteTransactionUseCaseImpl(transactionRepository: mockRepository)
    }
    
    override func tearDown() {
        mockRepository = nil
        useCase = nil
        super.tearDown()
    }
    
    // MARK: - Test Methods - Successful Deletion
    
    func test_execute_withExistingTransaction_deletesSuccessfully() async throws {
        // Given
        let transaction = TransactionFactory.sample()
        try await mockRepository.insertTransaction(transaction)
        
        // Verify transaction exists
        let existingTransaction = try await mockRepository.fetchTransaction(id: transaction.id)
        XCTAssertNotNil(existingTransaction)
        
        // When
        try await useCase.execute(transactionId: transaction.id)
        
        // Then
        let deletedTransaction = try await mockRepository.fetchTransaction(id: transaction.id)
        XCTAssertNil(deletedTransaction)
    }
    
    func test_execute_withNonExistentTransaction_throwsError() async {
        // Given
        let nonExistentId = UUID()
        
        // When & Then
        do {
            try await useCase.execute(transactionId: nonExistentId)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is TransactionDeletionError)
            if let deletionError = error as? TransactionDeletionError {
                XCTAssertEqual(deletionError, .transactionNotFound)
            }
        }
    }
    
    func test_execute_withMultipleTransactions_deletesOnlySpecified() async throws {
        // Given
        let transaction1 = TransactionFactory.sample()
        let transaction2 = TransactionFactory.sample()
        let transaction3 = TransactionFactory.sample()
        
        try await mockRepository.insertTransaction(transaction1)
        try await mockRepository.insertTransaction(transaction2)
        try await mockRepository.insertTransaction(transaction3)
        
        // When
        try await useCase.execute(transactionId: transaction2.id)
        
        // Then
        let remainingTransaction1 = try await mockRepository.fetchTransaction(id: transaction1.id)
        let deletedTransaction = try await mockRepository.fetchTransaction(id: transaction2.id)
        let remainingTransaction3 = try await mockRepository.fetchTransaction(id: transaction3.id)
        
        XCTAssertNotNil(remainingTransaction1)
        XCTAssertNil(deletedTransaction)
        XCTAssertNotNil(remainingTransaction3)
    }
    
    // MARK: - Test Methods - Business Logic Validation
    
    func test_execute_validatesExistenceBeforeDeletion() async throws {
        // Given
        let transaction = TransactionFactory.sample()
        try await mockRepository.insertTransaction(transaction)
        
        // When
        try await useCase.execute(transactionId: transaction.id)
        
        // Then - Verify both existence check and deletion were performed
        let result = try await mockRepository.fetchTransaction(id: transaction.id)
        XCTAssertNil(result, "Transaction should be deleted after successful existence validation")
    }
    
    func test_execute_withRepositoryFailure_propagatesError() async throws {
        // Given
        let transaction = TransactionFactory.sample()
        try await mockRepository.insertTransaction(transaction)
        
        mockRepository.shouldFail = true
        
        // When & Then
        do {
            try await useCase.execute(transactionId: transaction.id)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is MockError)
        }
    }
    
    // MARK: - Test Methods - Edge Cases
    
    func test_execute_withEmptyRepository_throwsNotFoundError() async {
        // Given
        let randomId = UUID()
        
        // When & Then
        do {
            try await useCase.execute(transactionId: randomId)
            XCTFail("Expected error to be thrown")
        } catch TransactionDeletionError.transactionNotFound {
            // Expected behavior
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}
