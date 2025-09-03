//
//  UpdateTransactionUseCaseImpl.swift
//  MoneyMoa
//
//  Created by profit on 8/20/25.
//

import Foundation

final class UpdateTransactionUseCaseImpl: UpdateTransactionUseCase {
    private let transactionWriter: TransactionWriter
    
    init(transactionWriter: TransactionWriter) {
        self.transactionWriter = transactionWriter
    }
    
    func execute(_ transaction: TransactionDTO) async throws {
        // 비즈니스 로직 검증: 금액 유효성 검사
        guard transaction.amount > 0 else {
            throw TransactionUpdateError.invalidAmount
        }
        
        // 거래 수정 (Repository에서 SubCategory, PaymentMethod 존재 검증 수행)
        try await transactionWriter.updateTransaction(transaction)
    }
}

// MARK: - Error Types

enum TransactionUpdateError: Error {
    case invalidAmount
    case transactionNotFound
}
