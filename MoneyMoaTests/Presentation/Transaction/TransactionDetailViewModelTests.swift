//
//  TransactionDetailViewModelTests.swift
//  MoneyMoaTests
//
//  Created by profit on 8/20/25.
//

import XCTest
@testable import MoneyMoa

@MainActor
final class TransactionDetailViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var viewModel: TransactionDetailViewModel!
    private var mockDIContainer: MockDIContainer!
    private var mockTransactionEventPublisher: MockTransactionEventPublisher!
    private var sampleTransaction: TransactionDTO!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        mockDIContainer = MockDIContainer()
        mockTransactionEventPublisher = MockTransactionEventPublisher()
        sampleTransaction = TransactionDTO.mockLunch
        
        // Create ViewModel with Repository-based dependencies
        viewModel = TransactionDetailViewModel(
            transaction: sampleTransaction,
            deleteTransactionUseCase: mockDIContainer.makeDeleteTransactionUseCase(),
            getTransactionByIdUseCase: mockDIContainer.makeGetTransactionByIdUseCase(),
            transactionEventPublisher: mockTransactionEventPublisher,
            updateTransactionViewModel: mockDIContainer.makeUpdateTransactionViewModel(transaction: sampleTransaction)
        )
        
        // Setup sample transaction in repository
        try await mockDIContainer.mockTransactionRepository.insertTransaction(sampleTransaction)
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockDIContainer = nil
        mockTransactionEventPublisher = nil
        sampleTransaction = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func test_initialization_setsCorrectInitialValues() {
        // Then
        XCTAssertEqual(viewModel.transaction.id, sampleTransaction.id)
        XCTAssertEqual(viewModel.transaction.amount, sampleTransaction.amount)
        XCTAssertEqual(viewModel.viewMode, .detail)
        XCTAssertFalse(viewModel.isPresentedDeleteConfirmation)
    }
    
    func test_initialization_withDifferentTransaction_setsCorrectValues() {
        // Given
        let customTransaction = TransactionDTO(
            amount: 50000,
            place: "Custom Place",
            memo: "Custom Memo",
            transactionType: .income,
            isFavorite: true,
            subCategory: SubCategoryDTO.mockIncomeAllowance,
            paymentMethod: PaymentMethodDTO.mockCash
        )
        
        // When
        let customViewModel = TransactionDetailViewModel(
            transaction: customTransaction,
            deleteTransactionUseCase: mockDIContainer.makeDeleteTransactionUseCase(),
            getTransactionByIdUseCase: mockDIContainer.makeGetTransactionByIdUseCase(),
            transactionEventPublisher: mockTransactionEventPublisher,
            updateTransactionViewModel: mockDIContainer.makeUpdateTransactionViewModel(transaction: customTransaction)
        )
        
        // Then
        XCTAssertEqual(customViewModel.transaction.id, customTransaction.id)
        XCTAssertEqual(customViewModel.transaction.amount, 50000)
        XCTAssertEqual(customViewModel.transaction.place, "Custom Place")
        XCTAssertTrue(customViewModel.transaction.isFavorite)
        XCTAssertEqual(customViewModel.transaction.transactionType, .income)
    }
    
    // MARK: - Delete Confirmation Tests
    
    func test_showDeleteConfirmation_setsConfirmationFlag() {
        // Given
        XCTAssertFalse(viewModel.isPresentedDeleteConfirmation)
        
        // When
        viewModel.send(.showDeleteConfirmation)
        
        // Then
        XCTAssertTrue(viewModel.isPresentedDeleteConfirmation)
    }
    
//    func test_hideDeleteConfirmation_resetsConfirmationFlag() {
//        // Given
//        viewModel.send(.showDeleteConfirmation)
//        XCTAssertTrue(viewModel.isPresentedDeleteConfirmation)
//        
//        // When
//        viewModel.send(.hideDeleteConfirmation)
//        
//        // Then
//        XCTAssertFalse(viewModel.isPresentedDeleteConfirmation)
//    }
    
    // MARK: - Delete Transaction Tests
    
    func test_deleteTransaction_withExistingTransaction_deletesSuccessfully() async throws {
        // Given
        var completionCalled = false
        let repository = mockDIContainer.mockTransactionRepository
        
        // Verify transaction exists
        let existingTransaction = try await repository.fetchTransaction(id: sampleTransaction.id)
        XCTAssertNotNil(existingTransaction)
        
        // When
        viewModel.send(.deleteTransaction {
            completionCalled = true
        })
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1초
        
        // Then
        let deletedTransaction = try await repository.fetchTransaction(id: sampleTransaction.id)
        XCTAssertNil(deletedTransaction, "거래가 삭제되어야 함")
        XCTAssertTrue(completionCalled, "Completion 콜백이 호출되어야 함")
    }
    
    func test_deleteTransaction_withNonExistentTransaction_handlesErrorGracefully() async throws {
        // Given
        let repository = mockDIContainer.mockTransactionRepository
        
        // Remove transaction from repository to simulate non-existent state
        try await repository.deleteTransaction(id: sampleTransaction.id)
        
        var completionCalled = false
        
        // When
        viewModel.send(.deleteTransaction {
            completionCalled = true
        })
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1초
        
        // Then
        XCTAssertFalse(completionCalled, "존재하지 않는 거래 삭제 시 completion이 호출되지 않아야 함")
    }
    
    func test_deleteTransaction_withRepositoryFailure_handlesErrorGracefully() async throws {
        // Given
        let repository = mockDIContainer.mockTransactionRepository
        repository.shouldFail = true
        
        var completionCalled = false
        
        // When
        viewModel.send(.deleteTransaction {
            completionCalled = true
        })
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1초
        
        // Then
        XCTAssertFalse(completionCalled, "Repository 오류 시 completion이 호출되지 않아야 함")
        
        // Transaction should still exist
        repository.shouldFail = false
        let stillExists = try await repository.fetchTransaction(id: sampleTransaction.id)
        XCTAssertNotNil(stillExists, "오류 발생 시 거래가 그대로 존재해야 함")
    }
    
    func test_deleteTransaction_publishesDeletedEvent() async throws {
        // Given
        var completionCalled = false
        
        // When
        viewModel.send(.deleteTransaction {
            completionCalled = true
        })
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1초
        
        // Then
        XCTAssertTrue(completionCalled)
        XCTAssertEqual(mockTransactionEventPublisher.publishedEvents.count, 1)
        
        let publishedEvent = mockTransactionEventPublisher.publishedEvents.first!
        XCTAssertEqual(publishedEvent.type, .deleted)
        XCTAssertEqual(publishedEvent.yearMonth, YearMonth(from: sampleTransaction.date))
    }
    
    func test_deleteTransaction_whenFailed_doesNotPublishEvent() async throws {
        // Given
        let repository = mockDIContainer.mockTransactionRepository
        repository.shouldFail = true
        
        var completionCalled = false
        
        // When
        viewModel.send(.deleteTransaction {
            completionCalled = true
        })
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1초
        
        // Then
        XCTAssertFalse(completionCalled)
        XCTAssertEqual(mockTransactionEventPublisher.publishedEvents.count, 0, "실패 시 이벤트가 발행되지 않아야 함")
    }
    
    // MARK: - Fetch Transaction Tests
    
    func test_fetchTransaction_updatesTransactionData() async throws {
        // Given
        let repository = mockDIContainer.mockTransactionRepository
        let updatedTransaction = TransactionDTO(
            id: sampleTransaction.id,
            amount: 75000,
            date: sampleTransaction.date,
            place: "Updated Place",
            memo: "Updated Memo",
            transactionType: sampleTransaction.transactionType,
            isFavorite: true,
            subCategory: sampleTransaction.subCategory,
            paymentMethod: sampleTransaction.paymentMethod
        )
        
        // Update transaction in repository
        try await repository.updateTransaction(updatedTransaction)
        
        // When
        viewModel.send(.fetchTransaction)
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1초
        
        // Then
        XCTAssertEqual(viewModel.transaction.amount, 75000)
        XCTAssertEqual(viewModel.transaction.place, "Updated Place")
        XCTAssertEqual(viewModel.transaction.memo, "Updated Memo")
        XCTAssertTrue(viewModel.transaction.isFavorite)
    }
    
    func test_fetchTransaction_withNonExistentTransaction_keepsOriginalData() async throws {
        // Given
        let repository = mockDIContainer.mockTransactionRepository
        let originalAmount = viewModel.transaction.amount
        let originalPlace = viewModel.transaction.place
        
        // Remove transaction from repository
        try await repository.deleteTransaction(id: sampleTransaction.id)
        
        // When
        viewModel.send(.fetchTransaction)
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1초
        
        // Then - Should keep original data
        XCTAssertEqual(viewModel.transaction.amount, originalAmount)
        XCTAssertEqual(viewModel.transaction.place, originalPlace)
    }
    
    func test_fetchTransaction_withRepositoryFailure_keepsOriginalData() async throws {
        // Given
        let repository = mockDIContainer.mockTransactionRepository
        let originalAmount = viewModel.transaction.amount
        let originalPlace = viewModel.transaction.place
        
        repository.shouldFail = true
        
        // When
        viewModel.send(.fetchTransaction)
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1초
        
        // Then - Should keep original data
        XCTAssertEqual(viewModel.transaction.amount, originalAmount)
        XCTAssertEqual(viewModel.transaction.place, originalPlace)
    }
    
    // MARK: - Integration Tests
    
    func test_fullDeleteFlow_showConfirmationThenDelete() async throws {
        // Given
        var completionCalled = false
        let repository = mockDIContainer.mockTransactionRepository
        
        // When - Show confirmation first
        viewModel.send(.showDeleteConfirmation)
        XCTAssertTrue(viewModel.isPresentedDeleteConfirmation)
        
        // Then - Execute deletion
        viewModel.send(.deleteTransaction {
            completionCalled = true
        })
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1초
        
        // Then
        let deletedTransaction = try await repository.fetchTransaction(id: sampleTransaction.id)
        XCTAssertNil(deletedTransaction)
        XCTAssertTrue(completionCalled)
        
        // Event should be published
        XCTAssertEqual(mockTransactionEventPublisher.publishedEvents.count, 1)
        XCTAssertEqual(mockTransactionEventPublisher.publishedEvents.first?.type, .deleted)
    }
    
    func test_updateAndFetchFlow_maintainsDataConsistency() async throws {
        // Given
        let repository = mockDIContainer.mockTransactionRepository
        let updatedTransaction = TransactionDTO(
            id: sampleTransaction.id,
            amount: 99000,
            date: sampleTransaction.date,
            place: "Integration Test Place",
            memo: "Integration Test Memo",
            transactionType: sampleTransaction.transactionType,
            isFavorite: false,
            subCategory: sampleTransaction.subCategory,
            paymentMethod: sampleTransaction.paymentMethod
        )
        
        // When - Update through repository
        try await repository.updateTransaction(updatedTransaction)
        
        // Then - Fetch through ViewModel
        viewModel.send(.fetchTransaction)
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1초
        
        // Then - ViewModel should reflect the changes
        XCTAssertEqual(viewModel.transaction.amount, 99000)
        XCTAssertEqual(viewModel.transaction.place, "Integration Test Place")
        XCTAssertEqual(viewModel.transaction.memo, "Integration Test Memo")
        XCTAssertFalse(viewModel.transaction.isFavorite)
    }
    
    // MARK: - Edge Cases Tests
    
    func test_multipleDeleteCalls_handledGracefully() async throws {
        // Given
        var firstCompletionCalled = false
        var secondCompletionCalled = false
        
        // When - Call delete twice quickly
        viewModel.send(.deleteTransaction {
            firstCompletionCalled = true
        })
        
        viewModel.send(.deleteTransaction {
            secondCompletionCalled = true
        })
        
        // Wait for async operations
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2초
        
        // Then - Only one deletion should succeed
        XCTAssertTrue(firstCompletionCalled || secondCompletionCalled, "적어도 하나의 삭제는 성공해야 함")
        
        // Transaction should be deleted
        let repository = mockDIContainer.mockTransactionRepository
        let deletedTransaction = try await repository.fetchTransaction(id: sampleTransaction.id)
        XCTAssertNil(deletedTransaction)
    }
}
