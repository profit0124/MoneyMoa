//
//  UpdateTransactionTemplateViewModel.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/24/25.
//

import Foundation
import Observation
import Combine

@Observable
final class UpdateTransactionTemplateViewModel {

    private let transactionTemplateEventPublisher: TransactionTemplateEventPublisher

    // MARK: - Dependencies

    private let updateTransactionTemplateUseCase: UpdateTransactionTemplateUseCase

    // MARK: - Original Data

    let template: TransactionTemplateDTO

    // MARK: - Child ViewModels

    let amountPlacePaymentViewModel: AmountPlacePaymentMethodFormViewModel
    let transactionTypeSelectionViewModel: TransactionTypeCategoryFormViewModel
    let templatePatternFormViewModel: TemplatePatternFormViewModel

    // MARK: - Computed Properties

    var isValid: Bool {
        // 기존 템플릿과 비교해서 변경사항이 있는지 확인 (createdAt 제외)
        (template.amount != amountPlacePaymentViewModel.amount &&
         amountPlacePaymentViewModel.amount ?? 0 > 0) ||
        template.place != amountPlacePaymentViewModel.place ||
        template.paymentMethod != amountPlacePaymentViewModel.selectedPaymentMethod ||
        template.transactionType != transactionTypeSelectionViewModel.selectedTransactionType ||
        template.subCategory != transactionTypeSelectionViewModel.selectedSubCategory ||
        template.memo != templatePatternFormViewModel.memo ||
        template.recurrencePattern != templatePatternFormViewModel.recurrencePattern
    }

    init(
        template: TransactionTemplateDTO,
        transactionTemplateEventPublisher: TransactionTemplateEventPublisher,
        updateTransactionTemplateUseCase: UpdateTransactionTemplateUseCase,
        amountPlacePaymentViewModel: AmountPlacePaymentMethodFormViewModel,
        transactionTypeSelectionViewModel: TransactionTypeCategoryFormViewModel,
        templatePatternFormViewModel: TemplatePatternFormViewModel
    ) {
        self.template = template
        self.transactionTemplateEventPublisher = transactionTemplateEventPublisher
        self.updateTransactionTemplateUseCase = updateTransactionTemplateUseCase
        self.amountPlacePaymentViewModel = amountPlacePaymentViewModel
        self.transactionTypeSelectionViewModel = transactionTypeSelectionViewModel
        self.templatePatternFormViewModel = templatePatternFormViewModel
    }

    // MARK: - Actions

    enum Action {
        case updateTemplate(AppRouter)
        case cancelButtonTapped(AppRouter)
    }

    func send(_ action: Action) {
        switch action {
        case .updateTemplate(let router):
            Task {
                do {
                    try await updateTemplate()
                    send(.cancelButtonTapped(router))
                } catch {
                    print("템플릿 업데이트 실패: \(error)")
                }
            }

        case .cancelButtonTapped(let router):
            cancelButtonTapped(router)
        }
    }

    // MARK: - Private Methods

    private func updateTemplate() async throws {
        guard let amount = amountPlacePaymentViewModel.amount,
              let subCategory = transactionTypeSelectionViewModel.selectedSubCategory,
              let paymentMethod = amountPlacePaymentViewModel.selectedPaymentMethod else {
            throw TransactionTemplateUpdateError.invalidAmount
        }

        let updatedTemplate = TransactionTemplateDTO(
            id: template.id,
            amount: amount,
            place: amountPlacePaymentViewModel.place,
            memo: templatePatternFormViewModel.memo,
            transactionType: transactionTypeSelectionViewModel.selectedTransactionType,
            recurrencePeriod: templatePatternFormViewModel.recurrencePattern.period,
            createdAt: template.createdAt, // 원래 템플릿의 생성일 유지
            subCategory: subCategory,
            paymentMethod: paymentMethod,
            recurrencePattern: templatePatternFormViewModel.recurrencePattern,
            executionState: template.executionState // 기존 실행 상태 유지
        )

        try await updateTransactionTemplateUseCase.execute(updatedTemplate)
        transactionTemplateEventPublisher.publish(.init(type: .updated, template: updatedTemplate))
    }

    private func cancelButtonTapped(_ router: AppRouter) {
        Task { @MainActor in
            router.dismissModal()
        }
    }
}
