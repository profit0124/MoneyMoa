//
//  TransactionDetailViewModel.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/20/25.
//

import Foundation
import Observation
import Combine

enum TransactionDetailViewMode {
    case detail
    case update
}

@Observable
final class TransactionDetailViewModel {

    var transaction: TransactionDTO
    var viewMode: TransactionDetailViewMode = .detail
    var isPresentedDeleteConfirmation: Bool = false
    
    private let deleteTransactionUseCase: DeleteTransactionUseCase
    private let getTransactionByIdUseCase: GetTransactionByIdUseCase
    private let transactionEventPublisher: TransactionEventPublisher

    let updateTransactionViewModel: UpdateTransactionViewModel

    private var cancellables: Set<AnyCancellable> = []

    init(
        transaction: TransactionDTO,
        deleteTransactionUseCase: DeleteTransactionUseCase,
        getTransactionByIdUseCase: GetTransactionByIdUseCase,
        transactionEventPublisher: TransactionEventPublisher,
        updateTransactionViewModel: UpdateTransactionViewModel
    ) {
        self.transaction = transaction
        self.deleteTransactionUseCase = deleteTransactionUseCase
        self.getTransactionByIdUseCase = getTransactionByIdUseCase
        self.transactionEventPublisher = transactionEventPublisher
        self.updateTransactionViewModel = updateTransactionViewModel
    }

    enum Action {
        case showDeleteConfirmation
        case deleteTransaction(() -> Void)
        case changeViewMode
        case fetchTransaction
    }

    func send(_ action: Action) {
        switch action {
        case .showDeleteConfirmation:
            isPresentedDeleteConfirmation = true
        case .deleteTransaction(let completion):
            Task {
                do {
                    try await deleteTransaction()
                    completion()
                } catch {
                    print("error: \(error)")
                }
            }
        case .changeViewMode:
            handleChangeViewMode()

        case .fetchTransaction:
            Task {
                await fetchTransaction()
            }
        }
    }

    private func handleChangeViewMode() {
        if viewMode == .detail {
            viewMode = .update
            transactionEventPublisher.transactionEvents
                .filter { event in
                    event.type == .updated
                }
                .sink(receiveValue: { [weak self] _ in
                    self?.send(.fetchTransaction)
                })
                .store(in: &cancellables)

            updateTransactionViewModel.cancelEventPublisher
                .sink(receiveValue: { [weak self] in
                    self?.send(.changeViewMode)
                })
                .store(in: &cancellables)
        } else {
            viewMode = .detail
            cancellables.removeAll()
        }
    }

    private func deleteTransaction() async throws {
        try await deleteTransactionUseCase.execute(transactionId: transaction.id)
        transactionEventPublisher.publish(
            .init(
                type: .deleted,
                yearMonth: YearMonth(
                    from: transaction.date
                )
            )
        )
    }

    private func fetchTransaction() async {
        do {
            if let updatedTransaction = try await getTransactionByIdUseCase.execute(id: transaction.id) {
                self.transaction = updatedTransaction
            }
        } catch {
            print("거래 내역 조회 실패: \(error)")
        }
    }
}
