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
    
    private var viewModel: TransactionDetailViewModel!
    private var mockDeleteUseCase: MockDeleteTransactionUseCase!
    private var mockTransaction: TransactionDTO!
    private var mockPublisher: MockTransactionEventPublisher!

    override func setUp() {
        super.setUp()
        mockDeleteUseCase = MockDeleteTransactionUseCase()
        mockTransaction = TransactionDTO.mockLunch
        mockPublisher = MockTransactionEventPublisher()
        viewModel = TransactionDetailViewModel(
            transaction: mockTransaction,
            deleteTransactionUseCase: mockDeleteUseCase,
            transactionEventPublisher: mockPublisher
        )
    }
    
    override func tearDown() {
        viewModel = nil
        mockDeleteUseCase = nil
        mockTransaction = nil
        mockPublisher = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInit_WithTransaction_SetsProperties() {
        // Then
        XCTAssertEqual(viewModel.transaction.id, mockTransaction.id)
        XCTAssertEqual(viewModel.viewMode, .detail)
        XCTAssertFalse(viewModel.isPresentedDeleteConfirmation)
    }
    
    // MARK: - Action Tests - Show Delete Confirmation
    
    func testSendShowDeleteConfirmation_UpdatesConfirmationState() {
        // Given
        XCTAssertFalse(viewModel.isPresentedDeleteConfirmation)
        
        // When
        viewModel.send(.showDeleteConfirmation)
        
        // Then
        XCTAssertTrue(viewModel.isPresentedDeleteConfirmation)
    }
    
    // MARK: - Action Tests - Change View Mode
    
    func testSendChangeViewMode_FromDetail_SwitchesToUpdate() {
        // Given
        XCTAssertEqual(viewModel.viewMode, .detail)
        
        // When
        viewModel.send(.changeViewMode)
        
        // Then
        XCTAssertEqual(viewModel.viewMode, .update)
    }
    
    func testSendChangeViewMode_FromUpdate_SwitchesToDetail() {
        // Given
        viewModel.send(.changeViewMode) // 먼저 update 모드로 변경
        XCTAssertEqual(viewModel.viewMode, .update)
        
        // When
        viewModel.send(.changeViewMode)
        
        // Then
        XCTAssertEqual(viewModel.viewMode, .detail)
    }
    
    // MARK: - Action Tests - Delete Transaction
    
    func testSendDeleteTransaction_WithValidTransaction_CallsUseCaseAndCompletion() async throws {
        // Given
        mockDeleteUseCase.addExistingTransaction(id: mockTransaction.id)
        var completionCalled = false
        
        // When
        viewModel.send(.deleteTransaction {
            completionCalled = true
        })
        
        // 비동기 작업 완료 대기
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1초
        
        // Then
        XCTAssertTrue(mockDeleteUseCase.deletedTransactionIds.contains(mockTransaction.id))
        XCTAssertTrue(completionCalled)
    }
    
    func testSendDeleteTransaction_WithNonExistentTransaction_CallsCompletionWithError() async throws {
        // Given - 존재하지 않는 거래 (mockDeleteUseCase에 추가하지 않음)
        var completionCalled = false
        
        // When
        viewModel.send(.deleteTransaction {
            completionCalled = true
        })
        
        // 비동기 작업 완료 대기
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1초
        
        // Then
        XCTAssertFalse(mockDeleteUseCase.deletedTransactionIds.contains(mockTransaction.id))
        XCTAssertFalse(completionCalled) // 에러로 인해 completion이 호출되지 않음
    }
    
    func testSendDeleteTransaction_WhenUseCaseFails_DoesNotCallCompletion() async throws {
        // Given
        mockDeleteUseCase.addExistingTransaction(id: mockTransaction.id)
        mockDeleteUseCase.shouldFail = true
        var completionCalled = false
        
        // When
        viewModel.send(.deleteTransaction {
            completionCalled = true
        })
        
        // 비동기 작업 완료 대기
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1초
        
        // Then
        XCTAssertFalse(mockDeleteUseCase.deletedTransactionIds.contains(mockTransaction.id))
        XCTAssertFalse(completionCalled)
    }
    
    // MARK: - Integration Tests
    
    func testFullDeleteFlow_ShowConfirmationThenDelete() async throws {
        // Given
        mockDeleteUseCase.addExistingTransaction(id: mockTransaction.id)
        var completionCalled = false
        
        // When - 먼저 삭제 확인창 표시
        viewModel.send(.showDeleteConfirmation)
        XCTAssertTrue(viewModel.isPresentedDeleteConfirmation)
        
        // Then - 삭제 실행
        viewModel.send(.deleteTransaction {
            completionCalled = true
        })
        
        // 비동기 작업 완료 대기
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1초
        
        // Then
        XCTAssertTrue(mockDeleteUseCase.deletedTransactionIds.contains(mockTransaction.id))
        XCTAssertTrue(completionCalled)
    }
    
    // MARK: - TransactionEventPublisher Tests
    
    func testSendDeleteTransaction_WithValidTransaction_PublishesDeletedEvent() async throws {
        // Given
        mockDeleteUseCase.addExistingTransaction(id: mockTransaction.id)
        var completionCalled = false
        
        // When
        viewModel.send(.deleteTransaction {
            completionCalled = true
        })
        
        // 비동기 작업 완료 대기
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1초
        
        // Then
        XCTAssertTrue(completionCalled)
        XCTAssertEqual(mockPublisher.publishedEvents.count, 1)
        
        let publishedEvent = mockPublisher.publishedEvents.first!
        XCTAssertEqual(publishedEvent.type, .deleted)
        XCTAssertEqual(publishedEvent.yearMonth, YearMonth(from: mockTransaction.date))
    }
    
    func testSendDeleteTransaction_WhenUseCaseFails_DoesNotPublishEvent() async throws {
        // Given
        mockDeleteUseCase.addExistingTransaction(id: mockTransaction.id)
        mockDeleteUseCase.shouldFail = true
        var completionCalled = false
        
        // When
        viewModel.send(.deleteTransaction {
            completionCalled = true
        })
        
        // 비동기 작업 완료 대기
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1초
        
        // Then
        XCTAssertFalse(completionCalled)
        XCTAssertEqual(mockPublisher.publishedEvents.count, 0)
    }
    
    func testSendDeleteTransaction_WithDifferentMonthTransaction_PublishesCorrectYearMonth() async throws {
        // Given
        let calendar = Calendar.current
        let futureDate = calendar.date(byAdding: .month, value: 2, to: Date()) ?? Date()
        let futureTransaction = TransactionDTO.mockWith(
            date: futureDate,
            transactionType: .variableExpense,
            subCategory: .mockFoodExpense,
            paymentMethod: .mockCreditCard
        )
        
        let futureViewModel = TransactionDetailViewModel(
            transaction: futureTransaction,
            deleteTransactionUseCase: mockDeleteUseCase,
            transactionEventPublisher: mockPublisher
        )
        
        mockDeleteUseCase.addExistingTransaction(id: futureTransaction.id)
        var completionCalled = false
        
        // When
        futureViewModel.send(.deleteTransaction {
            completionCalled = true
        })
        
        // 비동기 작업 완료 대기
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1초
        
        // Then
        XCTAssertTrue(completionCalled)
        XCTAssertEqual(mockPublisher.publishedEvents.count, 1)
        
        let publishedEvent = mockPublisher.publishedEvents.first!
        XCTAssertEqual(publishedEvent.type, .deleted)
        XCTAssertEqual(publishedEvent.yearMonth, YearMonth(from: futureDate))
    }
    
    func testInitialization_DoesNotPublishAnyEvents() {
        // Then
        XCTAssertEqual(mockPublisher.publishedEvents.count, 0)
    }
    
    func testOtherActions_DoNotPublishEvents() {
        // When
        viewModel.send(.showDeleteConfirmation)
        viewModel.send(.changeViewMode)
        
        // Then
        XCTAssertEqual(mockPublisher.publishedEvents.count, 0)
    }
}
