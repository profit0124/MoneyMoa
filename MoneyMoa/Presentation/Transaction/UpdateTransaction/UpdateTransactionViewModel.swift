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

    // MARK: Template Update State

    var showUpdateAlert: Bool = false
    private(set) var pendingUpdate: TransactionDTO?

    // MARK: Computed property

    var hasTemplate: Bool {
        transaction.transactionTemplate != nil
    }

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
        case confirmUpdateWithTemplate
        case confirmUpdateTransactionOnly
        case cancelUpdate
    }

    func send(_ action: Action) {
        switch action {
        case .updateTransaction:
            handleUpdateRequest()

        case .confirmUpdateWithTemplate:
            showUpdateAlert = false
            Task {
                await performUpdate(strategy: .updateWithTemplate)
            }

        case .confirmUpdateTransactionOnly:
            showUpdateAlert = false
            Task {
                await performUpdate(strategy: .none)
            }

        case .cancelUpdate:
            showUpdateAlert = false
            pendingUpdate = nil

        case .cancelButtonTapped:
            cancelButtonTapped()
        }
    }

    private func handleUpdateRequest() {
        preparePendingUpdate()

        if hasTemplate {
            // 템플릿이 있으면 alert 표시
            showUpdateAlert = true
        } else {
            // 템플릿이 없으면 거래만 수정
            Task {
                await performUpdate(strategy: .none)
            }
        }
    }

    private func preparePendingUpdate() {
        guard let amount = amountPlacePaymentViewModel.amount,
              let subCategory = transactionTypeSelectionViewModel.selectedSubCategory,
              let paymentMethod = amountPlacePaymentViewModel.selectedPaymentMethod else {
            return
        }

        pendingUpdate = TransactionDTO(
            id: transaction.id,
            amount: amount,
            date: dateAdditionalFormViewModel.selectedDate,
            place: amountPlacePaymentViewModel.place,
            memo: dateAdditionalFormViewModel.memo,
            transactionType: transactionTypeSelectionViewModel.selectedTransactionType,
            subCategory: subCategory,
            paymentMethod: paymentMethod,
            transactionTemplate: transaction.transactionTemplate
        )
    }

    private func performUpdate(strategy: TemplateUpdateStrategy) async {
        guard let transactionDTO = pendingUpdate else { return }

        do {
            try await updateTransactionUseCase.execute(
                transactionDTO,
                strategy: strategy
            )

            transactionEventPublisher.publish(
                .init(
                    type: .updated,
                    yearMonth: YearMonth(from: dateAdditionalFormViewModel.selectedDate)
                )
            )

            pendingUpdate = nil
            send(.cancelButtonTapped)
        } catch {
            print("거래 업데이트 실패: \(error)")
            pendingUpdate = nil
        }
    }

    private func cancelButtonTapped() {
        cancelEventPublisher.send()
    }
}
