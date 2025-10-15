//
//  UpdateTransactionViewModelTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 10/15/25.
//

import XCTest
import Combine
@testable import MoneyMoa

@MainActor
final class UpdateTransactionViewModelTests: XCTestCase {

    // MARK: - Properties

    private var mockUpdateUseCase: MockUpdateTransactionUseCase!
    private var mockEventPublisher: MockTransactionEventPublisher!
    private var mockContainer: MockDIContainer!
    private var viewModel: UpdateTransactionViewModel!
    private var cancellables: Set<AnyCancellable>!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mockUpdateUseCase = MockUpdateTransactionUseCase()
        mockEventPublisher = MockTransactionEventPublisher()
        mockContainer = MockDIContainer()
        cancellables = []
    }

    override func tearDown() {
        mockUpdateUseCase = nil
        mockEventPublisher = nil
        mockContainer = nil
        viewModel = nil
        cancellables = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func makeViewModel(transaction: TransactionDTO) -> UpdateTransactionViewModel {
        return UpdateTransactionViewModel(
            transaction: transaction,
            updateTransactionUseCase: mockUpdateUseCase,
            transactionEventPublisher: mockEventPublisher,
            amountPlacePaymentViewModel: mockContainer.makeAmountPlacePaymentMethodFormViewModel(
                amount: transaction.amount,
                place: transaction.place ?? "",
                paymentMethod: transaction.paymentMethod
            ),
            transactionTypeSelectionViewModel: mockContainer.makeTransactionTypeCategoryFormViewModel(
                transactionType: transaction.transactionType,
                subCategory: transaction.subCategory
            ),
            dateAdditionalFormViewModel: mockContainer.makeDateAdditionalFormViewModel(
                date: transaction.date,
                memo: transaction.memo ?? "",
                isReadOnlyTemplate: true
            )
        )
    }

    // MARK: - Test Methods - Computed Properties

    func test_hasTemplate_withTemplate_returnsTrue() {
        // Given: 템플릿이 있는 거래
        let template = TransactionTemplateDTO(
            amount: 50000,
            place: "Test",
            memo: "Test",
            transactionType: .variableExpense,
            recurrencePeriod: .monthly,
            createdAt: Date(),
            lastAddedAt: Date(),
            nextDueDate: Date().addingTimeInterval(86400 * 30),
            timeContext: .current,
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCreditCard,
            recurrencePattern: RecurrencePattern(period: .monthly),
            executionState: TemplateExecutionState(lastExecutedAt: Date(), executionCount: 1)
        )

        let transaction = TransactionDTO(
            amount: 50000,
            date: Date(),
            place: "Test",
            memo: "Test",
            transactionType: .variableExpense,
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCreditCard,
            transactionTemplate: template
        )
        viewModel = makeViewModel(transaction: transaction)

        // When & Then
        XCTAssertTrue(viewModel.hasTemplate, "템플릿이 있으면 true를 반환해야 함")
    }

    func test_hasTemplate_withoutTemplate_returnsFalse() {
        // Given: 템플릿이 없는 거래
        let transaction = TransactionFactory.sample()
        viewModel = makeViewModel(transaction: transaction)

        // When & Then
        XCTAssertFalse(viewModel.hasTemplate, "템플릿이 없으면 false를 반환해야 함")
    }

    // MARK: - Test Methods - Alert Flow

    func test_updateTransaction_withTemplate_showsAlert() {
        // Given: 템플릿이 있는 거래
        let template = TransactionTemplateDTO(
            amount: 50000,
            place: "Test",
            memo: "Test",
            transactionType: .variableExpense,
            recurrencePeriod: .monthly,
            createdAt: Date(),
            lastAddedAt: Date(),
            nextDueDate: Date().addingTimeInterval(86400 * 30),
            timeContext: .current,
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCreditCard,
            recurrencePattern: RecurrencePattern(period: .monthly),
            executionState: TemplateExecutionState(lastExecutedAt: Date(), executionCount: 1)
        )

        let transaction = TransactionDTO(
            amount: 50000,
            date: Date(),
            place: "Test",
            memo: "Test",
            transactionType: .variableExpense,
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCreditCard,
            transactionTemplate: template
        )
        viewModel = makeViewModel(transaction: transaction)

        // 금액 변경
        viewModel.amountPlacePaymentViewModel.amount = 75000

        // When
        viewModel.send(.updateTransaction)

        // Then
        XCTAssertTrue(viewModel.showUpdateAlert, "템플릿이 있으면 alert를 표시해야 함")
        XCTAssertNotNil(viewModel.pendingUpdate, "pendingUpdate가 생성되어야 함")
    }

    func test_updateTransaction_withoutTemplate_executesImmediately() async {
        // Given: 템플릿이 없는 거래
        let transaction = TransactionFactory.sample()
        viewModel = makeViewModel(transaction: transaction)

        // 금액 변경
        viewModel.amountPlacePaymentViewModel.amount = 75000

        // When
        viewModel.send(.updateTransaction)

        // Then: alert 표시 없이 바로 실행
        try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1초 대기
        XCTAssertFalse(viewModel.showUpdateAlert, "템플릿이 없으면 alert를 표시하지 않아야 함")
        XCTAssertTrue(mockUpdateUseCase.executeCallCount > 0, "UseCase가 호출되어야 함")
    }

    func test_confirmUpdateWithTemplate_executesWithUpdateStrategy() async {
        // Given: 템플릿이 있는 거래 & alert 표시됨
        let template = TransactionTemplateDTO(
            amount: 50000,
            place: "Test",
            memo: "Test",
            transactionType: .variableExpense,
            recurrencePeriod: .monthly,
            createdAt: Date(),
            lastAddedAt: Date(),
            nextDueDate: Date().addingTimeInterval(86400 * 30),
            timeContext: .current,
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCreditCard,
            recurrencePattern: RecurrencePattern(period: .monthly),
            executionState: TemplateExecutionState(lastExecutedAt: Date(), executionCount: 1)
        )

        let transaction = TransactionDTO(
            amount: 50000,
            date: Date(),
            place: "Test",
            memo: "Test",
            transactionType: .variableExpense,
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCreditCard,
            transactionTemplate: template
        )
        viewModel = makeViewModel(transaction: transaction)
        viewModel.amountPlacePaymentViewModel.amount = 75000
        viewModel.send(.updateTransaction)

        // When
        viewModel.send(.confirmUpdateWithTemplate)

        // Then
        try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1초 대기
        XCTAssertFalse(viewModel.showUpdateAlert, "alert가 닫혀야 함")
        XCTAssertNil(viewModel.pendingUpdate, "pendingUpdate가 초기화되어야 함")
        XCTAssertEqual(mockUpdateUseCase.lastStrategy, .updateWithTemplate, "updateWithTemplate 전략으로 실행되어야 함")
    }

    func test_confirmUpdateTransactionOnly_executesWithNoneStrategy() async {
        // Given: 템플릿이 있는 거래 & alert 표시됨
        // Mock을 새로 생성하여 완전히 초기화
        mockUpdateUseCase = MockUpdateTransactionUseCase()

        let template = TransactionTemplateDTO(
            amount: 50000,
            place: "Test",
            memo: "Test",
            transactionType: .variableExpense,
            recurrencePeriod: .monthly,
            createdAt: Date(),
            lastAddedAt: Date(),
            nextDueDate: Date().addingTimeInterval(86400 * 30),
            timeContext: .current,
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCreditCard,
            recurrencePattern: RecurrencePattern(period: .monthly),
            executionState: TemplateExecutionState(lastExecutedAt: Date(), executionCount: 1)
        )

        let transaction = TransactionDTO(
            amount: 50000,
            date: Date(),
            place: "Test",
            memo: "Test",
            transactionType: .variableExpense,
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCreditCard,
            transactionTemplate: template
        )
        viewModel = makeViewModel(transaction: transaction)
        viewModel.amountPlacePaymentViewModel.amount = 75000
        viewModel.send(.updateTransaction)

        // When
        viewModel.send(.confirmUpdateTransactionOnly)

        // Then
        try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1초 대기
        XCTAssertFalse(viewModel.showUpdateAlert, "alert가 닫혀야 함")
        XCTAssertNil(viewModel.pendingUpdate, "pendingUpdate가 초기화되어야 함")
        XCTAssertNotNil(mockUpdateUseCase.lastStrategy, "UseCase가 호출되어야 함")
        if let strategy = mockUpdateUseCase.lastStrategy {
            XCTAssertEqual(strategy, .none, "none 전략으로 실행되어야 함")
        }
    }

    func test_cancelUpdate_resetsAlertState() {
        // Given: alert 표시됨
        let template = TransactionTemplateDTO(
            amount: 50000,
            place: "Test",
            memo: "Test",
            transactionType: .variableExpense,
            recurrencePeriod: .monthly,
            createdAt: Date(),
            lastAddedAt: Date(),
            nextDueDate: Date().addingTimeInterval(86400 * 30),
            timeContext: .current,
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCreditCard,
            recurrencePattern: RecurrencePattern(period: .monthly),
            executionState: TemplateExecutionState(lastExecutedAt: Date(), executionCount: 1)
        )

        let transaction = TransactionDTO(
            amount: 50000,
            date: Date(),
            place: "Test",
            memo: "Test",
            transactionType: .variableExpense,
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCreditCard,
            transactionTemplate: template
        )
        viewModel = makeViewModel(transaction: transaction)
        viewModel.amountPlacePaymentViewModel.amount = 75000
        viewModel.send(.updateTransaction)

        // When
        viewModel.send(.cancelUpdate)

        // Then
        XCTAssertFalse(viewModel.showUpdateAlert, "alert가 닫혀야 함")
        XCTAssertNil(viewModel.pendingUpdate, "pendingUpdate가 초기화되어야 함")
        XCTAssertEqual(mockUpdateUseCase.executeCallCount, 0, "UseCase가 호출되지 않아야 함")
    }

    // MARK: - Test Methods - Cancel Button

    func test_cancelButtonTapped_publishesCancelEvent() {
        // Given
        let transaction = TransactionFactory.sample()
        viewModel = makeViewModel(transaction: transaction)

        var cancelEventReceived = false
        viewModel.cancelEventPublisher
            .sink { cancelEventReceived = true }
            .store(in: &cancellables)

        // When
        viewModel.send(.cancelButtonTapped)

        // Then
        XCTAssertTrue(cancelEventReceived, "취소 이벤트가 발행되어야 함")
    }
}

// MARK: - Mock UpdateTransactionUseCase

class MockUpdateTransactionUseCase: UpdateTransactionUseCase {
    var executeCallCount = 0
    var lastTransaction: TransactionDTO?
    var lastStrategy: TemplateUpdateStrategy?
    var shouldFail = false

    func execute(_ transaction: TransactionDTO, strategy: TemplateUpdateStrategy) async throws {
        executeCallCount += 1
        lastTransaction = transaction
        lastStrategy = strategy

        if shouldFail {
            throw MockError.simulatedFailure
        }
    }

    func reset() {
        executeCallCount = 0
        lastTransaction = nil
        lastStrategy = nil
        shouldFail = false
    }
}
