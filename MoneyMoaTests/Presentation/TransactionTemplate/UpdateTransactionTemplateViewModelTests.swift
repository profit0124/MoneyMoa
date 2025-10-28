//
//  UpdateTransactionTemplateViewModelTests.swift
//  MoneyMoaTests
//
//  Created by Sooik Kim on 10/15/25.
//

import Testing
import Foundation
import Combine
@testable import MoneyMoa

@MainActor
struct UpdateTransactionTemplateViewModelTests {

    private func makeAmountViewModel(from template: TransactionTemplateDTO) -> AmountPlacePaymentMethodFormViewModel {
        let vm = AmountPlacePaymentMethodFormViewModel(
            getActivePaymentMethodsUseCase: StubGetActivePaymentMethodsUseCase(),
            paymentMethodEventPublisher: TestPaymentMethodEventPublisher(),
            amount: template.amount,
            place: template.place ?? "",
            selectedPaymentMethod: template.paymentMethod
        )
        vm.paymentMethodOptions = [template.paymentMethod]
        return vm
    }

    private func makeTransactionTypeViewModel(from template: TransactionTemplateDTO) -> TransactionTypeCategoryFormViewModel {
        let category = CategoryDTO(
            name: template.subCategory.categoryName,
            iconName: template.subCategory.categoryIconName,
            transactionType: template.transactionType,
            subCategories: [template.subCategory]
        )
        let categoryVM = CategoryListViewModel(
            getCategoriesUseCase: StubGetCategoriesByTypeUseCase(categories: [category]),
            mode: .selection
        )
        categoryVM.categories = [category]
        categoryVM.selectedTransactionType = template.transactionType
        categoryVM.selectedSubCategory = template.subCategory
        return TransactionTypeCategoryFormViewModel(categoryListViewModel: categoryVM)
    }

    private func makePatternViewModel(from template: TransactionTemplateDTO) -> TemplatePatternFormViewModel {
        TemplatePatternFormViewModel(
            memo: template.memo ?? "",
            recurrencePattern: template.recurrencePattern
        )
    }

    private func makeViewModel(
        template: TransactionTemplateDTO,
        updateUseCase: SpyUpdateTransactionTemplateUseCase,
        eventPublisher: TestTransactionTemplateEventPublisher,
        amountViewModel: AmountPlacePaymentMethodFormViewModel? = nil,
        typeViewModel: TransactionTypeCategoryFormViewModel? = nil,
        patternViewModel: TemplatePatternFormViewModel? = nil
    ) -> UpdateTransactionTemplateViewModel {
        let amountVM = amountViewModel ?? makeAmountViewModel(from: template)
        let typeVM = typeViewModel ?? makeTransactionTypeViewModel(from: template)
        let patternVM = patternViewModel ?? makePatternViewModel(from: template)

        return UpdateTransactionTemplateViewModel(
            template: template,
            transactionTemplateEventPublisher: eventPublisher,
            updateTransactionTemplateUseCase: updateUseCase,
            amountPlacePaymentViewModel: amountVM,
            transactionTypeSelectionViewModel: typeVM,
            templatePatternFormViewModel: patternVM
        )
    }

    // MARK: - Tests

    @Test("값이 변경되지 않으면 isValid가 false")
    func testIsValidFalseWhenNothingChanged() async throws {
        // Given
        let template = TestDataFactory.createTransactionTemplate(
            subCategory: .mockFoodExpense,
            paymentMethod: .mockCreditCard
        )
        let viewModel = makeViewModel(
            template: template,
            updateUseCase: SpyUpdateTransactionTemplateUseCase(),
            eventPublisher: TestTransactionTemplateEventPublisher()
        )

        // Then
        #expect(!viewModel.isValid)
    }

    @Test("금액이 변경되면 isValid가 true")
    func testIsValidTrueWhenAmountChanged() async throws {
        // Given
        let template = TestDataFactory.createTransactionTemplate(
            amount: 50_000,
            subCategory: .mockFoodExpense,
            paymentMethod: .mockCreditCard
        )
        let amountVM = makeAmountViewModel(from: template)
        amountVM.amount = 60_000

        let viewModel = makeViewModel(
            template: template,
            updateUseCase: SpyUpdateTransactionTemplateUseCase(),
            eventPublisher: TestTransactionTemplateEventPublisher(),
            amountViewModel: amountVM
        )

        // Then
        #expect(viewModel.isValid)
    }

    @Test("업데이트 시 UseCase 호출, 이벤트 발행, 라우터 dismiss가 수행된다")
    func testUpdateTemplatePublishesEventAndDismisses() async throws {
        // Given
        let template = TestDataFactory.createTransactionTemplate(
            amount: 30_000,
            subCategory: .mockFoodExpense,
            paymentMethod: .mockCreditCard
        )
        let amountVM = makeAmountViewModel(from: template)
        amountVM.amount = 45_000
        amountVM.paymentMethodOptions = [template.paymentMethod]

        let updateUseCase = SpyUpdateTransactionTemplateUseCase()
        let eventPublisher = TestTransactionTemplateEventPublisher()
        let viewModel = makeViewModel(
            template: template,
            updateUseCase: updateUseCase,
            eventPublisher: eventPublisher,
            amountViewModel: amountVM
        )

        let router = AppRouter()
        router.sheet = ModalItem(root: .transactionTemplateAdd, style: .sheet)

        // When
        viewModel.send(.updateTemplate(router))
        try await Task.sleep(for: .milliseconds(30))

        // Then
        #expect(updateUseCase.executeCallCount == 1)
        let updatedTemplate = try #require(updateUseCase.lastTemplate)
        #expect(updatedTemplate.amount == 45_000)
        #expect(updatedTemplate.recurrencePattern == template.recurrencePattern)

        let event = try #require(eventPublisher.publishedEvents.first)
        #expect(event.type == .updated)
        #expect(event.template.amount == 45_000)

        #expect(router.sheet == nil)
    }
}

// MARK: - Test Doubles

@MainActor
private final class SpyUpdateTransactionTemplateUseCase: UpdateTransactionTemplateUseCase {
    private(set) var executeCallCount = 0
    private(set) var lastTemplate: TransactionTemplateDTO?

    func execute(_ template: TransactionTemplateDTO) async throws {
        executeCallCount += 1
        lastTemplate = template
    }
}
