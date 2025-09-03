//
//  GetFavoriteTransactionsUseCaseImpl.swift
//  MoneyMoa
//
//  Created by profit on 8/11/25.
//

import Foundation

final class GetFavoriteTransactionsUseCaseImpl: GetFavoriteTransactionsUseCase {
    private let transactionReader: TransactionReader
    
    init(transactionReader: TransactionReader) {
        self.transactionReader = transactionReader
    }
    
    func execute() async throws -> [TransactionDTO] {
        return try await transactionReader.fetchFavoriteTransactions()
    }
}
