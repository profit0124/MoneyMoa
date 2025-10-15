//
//  UpdateTransactionUseCaseTests.swift
//  MoneyMoaTests
//
//  Created by profit on 8/20/25.
//

import XCTest
@testable import MoneyMoa

final class UpdateTransactionUseCaseTests: XCTestCase {
    
    // MARK: - Properties

    private var mockTransactionRepository: MockTransactionRepository!
    private var mockTemplateRepository: MockTransactionTemplateRepository!
    private var useCase: UpdateTransactionUseCaseImpl!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mockTransactionRepository = MockTransactionRepository(scenario: .empty)
        mockTemplateRepository = MockTransactionTemplateRepository(scenario: .empty)
        useCase = UpdateTransactionUseCaseImpl(
            transactionWriter: mockTransactionRepository,
            templateWriter: mockTemplateRepository
        )
    }

    override func tearDown() {
        mockTransactionRepository = nil
        mockTemplateRepository = nil
        useCase = nil
        super.tearDown()
    }
    
    // MARK: - Test Methods - Successful Update
    
    func test_execute_withValidTransaction_updatesSuccessfully() async throws {
        // Given
        let originalTransaction = TransactionFactory.sample()
        try await mockTransactionRepository.insertTransaction(originalTransaction)

        let updatedTransaction = TransactionDTO(
            id: originalTransaction.id,
            amount: 75000,  // Changed from original
            date: originalTransaction.date,
            place: "Updated Place",  // Changed from original
            memo: "Updated Memo",    // Changed from original
            transactionType: originalTransaction.transactionType,
            subCategory: originalTransaction.subCategory,
            paymentMethod: originalTransaction.paymentMethod
        )

        // When
        try await useCase.execute(updatedTransaction)

        // Then
        let storedTransaction = try await mockTransactionRepository.fetchTransaction(id: originalTransaction.id)
        XCTAssertNotNil(storedTransaction)
        XCTAssertEqual(storedTransaction?.amount, 75000)
        XCTAssertEqual(storedTransaction?.place, "Updated Place")
        XCTAssertEqual(storedTransaction?.memo, "Updated Memo")
    }
    
    // MARK: - Test Methods - Error Cases
    
    func test_execute_withInvalidAmount_throwsError() async {
        // Given
        let transaction = TransactionDTO(
            amount: 0,  // Invalid amount
            place: "Test Place",
            memo: "Test Memo",
            transactionType: .variableExpense,
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCreditCard
        )
        
        // When & Then
        do {
            try await useCase.execute(transaction)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is TransactionUpdateError)
        }
    }
    
    func test_execute_withNegativeAmount_throwsError() async {
        // Given
        let transaction = TransactionDTO(
            amount: -1000,  // Negative amount
            place: "Test Place", 
            memo: "Test Memo",
            transactionType: .variableExpense,
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCreditCard
        )
        
        // When & Then
        do {
            try await useCase.execute(transaction)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is TransactionUpdateError)
        }
    }
    
    func test_execute_withRepositoryFailure_propagatesError() async {
        // Given
        let transaction = TransactionFactory.sample()
        mockTransactionRepository.shouldFail = true

        // When & Then
        do {
            try await useCase.execute(transaction)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is MockError)
        }
    }
    
    // MARK: - Test Methods - Business Logic Validation
    
    func test_execute_validatesBusinessRules() async throws {
        // Given
        let originalTransaction = TransactionFactory.sample()
        try await mockTransactionRepository.insertTransaction(originalTransaction)

        let validTransaction = TransactionDTO(
            id: originalTransaction.id,
            amount: 150000,  // Valid positive amount
            date: originalTransaction.date,
            place: "Business Rule Test",
            memo: "Testing business logic validation",
            transactionType: originalTransaction.transactionType,
            subCategory: originalTransaction.subCategory,
            paymentMethod: originalTransaction.paymentMethod
        )

        // When
        try await useCase.execute(validTransaction)

        // Then
        let updatedTransaction = try await mockTransactionRepository.fetchTransaction(id: originalTransaction.id)
        XCTAssertNotNil(updatedTransaction, "실제 UseCase 비즈니스 로직이 실행되어 거래가 업데이트되어야 함")
        XCTAssertEqual(updatedTransaction?.amount, 150000, "금액 검증 로직이 올바르게 동작해야 함")
        XCTAssertEqual(updatedTransaction?.place, "Business Rule Test")
    }

    // MARK: - Test Methods - Template Update Strategy

    func test_execute_withUpdateWithTemplateStrategy_updatesTemplate() async throws {
        // Given: 템플릿이 있는 거래 생성
        let template = TransactionTemplateDTO(
            amount: 50000,
            place: "Original Place",
            memo: "Original Memo",
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
        try await mockTemplateRepository.insertTemplate(template)

        let transaction = TransactionDTO(
            amount: 75000,  // Changed
            date: Date(),
            place: "Updated Place",  // Changed
            memo: "Updated Memo",  // Changed
            transactionType: .variableExpense,
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCreditCard,
            transactionTemplate: template
        )
        try await mockTransactionRepository.insertTransaction(transaction)

        // When: .updateWithTemplate 전략으로 실행
        try await useCase.execute(transaction, strategy: .updateWithTemplate)

        // Then: 템플릿이 업데이트 되어야 함
        let updatedTemplate = try await mockTemplateRepository.fetchTemplate(id: template.id)
        XCTAssertNotNil(updatedTemplate)
        XCTAssertEqual(updatedTemplate?.amount, 75000, "템플릿 금액이 거래 금액으로 동기화되어야 함")
        XCTAssertEqual(updatedTemplate?.place, "Updated Place", "템플릿 장소가 거래 장소로 동기화되어야 함")
        XCTAssertEqual(updatedTemplate?.memo, "Updated Memo", "템플릿 메모가 거래 메모로 동기화되어야 함")
        XCTAssertEqual(updatedTemplate?.recurrencePeriod, .monthly, "반복 주기는 유지되어야 함")
    }

    func test_execute_withUpdateWithTemplateStrategy_recalculatesNextDueDate() async throws {
        // Given: 과거 날짜의 거래와 템플릿
        let pastDate = Date().addingTimeInterval(-86400 * 15)  // 15일 전
        let oldNextDueDate = Date().addingTimeInterval(86400 * 30)  // 30일 후

        let template = TransactionTemplateDTO(
            amount: 50000,
            place: "Test",
            memo: "Test",
            transactionType: .variableExpense,
            recurrencePeriod: .monthly,
            createdAt: pastDate,
            lastAddedAt: pastDate,
            nextDueDate: oldNextDueDate,
            timeContext: .current,
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCreditCard,
            recurrencePattern: RecurrencePattern(from: pastDate, period: .monthly, calendar: .current),
            executionState: TemplateExecutionState(lastExecutedAt: pastDate, executionCount: 1)
        )
        try await mockTemplateRepository.insertTemplate(template)

        let transaction = TransactionDTO(
            amount: 60000,
            date: Date(),  // 오늘
            place: "Test",
            memo: "Test",
            transactionType: .variableExpense,
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCreditCard,
            transactionTemplate: template
        )
        try await mockTransactionRepository.insertTransaction(transaction)

        // When: .updateWithTemplate 전략으로 실행
        try await useCase.execute(transaction, strategy: .updateWithTemplate)

        // Then: nextDueDate가 재계산되어야 함
        let updatedTemplate = try await mockTemplateRepository.fetchTemplate(id: template.id)
        XCTAssertNotNil(updatedTemplate)
        XCTAssertNotEqual(updatedTemplate?.nextDueDate, oldNextDueDate, "nextDueDate가 재계산되어야 함")

        // nextDueDate가 현재 이후여야 함
        if let newNextDueDate = updatedTemplate?.nextDueDate {
            XCTAssertGreaterThan(newNextDueDate, Date(), "nextDueDate는 현재 시간 이후여야 함")
        }
    }

    func test_execute_withNoneStrategy_doesNotUpdateTemplate() async throws {
        // Given: 템플릿이 있는 거래
        let template = TransactionTemplateDTO(
            amount: 50000,
            place: "Original Place",
            memo: "Original Memo",
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
        try await mockTemplateRepository.insertTemplate(template)

        let transaction = TransactionDTO(
            amount: 75000,  // Changed
            date: Date(),
            place: "Updated Place",  // Changed
            memo: "Updated Memo",  // Changed
            transactionType: .variableExpense,
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCreditCard,
            transactionTemplate: template
        )
        try await mockTransactionRepository.insertTransaction(transaction)

        // When: .none 전략으로 실행 (템플릿 업데이트 안 함)
        try await useCase.execute(transaction, strategy: .none)

        // Then: 템플릿이 변경되지 않아야 함
        let unchangedTemplate = try await mockTemplateRepository.fetchTemplate(id: template.id)
        XCTAssertNotNil(unchangedTemplate)
        XCTAssertEqual(unchangedTemplate?.amount, 50000, "템플릿 금액이 변경되지 않아야 함")
        XCTAssertEqual(unchangedTemplate?.place, "Original Place", "템플릿 장소가 변경되지 않아야 함")
        XCTAssertEqual(unchangedTemplate?.memo, "Original Memo", "템플릿 메모가 변경되지 않아야 함")
    }

    func test_execute_withUpdateWithTemplateStrategy_withoutTemplate_doesNothing() async throws {
        // Given: 템플릿이 없는 거래
        let transaction = TransactionDTO(
            amount: 75000,
            date: Date(),
            place: "Test Place",
            memo: "Test Memo",
            transactionType: .variableExpense,
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCreditCard,
            transactionTemplate: nil  // 템플릿 없음
        )
        try await mockTransactionRepository.insertTransaction(transaction)

        // When: .updateWithTemplate 전략으로 실행 (템플릿이 없으므로 early return)
        try await useCase.execute(transaction, strategy: .updateWithTemplate)

        // Then: 에러 없이 정상 실행되어야 함 (early return으로 인해 템플릿 업데이트 시도하지 않음)
        let updatedTransaction = try await mockTransactionRepository.fetchTransaction(id: transaction.id)
        XCTAssertNotNil(updatedTransaction)
        XCTAssertEqual(updatedTransaction?.amount, 75000)
    }
}
