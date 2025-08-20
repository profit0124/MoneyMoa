//
//  DeleteTransactionUseCaseImpl.swift
//  MoneyMoa
//
//  Created by profit on 8/20/25.
//

import Foundation

final class DeleteTransactionUseCaseImpl: DeleteTransactionUseCase {
    private let transactionRepository: TransactionRepository
    
    init(transactionRepository: TransactionRepository) {
        self.transactionRepository = transactionRepository
    }
    
    func execute(transactionId: UUID) async throws {
        // 비즈니스 로직 검증: 거래가 존재하는지 확인
        let transaction = try await transactionRepository.fetchTransaction(id: transactionId)
        guard transaction != nil else {
            throw TransactionDeletionError.transactionNotFound
        }
        
        // 거래 삭제 실행
        try await transactionRepository.deleteTransaction(id: transactionId)
    }
}

// MARK: - Error Types

enum TransactionDeletionError: Error, Equatable {
    case transactionNotFound
}
