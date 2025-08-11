//
//  GetFavoriteTransactionsUseCaseImpl.swift
//  MoneyMoa
//
//  Created by profit on 8/11/25.
//

import Foundation

final class GetFavoriteTransactionsUseCaseImpl: GetFavoriteTransactionsUseCase {
    private let transactionRepository: TransactionRepository
    
    init(transactionRepository: TransactionRepository) {
        self.transactionRepository = transactionRepository
    }
    
    func execute() async throws -> [TransactionDTO] {
        return try await transactionRepository.fetchFavoriteTransactions()
    }
}