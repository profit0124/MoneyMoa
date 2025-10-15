//
//  AddTransactionTemplateViewModelTests.swift
//  MoneyMoaTests
//
//  Created by Sooik Kim on 10/15/25.
//

import Testing
import Foundation
import Combine
@testable import MoneyMoa

@MainActor
struct AddTransactionTemplateViewModelTests {

    // MARK: - Helpers

    private func makeAmountViewModel(
        amount: Decimal? = nil,
        place: String = "",
        paymentMethod: PaymentMethodDTO? = nil
    ) -> AmountPlacePaymentMethodFormViewModel {
        let vm = AmountPlacePaymentMethodFormViewModel(
            getActivePaymentMethodsUseCase: StubGetActivePaymentMethodsUseCase(),
            createPaymentMethodUseCase: StubCreatePaymentMethodUseCase(),
            amount: amount,
            place: place,
            selectedPaymentMethod: paymentMethod
        )
        return vm
    }

    private func makeTransactionTypeViewModel(
        subCategory: SubCategoryDTO? = nil,
        transactionType: TransactionType = .variableExpense
    ) -> TransactionTypeCategoryFormViewModel {
        let category = CategoryDTO(
            name: subCategory?.categoryName ?? "식비",
            iconName: subCategory?.categoryIconName ?? "fork.knife",
            transactionType: transactionType,
            subCategories: subCategory.map { [$0] } ?? []
        )

        let categoryListViewModel = CategoryListViewModel(
            getCategoriesUseCase: StubGetCategoriesByTypeUseCase(categories: [category]),
            mode: .selection
        )
        categoryListViewModel.categories = [category]
        categoryListViewModel.selectedTransactionType = transactionType
        categoryListViewModel.selectedSubCategory = subCategory

        return TransactionTypeCategoryFormViewModel(categoryListViewModel: categoryListViewModel)
    }

    private func makeTemplatePatternViewModel() -> TemplatePatternFormViewModel {
        TemplatePatternFormViewModel(
            memo: "정기결제",
            recurrencePattern: RecurrencePattern.weekly(on: 2, hour: 9, minute: 0)
        )
    }

    private func makeViewModel(
        amountViewModel: AmountPlacePaymentMethodFormViewModel,
        typeViewModel: TransactionTypeCategoryFormViewModel,
        patternViewModel: TemplatePatternFormViewModel,
        createUseCase: SpyCreateTransactionTemplateUseCase,
        eventPublisher: TestTransactionTemplateEventPublisher
    ) -> AddTransactionTemplateViewModel {
        AddTransactionTemplateViewModel(
            transactionTemplateEventPublisher: eventPublisher,
            createTransactionTemplateUseCase: createUseCase,
            amountPlacePaymentViewModel: amountViewModel,
            transactionTypeSelectionViewModel: typeViewModel,
            templatePatternFormViewModel: patternViewModel
        )
    }

    // MARK: - Tests

    @Test("버튼 탭 시 단계가 순차적으로 진행된다")
    func testStepProgression() async throws {
        // Given
        let createUseCase = SpyCreateTransactionTemplateUseCase()
        let eventPublisher = TestTransactionTemplateEventPublisher()
        let amountVM = makeAmountViewModel()
        let typeVM = makeTransactionTypeViewModel()
        let patternVM = makeTemplatePatternViewModel()

        let viewModel = makeViewModel(
            amountViewModel: amountVM,
            typeViewModel: typeVM,
            patternViewModel: patternVM,
            createUseCase: createUseCase,
            eventPublisher: eventPublisher
        )

        // When
        viewModel.send(.buttonTapped({}))

        // Then
        #expect(viewModel.currentStep == .transactionTypeCategory)
        #expect(viewModel.filteredCompletedStep == [.amountPlacePaymentMethod])

        // When
        viewModel.send(.buttonTapped({}))

        // Then
        #expect(viewModel.currentStep == .patternAdditional)
        #expect(viewModel.filteredCompletedStep == [.amountPlacePaymentMethod, .transactionTypeCategory])
    }

    @Test("필수 입력이 없으면 템플릿 생성이 호출되지 않는다")
    func testCreateTemplateFailsWhenRequiredInputsMissing() async throws {
        // Given
        let createUseCase = SpyCreateTransactionTemplateUseCase()
        let eventPublisher = TestTransactionTemplateEventPublisher()

        let amountVM = makeAmountViewModel() // amount == nil, paymentMethod == nil
        let typeVM = makeTransactionTypeViewModel()
        let patternVM = makeTemplatePatternViewModel()

        let viewModel = makeViewModel(
            amountViewModel: amountVM,
            typeViewModel: typeVM,
            patternViewModel: patternVM,
            createUseCase: createUseCase,
            eventPublisher: eventPublisher
        )

        // 현재 단계 패턴으로 이동
        viewModel.send(.buttonTapped({})) // -> transactionTypeCategory
        viewModel.send(.buttonTapped({})) // -> patternAdditional

        // When
        viewModel.send(.buttonTapped({}))
        try await Task.sleep(for: .milliseconds(20))

        // Then
        #expect(createUseCase.executeCallCount == 0)
        #expect(eventPublisher.publishedEvents.isEmpty)
    }

    @Test("정상 입력 시 템플릿을 생성하고 이벤트를 발행한다")
    func testCreateTemplateSuccessPublishesEvent() async throws {
        // Given
        let createUseCase = SpyCreateTransactionTemplateUseCase()
        let eventPublisher = TestTransactionTemplateEventPublisher()

        let paymentMethod = PaymentMethodDTO.mockCreditCard
        let subCategory = SubCategoryDTO.mockFoodExpense

        let amountVM = makeAmountViewModel(
            amount: 25_000,
            place: "커피숍",
            paymentMethod: paymentMethod
        )
        amountVM.paymentMethodOptions = [paymentMethod]
        let typeVM = makeTransactionTypeViewModel(
            subCategory: subCategory,
            transactionType: subCategory.transactionType
        )
        let patternVM = makeTemplatePatternViewModel()

        let viewModel = makeViewModel(
            amountViewModel: amountVM,
            typeViewModel: typeVM,
            patternViewModel: patternVM,
            createUseCase: createUseCase,
            eventPublisher: eventPublisher
        )

        // When
        viewModel.send(.buttonTapped({})) // step -> transactionTypeCategory
        viewModel.send(.buttonTapped({})) // step -> patternAdditional
        viewModel.send(.buttonTapped({})) // attempt create
        try await Task.sleep(for: .milliseconds(30))

        // Then
        #expect(createUseCase.executeCallCount == 1)
        let createdTemplate = try #require(createUseCase.lastTemplate)
        #expect(createdTemplate.amount == 25_000)
        #expect(createdTemplate.place == "커피숍")
        #expect(createdTemplate.paymentMethod == paymentMethod)
        #expect(createdTemplate.subCategory == subCategory)
        #expect(createdTemplate.recurrencePattern == patternVM.recurrencePattern)
        #expect(createdTemplate.executionState.executionCount == 0)
        #expect(createdTemplate.executionState.lastExecutedAt == nil)

        let publishedEvent = try #require(eventPublisher.publishedEvents.first)
        #expect(publishedEvent.type == .created)
        #expect(publishedEvent.template.amount == createdTemplate.amount)
        #expect(publishedEvent.template.paymentMethod == paymentMethod)
    }
}

// MARK: - Test Doubles

@MainActor
private final class SpyCreateTransactionTemplateUseCase: CreateTransactionTemplateUseCase {
    private(set) var executeCallCount = 0
    private(set) var lastTemplate: TransactionTemplateDTO?

    func execute(_ template: TransactionTemplateDTO) async throws {
        executeCallCount += 1
        lastTemplate = template
    }
}

private final class TestTransactionTemplateEventPublisher: TransactionTemplateEventPublisher {
    private let subject = PassthroughSubject<TransactionTemplateEvent, Never>()
    private(set) var publishedEvents: [TransactionTemplateEvent] = []

    var transactionTemplateEvents: AnyPublisher<TransactionTemplateEvent, Never> {
        subject.eraseToAnyPublisher()
    }

    func publish(_ event: TransactionTemplateEvent) {
        publishedEvents.append(event)
        subject.send(event)
    }
}

private final class StubGetActivePaymentMethodsUseCase: GetActivePaymentMethodsUseCase {
    var result: [PaymentMethodDTO]

    init(result: [PaymentMethodDTO] = []) {
        self.result = result
    }

    func execute() async throws -> [PaymentMethodDTO] {
        result
    }
}

@MainActor
private final class StubCreatePaymentMethodUseCase: CreatePaymentMethodUseCase {
    func execute(_ paymentMethod: PaymentMethodDTO) async throws {}
}

@MainActor
private final class StubGetCategoriesByTypeUseCase: GetCategoriesByTypeUseCase {
    var categories: [CategoryDTO]

    init(categories: [CategoryDTO]) {
        self.categories = categories
    }

    func execute(_ type: TransactionType) async throws -> [CategoryDTO] {
        categories
    }
}
