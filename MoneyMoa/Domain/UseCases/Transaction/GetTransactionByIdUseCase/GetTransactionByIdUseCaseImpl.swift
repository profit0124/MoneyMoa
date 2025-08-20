//
//  GetTransactionByIdUseCaseImpl.swift
//  MoneyMoa
//
//  Created by profit on 8/20/25.
//

import Foundation

final class GetTransactionByIdUseCaseImpl: GetTransactionByIdUseCase {
    private let transactionRepository: TransactionRepository
    
    init(transactionRepository: TransactionRepository) {
        self.transactionRepository = transactionRepository
    }
    
    func execute(id: UUID) async throws -> TransactionDTO? {
        return try await transactionRepository.fetchTransaction(id: id)
    }
}