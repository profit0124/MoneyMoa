//
//  UpdateTransactionView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/10/25.
//

import SwiftUI

struct UpdateTransactionView: View {

    @State private var viewModel: UpdateTransactionViewModel
    @State private var cardCoordinator: BasicCardFormCoordinator

    init(viewModel: UpdateTransactionViewModel) {
        self._viewModel = State(initialValue: viewModel)
        let ids: [String] = [
            viewModel.amountPlacePaymentViewModel.id.uuidString,
            viewModel.transactionTypeSelectionViewModel.id.uuidString,
            viewModel.dateAdditionalFormViewModel.id.uuidString
        ]
        self._cardCoordinator = State(initialValue: UpdateTransactionFormCoordinator(ids))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(TransactionStep.allCases, id: \.self) {
                    stepView($0, isCompleted: true)
                }
            }
        }
        .environment(cardCoordinator)
        .navigationTitle("거래 수정")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("취소") {
                    viewModel.send(.cancelButtonTapped)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("수정") {
                    viewModel.send(.updateTransaction)
                }
                .disabled(!viewModel.isValid)
            }
        }
    }

    @ViewBuilder
    private func stepView(_ step: TransactionStep, isCompleted: Bool) -> some View {
        Group {
            switch step {
            case .amountPlacePaymentMethod:
                AmountPlacePaymentMethodFormView(viewModel: viewModel.amountPlacePaymentViewModel)

            case .transactionTypeCategory:
                TransactionTypeCategoryFormView(viewModel: viewModel.transactionTypeSelectionViewModel)

            case .dateAdditional:
                DateAdditionalFormView(viewModel: viewModel.dateAdditionalFormViewModel)
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

    private func getStepID(_ step: TransactionStep) -> String {
        switch step {
        case .amountPlacePaymentMethod:
            return viewModel.amountPlacePaymentViewModel.id.uuidString
        case .transactionTypeCategory:
            return viewModel.transactionTypeSelectionViewModel.id.uuidString
        case .dateAdditional:
            return viewModel.dateAdditionalFormViewModel.id.uuidString
        }
    }

    private func getSummary(_ step: TransactionStep) -> String {
        switch step {
        case .amountPlacePaymentMethod:
            return viewModel.amountPlacePaymentViewModel.summary
        case .transactionTypeCategory:
            return viewModel.transactionTypeSelectionViewModel.summary
        case .dateAdditional:
            return viewModel.dateAdditionalFormViewModel.summary
        }
    }
}

#Preview {
    CoordinatorHost(container: MockDIContainer(), start: .transactionUpdate(.mockLunch))
}
