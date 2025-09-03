//
//  GetTransactionByIdUseCaseImpl.swift
//  MoneyMoa
//
//  Created by profit on 8/20/25.
//

import Foundation

final class GetTransactionByIdUseCaseImpl: GetTransactionByIdUseCase {
    private let transactionReader: TransactionReader
    
    init(transactionReader: TransactionReader) {
        self.transactionReader = transactionReader
    }
    
    func execute(id: UUID) async throws -> TransactionDTO? {
        return try await transactionReader.fetchTransaction(id: id)
    }
}
