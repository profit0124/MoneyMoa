//
//  AmountPlacePaymentMethodFormViewModelTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 8/19/25.
//

import XCTest
@testable import MoneyMoa

// MARK: - AmountPlacePaymentMethodFormViewModelTests

@MainActor
final class AmountPlacePaymentMethodFormViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var viewModel: AmountPlacePaymentMethodFormViewModel!
    private var mockContainer: MockDIContainer!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        
        mockContainer = MockDIContainer()
        viewModel = mockContainer.makeAmountPlacePaymentMethodFormViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        mockContainer = nil
        super.tearDown()
    }
    
    // MARK: - Test Methods - Initialization
    
    func test_initialization_setsCorrectInitialValues() {
        // Then
        XCTAssertNil(viewModel.amount)
        XCTAssertEqual(viewModel.place, "")
        XCTAssertNil(viewModel.selectedPaymentMethod)
        XCTAssertNotNil(viewModel.id)
    }
    
    func test_initialization_loadsPaymentMethods() {
        // When
        viewModel.send(.onAppear)
        
        // Wait for async loading
        let expectation = expectation(description: "Payment methods loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertFalse(viewModel.paymentMethodOptions.isEmpty)
    }
    
    // MARK: - Test Methods - Actions
    
    func test_send_setDecimalAmount_updatesAmountValue() {
        // Given
        let testAmount = "50000"
        
        // When
        viewModel.send(.setDecimalAmount(testAmount))
        
        // Then
        XCTAssertEqual(viewModel.amount, Decimal(50000))
    }
    
    func test_send_setDecimalAmount_withEmptyString_setsAmountToNil() {
        // Given
        viewModel.send(.setDecimalAmount("50000"))
        XCTAssertNotNil(viewModel.amount)
        
        // When
        viewModel.send(.setDecimalAmount(""))
        
        // Then
        XCTAssertNil(viewModel.amount)
    }
    
    func test_send_setDecimalAmount_withNonNumericCharacters_extractsNumbersOnly() {
        // Given
        let testInput = "abc50,000def"
        
        // When
        viewModel.send(.setDecimalAmount(testInput))
        
        // Then
        XCTAssertEqual(viewModel.amount, Decimal(50000))
    }
    
    func test_send_setDecimalAmount_withLeadingZeros_removesLeadingZeros() {
        // Given
        let testInput = "000123"
        
        // When
        viewModel.send(.setDecimalAmount(testInput))
        
        // Then
        XCTAssertEqual(viewModel.amount, Decimal(123))
    }
    
    func test_send_setSelectedPaymentMethod_updatesSelectedPaymentMethod() {
        // Given
        let testPaymentMethod = PaymentMethodDTO.mockCreditCard
        viewModel.send(.onAppear)
        
        // Wait for payment methods to load
        let expectation = expectation(description: "Payment methods loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // When
        viewModel.send(.setSelectedPaymentMethod(testPaymentMethod))
        
        // Then
        XCTAssertEqual(viewModel.selectedPaymentMethod?.id, testPaymentMethod.id)
        XCTAssertEqual(viewModel.selectedPaymentMethod?.name, testPaymentMethod.name)
    }
    
    // MARK: - Test Methods - Validation
    
    func test_isValid_withNilAmount_returnsFalse() {
        // Given - Amount가 nil인 상태
        viewModel.amount = nil
        viewModel.place = "Test Place"
        viewModel.selectedPaymentMethod = PaymentMethodDTO.mockCreditCard
        
        // Then
        XCTAssertFalse(viewModel.isValid)
    }
    
    func test_isValid_withZeroAmount_returnsFalse() {
        // Given - Amount가 0인 상태
        viewModel.amount = Decimal(0)
        viewModel.place = "Test Place"
        viewModel.selectedPaymentMethod = PaymentMethodDTO.mockCreditCard
        
        // Then
        XCTAssertFalse(viewModel.isValid)
    }
    
    func test_isValid_withNegativeAmount_returnsFalse() {
        // Given - Amount가 음수인 상태
        viewModel.amount = Decimal(-1000)
        viewModel.place = "Test Place"
        viewModel.selectedPaymentMethod = PaymentMethodDTO.mockCreditCard
        
        // Then
        XCTAssertFalse(viewModel.isValid)
    }
    
    func test_isValid_withoutSelectedPaymentMethod_returnsFalse() {
        // Given - PaymentMethod가 선택되지 않은 상태
        viewModel.amount = Decimal(50000)
        viewModel.place = "Test Place"
        viewModel.selectedPaymentMethod = nil
        
        // Then
        XCTAssertFalse(viewModel.isValid)
    }
    
    func test_isValid_withValidAmountAndPaymentMethod_returnsTrue() {
        // Given - 유효한 금액과 결제수단이 있는 상태 (place는 선택사항)
        viewModel.amount = Decimal(50000)
        viewModel.selectedPaymentMethod = PaymentMethodDTO.mockCreditCard
        
        // Then
        XCTAssertTrue(viewModel.isValid)
    }
    
    func test_isValid_withEmptyPlace_stillValid() {
        // Given - Place가 비어있어도 유효 (place는 필수가 아님)
        viewModel.amount = Decimal(50000)
        viewModel.place = ""
        viewModel.selectedPaymentMethod = PaymentMethodDTO.mockCreditCard
        
        // Then
        XCTAssertTrue(viewModel.isValid)
    }
    
    // MARK: - Test Methods - Computed Properties
    
    func test_formattedAmount_withValidAmount_returnsFormattedString() {
        // Given
        viewModel.amount = Decimal(50000)
        
        // When
        let formatted = viewModel.formattedAmount
        
        // Then
        XCTAssertFalse(formatted.isEmpty)
        XCTAssertTrue(formatted.contains("50,000") || formatted.contains("50000"))
    }
    
    func test_formattedAmount_withNilAmount_returnsEmptyString() {
        // Given
        viewModel.amount = nil
        
        // When
        let formatted = viewModel.formattedAmount
        
        // Then
        XCTAssertEqual(formatted, "")
    }
    
    func test_summary_withAllData_returnsCompleteInfo() {
        // Given
        viewModel.amount = Decimal(15000)
        viewModel.place = "스타벅스"
        viewModel.selectedPaymentMethod = PaymentMethodDTO.mockCreditCard
        
        // When
        let summary = viewModel.summary
        
        // Then
        XCTAssertTrue(summary.contains("15,000") || summary.contains("₩"))
        XCTAssertTrue(summary.contains("스타벅스"))
        XCTAssertTrue(summary.contains("신용카드"))
    }
    
    func test_summary_withNoData_returnsDefaultMessage() {
        // Given - 모든 데이터가 비어있는 상태
        viewModel.amount = nil
        viewModel.place = ""
        viewModel.selectedPaymentMethod = nil
        
        // When
        let summary = viewModel.summary
        
        // Then
        XCTAssertEqual(summary, "정보 없음")
    }
    
    // MARK: - Test Methods - Focus Management
    
    func test_send_setFocus_updatesFocusField() {
        // When
        viewModel.send(.setFocus(.amount))
        
        // Then
        XCTAssertEqual(viewModel.focusField, .amount)
        
        // When
        viewModel.send(.setFocus(.place))
        
        // Then
        XCTAssertEqual(viewModel.focusField, .place)
    }
    
    func test_send_setFocus_nil_setsAutomaticFocus() {
        // Given - amount가 nil인 상태
        viewModel.amount = nil
        viewModel.place = ""
        
        // When
        viewModel.send(.setFocus(nil))
        
        // Then - amount 필드에 자동 포커스
        XCTAssertEqual(viewModel.focusField, .amount)
    }
    
    // MARK: - Test Methods - Payment Method Management
    
    func test_send_presentPaymentMethodForm_createsFormViewModel() {
        // When
        viewModel.send(.presentPaymentMethodForm)
        
        // Then
        XCTAssertNotNil(viewModel.paymentMethodFormViewModel)
    }
    
    func test_send_addPaymentMethod_addsToOptions() {
        // Given
        let initialCount = viewModel.paymentMethodOptions.count
        let newPaymentMethod = PaymentMethodDTO.mockDebitCard
        
        // When
        viewModel.send(.addPaymentMethod(newPaymentMethod))
        
        // Then
        XCTAssertEqual(viewModel.paymentMethodOptions.count, initialCount + 1)
        XCTAssertTrue(viewModel.paymentMethodOptions.contains { $0.id == newPaymentMethod.id })
    }
    
    // MARK: - Test Methods - Data Consistency
    
    func test_paymentMethodOptions_afterOnAppear_containsExpectedMethods() async {
        // When
        viewModel.send(.onAppear)
        
        // Wait for async loading
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Then
        XCTAssertFalse(viewModel.paymentMethodOptions.isEmpty)
    }
    
    // MARK: - Test Methods - Observable Pattern
    
    func test_amountUpdate_triggersPropertyChange() {
        // Given
        let initialAmount = viewModel.amount
        
        // When
        viewModel.send(.setDecimalAmount("75000"))
        
        // Then
        XCTAssertNotEqual(viewModel.amount, initialAmount)
        XCTAssertEqual(viewModel.amount, Decimal(75000))
    }
    
    func test_paymentMethodSelection_triggersPropertyChange() {
        // Given
        let initialSelection = viewModel.selectedPaymentMethod
        let newSelection = PaymentMethodDTO.mockCash
        
        // When
        viewModel.send(.setSelectedPaymentMethod(newSelection))
        
        // Then
        XCTAssertNotEqual(viewModel.selectedPaymentMethod?.id, initialSelection?.id)
        XCTAssertEqual(viewModel.selectedPaymentMethod?.id, newSelection.id)
    }
}
