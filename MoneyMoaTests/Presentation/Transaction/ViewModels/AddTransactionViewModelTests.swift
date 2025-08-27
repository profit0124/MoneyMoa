//
//  AddTransactionViewModelTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 8/19/25.
//

import XCTest
import Combine
@testable import MoneyMoa

// MARK: - MockTransactionEventPublisher

final class MockTransactionEventPublisher: TransactionEventPublisher {
    private let subject = PassthroughSubject<TransactionEvent, Never>()
    private(set) var publishedEvents: [TransactionEvent] = []
    
    var transactionEvents: AnyPublisher<TransactionEvent, Never> {
        subject.eraseToAnyPublisher()
    }
    
    func publish(_ event: TransactionEvent) {
        publishedEvents.append(event)
        subject.send(event)
    }
    
    func reset() {
        publishedEvents.removeAll()
    }
}

// MARK: - AddTransactionViewModelTests

@MainActor
final class AddTransactionViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var viewModel: AddTransactionViewModel!
    private var mockContainer: MockDIContainer!
    private var mockTransactionEventPublisher: MockTransactionEventPublisher!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        
        mockContainer = MockDIContainer()
        mockTransactionEventPublisher = MockTransactionEventPublisher()
        cancellables = Set<AnyCancellable>()
        
        // Create viewModel with mock dependencies
        viewModel = AddTransactionViewModel(
            createTransactionUseCase: mockContainer.makeCreateTransactionUseCase(),
            getFavoriteTransactionsUseCase: mockContainer.makeGetFavoriteTransactionsUseCase(),
            transactionEventPublisher: mockTransactionEventPublisher,
            amountPlacePaymentViewModel: mockContainer.makeAmountPlacePaymentMethodFormViewModel(),
            transactionTypeSelectionViewModel: mockContainer.makeTransactionTypeCategoryFormViewModel(),
            dateAdditionalFormViewModel: mockContainer.makeDateAdditionalFormViewModel()
        )
    }
    
    override func tearDown() {
        cancellables = nil
        mockTransactionEventPublisher = nil
        mockContainer = nil
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - Test Methods - Initialization
    
    func test_initialization_setsCorrectInitialValues() {
        // Then
        XCTAssertEqual(viewModel.currentStep, .amountPlacePaymentMethod)
        XCTAssertTrue(viewModel.filteredCompletedStep.isEmpty)
        XCTAssertEqual(viewModel.buttonTitle, "다음")
        XCTAssertFalse(viewModel.isValid) // 초기에는 유효하지 않음
    }
    
    func test_initialization_createsChildViewModels() {
        // Then
        XCTAssertNotNil(viewModel.amountPlacePaymentViewModel)
        XCTAssertNotNil(viewModel.transactionTypeSelectionViewModel)
        XCTAssertNotNil(viewModel.dateAdditionalFormViewModel)
        
        // 각 ViewModel이 고유한 ID를 가지는지 확인
        XCTAssertNotEqual(
            viewModel.amountPlacePaymentViewModel.id,
            viewModel.transactionTypeSelectionViewModel.id
        )
        XCTAssertNotEqual(
            viewModel.transactionTypeSelectionViewModel.id,
            viewModel.dateAdditionalFormViewModel.id
        )
    }
    
    // MARK: - Test Methods - Step Management
    
    func test_buttonTapped_fromAmountStep_toTransactionTypeStep() {
        // Given - 첫 번째 단계를 유효하게 설정
        setupValidAmountStep()
        
        // When
        var completionCalled = false
        viewModel.send(.buttonTapped {
            completionCalled = true
        })
        
        // Then
        XCTAssertEqual(viewModel.currentStep, .transactionTypeCategory)
        XCTAssertEqual(viewModel.filteredCompletedStep.count, 1)
        XCTAssertTrue(viewModel.filteredCompletedStep.contains(.amountPlacePaymentMethod))
        XCTAssertEqual(viewModel.buttonTitle, "다음")
        XCTAssertFalse(completionCalled) // 아직 완료되지 않음
    }
    
    func test_buttonTapped_fromTransactionTypeStep_toDateStep() {
        // Given - 첫 번째와 두 번째 단계를 유효하게 설정
        setupValidAmountStep()
        setupValidTransactionTypeStep()
        
        // Move to transaction type step
        viewModel.send(.buttonTapped {})
        
        // When
        var completionCalled = false
        viewModel.send(.buttonTapped {
            completionCalled = true
        })
        
        // Then
        XCTAssertEqual(viewModel.currentStep, .dateAdditional)
        XCTAssertEqual(viewModel.filteredCompletedStep.count, 2)
        XCTAssertTrue(viewModel.filteredCompletedStep.contains(.amountPlacePaymentMethod))
        XCTAssertTrue(viewModel.filteredCompletedStep.contains(.transactionTypeCategory))
        XCTAssertEqual(viewModel.buttonTitle, "완료")
        XCTAssertFalse(completionCalled) // 아직 완료되지 않음
    }
    
    func test_buttonTapped_fromDateStep_callsCreateTransaction() async {
        // Given - 모든 단계를 유효하게 설정
        setupValidAmountStep()
        setupValidTransactionTypeStep()
        setupValidDateStep()
        
        // Move to final step
        viewModel.send(.buttonTapped {})
        viewModel.send(.buttonTapped {})
        
        var completionCalled = false
        let expectation = expectation(description: "Transaction created")
        
        // When
        viewModel.send(.buttonTapped {
            completionCalled = true
            expectation.fulfill()
        })
        
        // Wait for async operation
        await fulfillment(of: [expectation], timeout: 2.0)
        
        // Then
        XCTAssertTrue(completionCalled)
        XCTAssertEqual(mockTransactionEventPublisher.publishedEvents.count, 1)
        XCTAssertEqual(mockTransactionEventPublisher.publishedEvents.first?.type, .created)
    }
    
    // MARK: - Test Methods - Validation
    
    func test_isValid_withInvalidAmountStep_returnsFalse() {
        // Given - Amount step is invalid (no amount set)
        
        // Then
        XCTAssertFalse(viewModel.isValid)
    }
    
    func test_isValid_withValidAmountStep_returnsTrue() {
        // Given
        setupValidAmountStep()
        
        // Then
        XCTAssertTrue(viewModel.isValid)
    }
    
    func test_isValid_withInvalidTransactionTypeStep_returnsFalse() {
        // Given - Move to transaction type step but no subcategory selected
        setupValidAmountStep()
        viewModel.send(.buttonTapped {})
        
        // Then
        XCTAssertFalse(viewModel.isValid)
    }
    
    func test_isValid_withValidTransactionTypeStep_returnsTrue() {
        // Given
        setupValidAmountStep()
        setupValidTransactionTypeStep()
        viewModel.send(.buttonTapped {})
        
        // Then
        XCTAssertTrue(viewModel.isValid)
    }
    
    func test_isValid_atDateStep_alwaysReturnsTrue() {
        // Given - Move to date step
        setupValidAmountStep()
        setupValidTransactionTypeStep()
        viewModel.send(.buttonTapped {})
        viewModel.send(.buttonTapped {})
        
        // Then
        XCTAssertTrue(viewModel.isValid) // Date step은 항상 유효
    }
    
    // MARK: - Test Methods - Button Title
    
    func test_buttonTitle_atAmountStep_returnsNext() {
        // Given - At amount step
        XCTAssertEqual(viewModel.currentStep, .amountPlacePaymentMethod)
        
        // Then
        XCTAssertEqual(viewModel.buttonTitle, "다음")
    }
    
    func test_buttonTitle_atTransactionTypeStep_returnsNext() {
        // Given - Move to transaction type step
        setupValidAmountStep()
        viewModel.send(.buttonTapped {})
        
        // Then
        XCTAssertEqual(viewModel.buttonTitle, "다음")
    }
    
    func test_buttonTitle_atDateStep_returnsComplete() {
        // Given - Move to date step
        setupValidAmountStep()
        setupValidTransactionTypeStep()
        viewModel.send(.buttonTapped {})
        viewModel.send(.buttonTapped {})
        
        // Then
        XCTAssertEqual(viewModel.buttonTitle, "완료")
    }
    
    // MARK: - Test Methods - Data Binding
    
    func test_currentSelectedDate_returnsDateFromDateViewModel() {
        // Given
        let testDate = Date()
        viewModel.dateAdditionalFormViewModel.selectedDate = testDate
        
        // Then
        XCTAssertEqual(viewModel.currentSelectedDate, testDate)
    }
    
    func test_currentMemo_returnsMetaFromDateViewModel() {
        // Given
        let testMemo = "Test memo"
        viewModel.dateAdditionalFormViewModel.memo = testMemo
        
        // Then
        XCTAssertEqual(viewModel.currentMemo, testMemo)
    }
    
    func test_currentIsFavorite_returnsFavoriteFromDateViewModel() {
        // Given
        viewModel.dateAdditionalFormViewModel.isFavorite = true
        
        // Then
        XCTAssertTrue(viewModel.currentIsFavorite)
        
        // When
        viewModel.dateAdditionalFormViewModel.isFavorite = false
        
        // Then
        XCTAssertFalse(viewModel.currentIsFavorite)
    }
    
    // MARK: - Test Methods - Transaction Event Publishing
    
    func test_createTransaction_publishesCorrectEvent() async {
        // Given
        setupValidAmountStep()
        setupValidTransactionTypeStep()
        setupValidDateStep()
        
        // Move to final step and trigger transaction creation
        viewModel.send(.buttonTapped {})
        viewModel.send(.buttonTapped {})
        
        let expectation = expectation(description: "Event published")
        
        // When
        viewModel.send(.buttonTapped {
            expectation.fulfill()
        })
        
        // Wait for async operation
        await fulfillment(of: [expectation], timeout: 2.0)
        
        // Then
        XCTAssertEqual(mockTransactionEventPublisher.publishedEvents.count, 1)
        
        let publishedEvent = mockTransactionEventPublisher.publishedEvents.first
        XCTAssertEqual(publishedEvent?.type, .created)
        XCTAssertNotNil(publishedEvent?.transactionId)

        // Year month should match the date from dateAdditionalFormViewModel
        let expectedYearMonth = YearMonth(from: viewModel.dateAdditionalFormViewModel.selectedDate)
        XCTAssertEqual(publishedEvent?.yearMonth, expectedYearMonth)
    }
    
    // MARK: - Private Helper Methods
    
    private func setupValidAmountStep() {
        viewModel.amountPlacePaymentViewModel.amount = Decimal(50000)
        viewModel.amountPlacePaymentViewModel.place = "Test Place"
        viewModel.amountPlacePaymentViewModel.selectedPaymentMethod = PaymentMethodDTO.mockCreditCard
    }
    
    private func setupValidTransactionTypeStep() {
        viewModel.transactionTypeSelectionViewModel.categoryListViewModel.selectedSubCategory = SubCategoryDTO.mockFoodExpense
        viewModel.transactionTypeSelectionViewModel.selectedTransactionType = .variableExpense
    }
    
    private func setupValidDateStep() {
        viewModel.dateAdditionalFormViewModel.selectedDate = Date()
        viewModel.dateAdditionalFormViewModel.memo = "Test memo"
        viewModel.dateAdditionalFormViewModel.isFavorite = false
    }
}
