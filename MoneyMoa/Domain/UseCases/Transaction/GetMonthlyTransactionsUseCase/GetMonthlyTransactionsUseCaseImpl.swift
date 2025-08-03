//
//  GetMonthlyTransactionsUseCaseImpl.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/30/25.
//

import Foundation

// MARK: - GetMonthlyTransactionsUseCaseImpl

public class GetMonthlyTransactionsUseCaseImpl: GetMonthlyTransactionsUseCase {
    private let transactionRepository: TransactionRepository
    
    public init(transactionRepository: TransactionRepository) {
        self.transactionRepository = transactionRepository
    }
    
    // MARK: - UseCase Methods
    
    public func execute(yearMonth: YearMonth) async throws -> [TransactionDTO] {
        let transactions = try await transactionRepository.fetchTransactions(for: yearMonth)
        return transactions
    }
}
