//
//  CreateTransactionUseCaseImpl.swift
//  MoneyMoa
//
//  Created by profit on 8/11/25.
//

import Foundation

final class CreateTransactionUseCaseImpl: CreateTransactionUseCase {
    private let transactionRepository: TransactionRepository
    
    init(transactionRepository: TransactionRepository) {
        self.transactionRepository = transactionRepository
    }
    
    func execute(_ transaction: TransactionDTO) async throws {
        // 비즈니스 로직 검증: 금액 유효성 검사
        guard transaction.amount > 0 else {
            throw TransactionCreationError.invalidAmount
        }
        
        // 거래 저장 (Repository에서 SubCategory, PaymentMethod 존재 검증 수행)
        try await transactionRepository.insertTransaction(transaction)
    }
}

// MARK: - Error Types

enum TransactionCreationError: Error {
    case invalidAmount
}
