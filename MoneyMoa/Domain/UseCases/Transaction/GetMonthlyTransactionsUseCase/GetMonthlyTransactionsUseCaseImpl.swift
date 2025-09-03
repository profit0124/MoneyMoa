//
//  GetMonthlyTransactionsUseCaseImpl.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/30/25.
//

import Foundation

// MARK: - GetMonthlyTransactionsUseCaseImpl

public class GetMonthlyTransactionsUseCaseImpl: GetMonthlyTransactionsUseCase {
    private let transactionReader: TransactionReader
    
    public init(transactionReader: TransactionReader) {
        self.transactionReader = transactionReader
    }
    
    // MARK: - UseCase Methods
    
    public func execute(yearMonth: YearMonth) async throws -> [TransactionDTO] {
        let transactions = try await transactionReader.fetchTransactions(for: yearMonth)
        return transactions
    }
}
