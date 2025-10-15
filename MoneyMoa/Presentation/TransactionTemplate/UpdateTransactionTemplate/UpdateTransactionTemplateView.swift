//
//  UpdateTransactionTemplateView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/24/25.
//

import SwiftUI

struct UpdateTransactionTemplateView: View {
    @Environment(AppRouter.self) private var router

    @State private var viewModel: UpdateTransactionTemplateViewModel
    @State private var cardCoordinator: BasicCardFormCoordinator

    init(viewModel: UpdateTransactionTemplateViewModel) {
        self._viewModel = State(initialValue: viewModel)
        let ids: [String] = [
            viewModel.amountPlacePaymentViewModel.id.uuidString,
            viewModel.transactionTypeSelectionViewModel.id.uuidString,
            viewModel.templatePatternFormViewModel.id.uuidString
        ]
        self._cardCoordinator = State(
            initialValue: UpdateTransactionFormCoordinator(ids)
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(TransactionTemplateStep.allCases, id: \.self) {
                    stepView($0, isCompleted: true)
                }
            }
        }
        .environment(cardCoordinator)
        .navigationTitle("템플릿 수정")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("취소") {
                    viewModel.send(.cancelButtonTapped(router))
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("수정") {
                    viewModel.send(.updateTemplate(router))
                }
                .disabled(!viewModel.isValid)
            }
        }
    }

    @ViewBuilder
    private func stepView(_ step: TransactionTemplateStep, isCompleted: Bool) -> some View {
        Group {
            switch step {
            case .amountPlacePaymentMethod:
                AmountPlacePaymentMethodFormView(
                    viewModel: viewModel.amountPlacePaymentViewModel
                )

            case .transactionTypeCategory:
                TransactionTypeCategoryFormView(
                    viewModel: viewModel.transactionTypeSelectionViewModel
                )

            case .patternAdditional:
                TemplatePatternFormView(
                    viewModel: viewModel.templatePatternFormViewModel
                )
            }
        }
        .cardFormContainer(
            cardId: getStepID(step),
            formType: .update,
            title: step.title,
            subtitle: step.subtitle,
            stepNumber: step.stepNumber,
            summary: getSummary(step),
            isCompleted: isCompleted
        )
    }

    private func getStepID(_ step: TransactionTemplateStep) -> String {
        switch step {
        case .amountPlacePaymentMethod:
            return viewModel.amountPlacePaymentViewModel.id.uuidString
        case .transactionTypeCategory:
            return viewModel.transactionTypeSelectionViewModel.id.uuidString
        case .patternAdditional:
            return viewModel.templatePatternFormViewModel.id.uuidString
        }
    }

    private func getSummary(_ step: TransactionTemplateStep) -> String {
        switch step {
        case .amountPlacePaymentMethod:
            return viewModel.amountPlacePaymentViewModel.summary
        case .transactionTypeCategory:
            return viewModel.transactionTypeSelectionViewModel.summary
        case .patternAdditional:
            return viewModel.templatePatternFormViewModel.summary
        }
    }
}

// MARK: - Preview

#Preview("Monthly Subscription") {
    let container = DIContainerFactory.createForPreview()
    let router = AppRouter()

    let monthlyTemplate = TransactionTemplateDTO(
        amount: 17000,
        place: "넷플릭스",
        memo: "월간 구독료",
        transactionType: .fixedExpense,
        createdAt: Date(),
        subCategory: .mockEntertainment,
        paymentMethod: .mockCreditCard,
        recurrencePattern: RecurrencePattern.monthly(on: 1),
        executionState: TemplateExecutionState(
            lastExecutedAt: nil,
            executionCount: 0
        )
    )
    NavigationStack {
        UpdateTransactionTemplateView(
            viewModel: container.makeUpdateTransactionTemplateViewModel(
                template: monthlyTemplate
            )
        )
    }
    .environment(router)
}
