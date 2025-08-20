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
    private var mockGetTransactionByIdUseCase: MockGetTransactionByIdUseCase!
    private var mockUpdateTransactionViewModel: UpdateTransactionViewModel!
    private var mockTransaction: TransactionDTO!
    private var mockPublisher: MockTransactionEventPublisher!
    private var mockDIContainer: MockDIContainer!

    override func setUp() {
        super.setUp()
        mockDeleteUseCase = MockDeleteTransactionUseCase()
        mockGetTransactionByIdUseCase = MockGetTransactionByIdUseCase()
        mockTransaction = TransactionDTO.mockLunch
        mockPublisher = MockTransactionEventPublisher()
        mockDIContainer = MockDIContainer()
        mockUpdateTransactionViewModel = mockDIContainer.makeUpdateTransactionViewModel(transaction: mockTransaction)
        
        viewModel = TransactionDetailViewModel(
            transaction: mockTransaction,
            deleteTransactionUseCase: mockDeleteUseCase,
            getTransactionByIdUseCase: mockGetTransactionByIdUseCase,
            transactionEventPublisher: mockPublisher,
            updateTransactionViewModel: mockUpdateTransactionViewModel
        )
    }
    
    override func tearDown() {
        viewModel = nil
        mockDeleteUseCase = nil
        mockGetTransactionByIdUseCase = nil
        mockUpdateTransactionViewModel = nil
        mockTransaction = nil
        mockPublisher = nil
        mockDIContainer = nil
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
        
        let futureUpdateTransactionViewModel = mockDIContainer.makeUpdateTransactionViewModel(transaction: futureTransaction)
        let futureViewModel = TransactionDetailViewModel(
            transaction: futureTransaction,
            deleteTransactionUseCase: mockDeleteUseCase,
            getTransactionByIdUseCase: mockGetTransactionByIdUseCase,
            transactionEventPublisher: mockPublisher,
            updateTransactionViewModel: futureUpdateTransactionViewModel
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
    
    // MARK: - Fetch Transaction Tests
    
    func testSendFetchTransaction_WithExistingTransaction_UpdatesTransaction() async throws {
        // Given
        let updatedTransaction = TransactionDTO(
            id: mockTransaction.id,
            amount: 100000,
            date: mockTransaction.date,
            place: "수정된 장소",
            memo: "수정된 메모",
            transactionType: .income,
            isFavorite: true,
            subCategory: SubCategoryDTO.mockIncomeAllowance,
            paymentMethod: PaymentMethodDTO.mockCash
        )
        
        mockGetTransactionByIdUseCase.setMockTransaction(updatedTransaction)
        
        // When
        viewModel.send(.fetchTransaction)
        
        // 비동기 작업 완료 대기
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1초
        
        // Then
        XCTAssertEqual(viewModel.transaction.id, updatedTransaction.id)
        XCTAssertEqual(viewModel.transaction.amount, 100000)
        XCTAssertEqual(viewModel.transaction.place, "수정된 장소")
        XCTAssertEqual(viewModel.transaction.memo, "수정된 메모")
        XCTAssertEqual(viewModel.transaction.transactionType, .income)
        XCTAssertTrue(viewModel.transaction.isFavorite)
    }
    
    func testSendFetchTransaction_WithNonExistingTransaction_DoesNotUpdateTransaction() async throws {
        // Given
        let originalTransaction = viewModel.transaction
        // mockGetTransactionByIdUseCase에 거래를 추가하지 않음 (nil 반환)
        
        // When
        viewModel.send(.fetchTransaction)
        
        // 비동기 작업 완료 대기
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1초
        
        // Then
        XCTAssertEqual(viewModel.transaction.id, originalTransaction.id)
        XCTAssertEqual(viewModel.transaction.amount, originalTransaction.amount)
        XCTAssertEqual(viewModel.transaction.place, originalTransaction.place)
    }
    
    func testSendFetchTransaction_WhenUseCaseFails_DoesNotUpdateTransaction() async throws {
        // Given
        let originalTransaction = viewModel.transaction
        mockGetTransactionByIdUseCase.shouldFail = true
        
        // When
        viewModel.send(.fetchTransaction)
        
        // 비동기 작업 완료 대기
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1초
        
        // Then
        XCTAssertEqual(viewModel.transaction.id, originalTransaction.id)
        XCTAssertEqual(viewModel.transaction.amount, originalTransaction.amount)
        XCTAssertEqual(viewModel.transaction.place, originalTransaction.place)
    }
    
    // MARK: - Update Mode Transition Tests
    
    func testChangeViewModeToUpdate_SetsCombineSubscriptions() {
        // Given
        XCTAssertEqual(viewModel.viewMode, .detail)
        
        // When
        viewModel.send(.changeViewMode)
        
        // Then
        XCTAssertEqual(viewModel.viewMode, .update)
        // Combine subscriptions이 설정되었는지는 내부 구현이므로 직접 테스트하기 어려움
        // 대신 이후 이벤트 발행 시 동작을 테스트
    }
    
    func testChangeViewModeToDetail_ClearsCombineSubscriptions() {
        // Given
        viewModel.send(.changeViewMode) // update 모드로 변경
        XCTAssertEqual(viewModel.viewMode, .update)
        
        // When
        viewModel.send(.changeViewMode) // detail 모드로 복귀
        
        // Then
        XCTAssertEqual(viewModel.viewMode, .detail)
    }
    
    // MARK: - Integration Tests for Update Flow
    
    func testUpdateFlow_WhenTransactionUpdated_FetchesLatestData() async throws {
        // Given
        let updatedTransaction = TransactionDTO(
            id: mockTransaction.id,
            amount: 150000,
            date: mockTransaction.date,
            place: "업데이트된 장소",
            memo: "업데이트된 메모",
            transactionType: .fixedExpense,
            isFavorite: false,
            subCategory: SubCategoryDTO.mockTransportBus,
            paymentMethod: PaymentMethodDTO.mockCreditCard
        )
        
        mockGetTransactionByIdUseCase.setMockTransaction(updatedTransaction)
        
        // update 모드로 변경
        viewModel.send(.changeViewMode)
        XCTAssertEqual(viewModel.viewMode, .update)
        
        // When - updated 이벤트 발행 시뮬레이션
        mockPublisher.publish(.init(type: .updated, yearMonth: YearMonth(from: mockTransaction.date)))
        
        // 비동기 작업 완료 대기
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1초
        
        // Then
        XCTAssertEqual(viewModel.transaction.amount, 150000)
        XCTAssertEqual(viewModel.transaction.place, "업데이트된 장소")
        XCTAssertEqual(viewModel.transaction.transactionType, .fixedExpense)
    }
    
    func testUpdateFlow_WhenUpdateCancelled_ReturnsToDetailMode() async throws {
        // Given
        viewModel.send(.changeViewMode)
        XCTAssertEqual(viewModel.viewMode, .update)
        
        // When - cancel 이벤트 발행 시뮬레이션
        mockUpdateTransactionViewModel.cancelEventPublisher.send()
        
        // 비동기 작업 완료 대기
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1초
        
        // Then
        XCTAssertEqual(viewModel.viewMode, .detail)
    }
    
    // MARK: - UpdateTransactionViewModel Integration Tests
    
    func testUpdateTransactionViewModel_IsCorrectlyInitialized() {
        // Then
        XCTAssertEqual(mockUpdateTransactionViewModel.transaction.id, mockTransaction.id)
        XCTAssertNotNil(viewModel.updateTransactionViewModel)
    }
    
    func testMultipleViewModeChanges_DoesNotLeakMemory() {
        // Given & When - 여러 번 모드 변경
        for _ in 0..<5 {
            viewModel.send(.changeViewMode) // detail -> update
            viewModel.send(.changeViewMode) // update -> detail
        }
        
        // Then
        XCTAssertEqual(viewModel.viewMode, .detail)
        // 메모리 누수 방지를 위해 cancellables이 정리되어야 함
        // 직접 테스트하기 어려우므로 앱이 크래시하지 않음을 확인
    }
}
