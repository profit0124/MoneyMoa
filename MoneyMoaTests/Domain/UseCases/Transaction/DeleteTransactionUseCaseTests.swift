//
//  DeleteTransactionUseCaseTests.swift
//  MoneyMoaTests
//
//  Created by profit on 8/20/25.
//

import XCTest
@testable import MoneyMoa

@MainActor
final class DeleteTransactionUseCaseTests: XCTestCase {
    
    private var mockUseCase: MockDeleteTransactionUseCase!
    
    override func setUp() {
        super.setUp()
        mockUseCase = MockDeleteTransactionUseCase()
    }
    
    override func tearDown() {
        mockUseCase = nil
        super.tearDown()
    }
    
    // MARK: - Success Cases
    
    func testExecute_WithValidTransactionId_DeletesSuccessfully() async throws {
        // Given
        let transactionId = UUID()
        mockUseCase.addExistingTransaction(id: transactionId)
        
        // When
        try await mockUseCase.execute(transactionId: transactionId)
        
        // Then
        XCTAssertTrue(mockUseCase.deletedTransactionIds.contains(transactionId))
        XCTAssertFalse(mockUseCase.existingTransactionIds.contains(transactionId))
    }
    
    func testExecute_WithMultipleTransactions_DeletesOnlySpecified() async throws {
        // Given
        let transactionId1 = UUID()
        let transactionId2 = UUID()
        let transactionId3 = UUID()
        
        mockUseCase.addExistingTransaction(id: transactionId1)
        mockUseCase.addExistingTransaction(id: transactionId2)
        mockUseCase.addExistingTransaction(id: transactionId3)
        
        // When
        try await mockUseCase.execute(transactionId: transactionId2)
        
        // Then
        XCTAssertEqual(mockUseCase.deletedTransactionIds.count, 1)
        XCTAssertTrue(mockUseCase.deletedTransactionIds.contains(transactionId2))
        XCTAssertTrue(mockUseCase.existingTransactionIds.contains(transactionId1))
        XCTAssertFalse(mockUseCase.existingTransactionIds.contains(transactionId2))
        XCTAssertTrue(mockUseCase.existingTransactionIds.contains(transactionId3))
    }
    
    // MARK: - Error Cases
    
    func testExecute_WithNonExistentTransactionId_ThrowsTransactionNotFound() async {
        // Given
        let nonExistentId = UUID()
        
        // When & Then
        do {
            try await mockUseCase.execute(transactionId: nonExistentId)
            XCTFail("Expected TransactionDeletionError.transactionNotFound")
        } catch let error as TransactionDeletionError {
            XCTAssertEqual(error, TransactionDeletionError.transactionNotFound)
        } catch {
            XCTFail("Expected TransactionDeletionError.transactionNotFound, but got \(error)")
        }
    }
    
    func testExecute_WhenForceFailure_ThrowsError() async {
        // Given
        let transactionId = UUID()
        mockUseCase.addExistingTransaction(id: transactionId)
        mockUseCase.shouldFail = true
        
        // When & Then
        do {
            try await mockUseCase.execute(transactionId: transactionId)
            XCTFail("Expected TransactionDeletionError.transactionNotFound")
        } catch let error as TransactionDeletionError {
            XCTAssertEqual(error, TransactionDeletionError.transactionNotFound)
        } catch {
            XCTFail("Expected TransactionDeletionError.transactionNotFound, but got \(error)")
        }
    }
    
    // MARK: - Mock State Tests
    
    func testMockReset_ClearsAllState() async throws {
        // Given
        let transactionId = UUID()
        mockUseCase.addExistingTransaction(id: transactionId)
        try await mockUseCase.execute(transactionId: transactionId)
        mockUseCase.shouldFail = true
        
        // When
        mockUseCase.reset()
        
        // Then
        XCTAssertTrue(mockUseCase.deletedTransactionIds.isEmpty)
        XCTAssertTrue(mockUseCase.existingTransactionIds.isEmpty)
        XCTAssertFalse(mockUseCase.shouldFail)
    }
    
    func testMockAddExistingTransaction_AddsToExistingSet() {
        // Given
        let transactionId1 = UUID()
        let transactionId2 = UUID()
        
        // When
        mockUseCase.addExistingTransaction(id: transactionId1)
        mockUseCase.addExistingTransaction(id: transactionId2)
        
        // Then
        XCTAssertTrue(mockUseCase.existingTransactionIds.contains(transactionId1))
        XCTAssertTrue(mockUseCase.existingTransactionIds.contains(transactionId2))
        XCTAssertEqual(mockUseCase.existingTransactionIds.count, 2)
    }
}
