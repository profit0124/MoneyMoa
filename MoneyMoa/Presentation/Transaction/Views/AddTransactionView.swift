//
//  AddTransactionView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/10/25.
//

import SwiftUI

enum TransactionStep: CaseIterable {
    case amountPlacePaymentMethod
    case transactionTypeCategory
    case dateAdditional
    
    var title: String {
        switch self {
        case .amountPlacePaymentMethod:
            return "금액 및 결제정보"
        case .transactionTypeCategory:
            return "거래유형 및 카테고리"
        case .dateAdditional:
            return "날짜 및 추가정보"
        }
    }
    
    var subtitle: String {
        switch self {
        case .amountPlacePaymentMethod:
            return "금액, 장소, 결제수단을 입력하세요"
        case .transactionTypeCategory:
            return "거래유형과 카테고리를 선택하세요"
        case .dateAdditional:
            return "날짜, 메모, 즐겨찾기를 설정하세요"
        }
    }
    
    var icon: String {
        switch self {
        case .amountPlacePaymentMethod:
            return "wonsign.circle.fill"
        case .transactionTypeCategory:
            return "tag.circle.fill"
        case .dateAdditional:
            return "calendar.circle.fill"
        }
    }
    
    var stepNumber: Int {
        switch self {
        case .amountPlacePaymentMethod:
            return 1
        case .transactionTypeCategory:
            return 2
        case .dateAdditional:
            return 3
        }
    }
}

struct AddTransactionView: View {
    @Environment(AppRouter.self) private var router
    @State var viewModel: AddTransactionViewModel
    @State private var cardCoordinator: BasicCardFormCoordinator

    init(viewModel: AddTransactionViewModel) {
        self._viewModel = State(initialValue: viewModel)
        let id = viewModel.amountPlacePaymentViewModel.id
        self._cardCoordinator = State(initialValue: CreateTransactionFormCoordinator(id.uuidString))
    }
    
    var body: some View {
        NavigationStack {
            ScrollViewReader { _ in
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
            }
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
            .navigationTitle("거래 추가")
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
            formType: .create,
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

// MARK: - Preview

#Preview {
    let container = DIContainerFactory.createForPreview()
    let router = AppRouter()
    return AddTransactionView(viewModel: container.makeAddTransactionViewModel())
        .environment(router)
}
