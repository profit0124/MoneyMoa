//
//  TransactionDetailViewModel.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/20/25.
//

import Foundation
import Observation

enum TransactionDetailViewMode {
    case detail
    case update
}

@Observable
final class TransactionDetailViewModel {

    var transaction: TransactionDTO
    var viewMode: TransactionDetailViewMode = .detail
    var isPresentedDeleteConfirmation: Bool = false

    init(transaction: TransactionDTO) {
        self.transaction = transaction
    }

    enum Action {
        case showDeleteConfirmation
        case deleteTransaction(() -> Void)
        case changeViewMode
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
        }
    }

    private func handleChangeViewMode() {
        viewMode = viewMode == .detail ? .update : .detail
    }

    private func deleteTransaction() async throws {
        // delte transaction
    }
}
