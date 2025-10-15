//
//  AddTransactionTemplateView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/24/25.
//

import SwiftUI

struct AddTransactionTemplateView: View {
    @Environment(AppRouter.self) private var router
    @State var viewModel: AddTransactionTemplateViewModel
    @State private var cardCoordinator: BasicCardFormCoordinator

    init(viewModel: AddTransactionTemplateViewModel) {
        self._viewModel = State(initialValue: viewModel)
        let firstStepId = viewModel.amountPlacePaymentViewModel.id.uuidString
        self._cardCoordinator = State(initialValue: CreateTransactionFormCoordinator(firstStepId))
    }

    var body: some View {
//        ScrollViewReader { _ in
        ScrollView {
            VStack(spacing: 16) {
                ForEach(viewModel.filteredCompletedStep, id: \.self) { step in
                    stepView(step, isCompleted: true)
                }

                stepView(viewModel.currentStep, isCompleted: false)

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 16)
        }
        .scrollIndicators(.hidden)
//        }
        .environment(cardCoordinator)
        .overlay(alignment: .bottom) {
            actionButton
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .background {
                    LinearGradient(
                        colors: [Color.clear, Color(.systemBackground)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 100)
                    .allowsHitTesting(false)
                }
        }
        .navigationTitle("템플릿 추가")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("취소") {
                    router.dismissModal()
                }
            }
        }
        .onChange(of: viewModel.currentStep) { _, newValue in
            cardCoordinator.expandCard(getStepID(newValue))
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                viewModel.send(.buttonTapped(router.dismissModal))
            }
        }, label: {
            Text(viewModel.buttonTitle)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(viewModel.isValid ? Color.blue : Color.gray)
                }
        })
        .disabled(!viewModel.isValid)
    }

    @ViewBuilder
    private func stepView(_ step: TransactionTemplateStep, isCompleted: Bool) -> some View {
        Group {
            switch step {
            case .amountPlacePaymentMethod:
                AmountPlacePaymentMethodFormView(viewModel: viewModel.amountPlacePaymentViewModel)

            case .transactionTypeCategory:
                TransactionTypeCategoryFormView(viewModel: viewModel.transactionTypeSelectionViewModel)

            case .patternAdditional:
                TemplatePatternFormView(viewModel: viewModel.templatePatternFormViewModel)
            }
        }
        .cardFormContainer(
            cardId: getStepID(step),
            formType: .create,
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

#Preview {
    let container = DIContainerFactory.createForPreview()
    let router = AppRouter()

    NavigationStack {
        AddTransactionTemplateView(viewModel: container.makeAddTransactionTemplateViewModel())
            .environment(router)
    }
}
