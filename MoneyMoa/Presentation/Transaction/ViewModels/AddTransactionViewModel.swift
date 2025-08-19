//
//  AddTransactionViewModel.swift
//  MoneyMoa
//
//  Created by profit on 8/11/25.
//

import Foundation
import SwiftUI

@Observable
final class AddTransactionViewModel {
    
    // MARK: - Dependencies
    
    private let createTransactionUseCase: CreateTransactionUseCase
    private let getFavoriteTransactionsUseCase: GetFavoriteTransactionsUseCase
    private let transactionEventPublisher: TransactionEventPublisher

    let amountPlacePaymentViewModel: AmountPlacePaymentMethodFormViewModel
    let transactionTypeSelectionViewModel: TransactionTypeCategoryFormViewModel
    let dateAdditionalFormViewModel: DateAdditionalFormViewModel

    // MARK: - UI State

    private var completedStep = Set<TransactionStep>()
    var currentStep: TransactionStep = .amountPlacePaymentMethod
    var filteredCompletedStep: [TransactionStep] {
        completedStep.filter({ $0.stepNumber < currentStep.stepNumber }).sorted { $0.stepNumber < $1.stepNumber }
    }

    // MARK: - Computed Properties for Data Binding
    
    var currentSelectedDate: Date {
        dateAdditionalFormViewModel.selectedDate
    }
    
    var currentMemo: String {
        dateAdditionalFormViewModel.memo
    }
    
    var currentIsFavorite: Bool {
        dateAdditionalFormViewModel.isFavorite
    }

    var isValid: Bool {
        switch currentStep {
        case .amountPlacePaymentMethod:
            amountPlacePaymentViewModel.isValid
        case .transactionTypeCategory:
            transactionTypeSelectionViewModel.isValid
        case .dateAdditional:
            true
        }
    }

    var buttonTitle: String {
        switch currentStep {
        case .amountPlacePaymentMethod:
            "다음"
        case .transactionTypeCategory:
            "다음"
        case .dateAdditional:
            "완료"
        }
    }

    // MARK: - Init
    
    init(container: DIContainer) {
        self.createTransactionUseCase = container.makeCreateTransactionUseCase()
        self.getFavoriteTransactionsUseCase = container.makeGetFavoriteTransactionsUseCase()
        self.transactionEventPublisher = container.makeTransactionEventPublisher()
        
        self.amountPlacePaymentViewModel = container.makeAmountPlacePaymentMethodFormViewModel()
        self.transactionTypeSelectionViewModel = container.makeTransactionTypeCategoryFormViewModel()
        self.dateAdditionalFormViewModel = container.makeDateAdditionalFormViewModel()
    }

    enum Action {
        case buttonTapped(() -> Void)
    }

    func send(_ action: Action) {
        switch action {
        case .buttonTapped(let completion):
            handleButtonTapped(completion)
        }
    }

    private func handleButtonTapped(_ completion: @escaping () -> Void) {
        switch currentStep {
        case .amountPlacePaymentMethod:
            completedStep.insert(.amountPlacePaymentMethod)
            currentStep = .transactionTypeCategory
        case .transactionTypeCategory:
            completedStep.insert(.transactionTypeCategory)
            currentStep = .dateAdditional
        case .dateAdditional:
            createTransaction(completion)
        }
    }

    private func createTransaction(_ completion: @escaping () -> Void) {
        if let amount = amountPlacePaymentViewModel.amount,
           let paymentMethod = amountPlacePaymentViewModel.selectedPaymentMethod,
           let subCategory = transactionTypeSelectionViewModel.selectedSubCategory {
            let transactionDTO = TransactionDTO(
                id: UUID(),
                amount: amount,
                date: dateAdditionalFormViewModel.selectedDate,
                place: amountPlacePaymentViewModel.place,
                memo: dateAdditionalFormViewModel.memo,
                transactionType: transactionTypeSelectionViewModel.selectedTransactionType,
                isFavorite: dateAdditionalFormViewModel.isFavorite,
                subCategory: subCategory,
                paymentMethod: paymentMethod
            )

            Task {
                do {
                    try await createTransactionUseCase.execute(transactionDTO)
                    
                    // 트랜잭션 생성 성공 이벤트 발행
                    await MainActor.run {
                        let event = TransactionEvent(
                            type: .created,
                            yearMonth: YearMonth(from: transactionDTO.date),
                            transactionId: transactionDTO.id
                        )
                        transactionEventPublisher.publish(event)
                        completion()
                    }

                } catch {
                    print(error)
                }
            }
        }
    }
}
