//
//  UpdateTransactionViewModel.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/20/25.
//

import Foundation
import Observation
import Combine

@Observable
final class UpdateTransactionViewModel {

    private let updateTransactionUseCase: UpdateTransactionUseCase
    private let transactionEventPublisher: TransactionEventPublisher

    // MARK: Original Data

    let transaction: TransactionDTO
    let cancelEventPublisher: PassthroughSubject<Void, Never> = .init()

    // MARK: Child View Model

    let amountPlacePaymentViewModel: AmountPlacePaymentMethodFormViewModel
    let transactionTypeSelectionViewModel: TransactionTypeCategoryFormViewModel
    let dateAdditionalFormViewModel: DateAdditionalFormViewModel

    // MARK: Computed property
    var isValid: Bool {
        (transaction.amount != amountPlacePaymentViewModel.amount &&
         amountPlacePaymentViewModel.amount ?? 0 > 0) ||
        transaction.place != amountPlacePaymentViewModel.place ||
        transaction.paymentMethod != amountPlacePaymentViewModel.selectedPaymentMethod ||
        transaction.transactionType != transactionTypeSelectionViewModel.selectedTransactionType ||
        transaction.subCategory != transactionTypeSelectionViewModel.selectedSubCategory ||
        transaction.date != dateAdditionalFormViewModel.selectedDate ||
        transaction.memo != dateAdditionalFormViewModel.memo
    }

    init(
        transaction: TransactionDTO,
        updateTransactionUseCase: UpdateTransactionUseCase,
        transactionEventPublisher: TransactionEventPublisher,
        amountPlacePaymentViewModel: AmountPlacePaymentMethodFormViewModel,
        transactionTypeSelectionViewModel: TransactionTypeCategoryFormViewModel,
        dateAdditionalFormViewModel: DateAdditionalFormViewModel
    ) {
        self.transaction = transaction
        self.updateTransactionUseCase = updateTransactionUseCase
        self.transactionEventPublisher = transactionEventPublisher
        self.amountPlacePaymentViewModel = amountPlacePaymentViewModel
        self.transactionTypeSelectionViewModel = transactionTypeSelectionViewModel
        self.dateAdditionalFormViewModel = dateAdditionalFormViewModel
    }

    enum Action {
        case updateTransaction
        case cancelButtonTapped
    }

    func send(_ action: Action) {
        switch action {
        case .updateTransaction:
            Task {
                do {
                    try await updateTransaction()
                    transactionEventPublisher.publish(
                        .init(
                            type: .updated,
                            yearMonth: YearMonth(from: dateAdditionalFormViewModel.selectedDate)
                        )
                    )
                    send(.cancelButtonTapped)
                } catch {
                    print(error)
                }
            }

        case .cancelButtonTapped:
            cancelButtonTapped()
        }
    }

    private func updateTransaction() async throws {
        if let amount = amountPlacePaymentViewModel.amount,
           let subCategory = transactionTypeSelectionViewModel.selectedSubCategory,
           let paymentMethod = amountPlacePaymentViewModel.selectedPaymentMethod {
            let transactionDTO = TransactionDTO(
                id: transaction.id,
                amount: amount,
                date: dateAdditionalFormViewModel.selectedDate,
                place: amountPlacePaymentViewModel.place,
                memo: dateAdditionalFormViewModel.memo,
                transactionType: transactionTypeSelectionViewModel.selectedTransactionType,
                subCategory: subCategory,
                paymentMethod: paymentMethod
            )

            try await updateTransactionUseCase.execute(transactionDTO)
        }

    }

    private func cancelButtonTapped() {
        cancelEventPublisher.send()
    }
}
