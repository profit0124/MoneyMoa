//
//  MockCreateTransactionUseCase.swift
//  MoneyMoa
//
//  Created by profit on 8/11/25.
//

import Foundation

#if DEBUG
final class MockCreateTransactionUseCase: CreateTransactionUseCase {
    var shouldFail = false
    var createdTransactions: [TransactionDTO] = []
    
    func execute(_ transaction: TransactionDTO) async throws {
        if shouldFail {
            throw TransactionCreationError.invalidAmount
        }
        
        // Mock에서도 동일한 비즈니스 로직 검증
        guard transaction.amount > 0 else {
            throw TransactionCreationError.invalidAmount
        }
        
        createdTransactions.append(transaction)
    }
    
    func reset() {
        shouldFail = false
        createdTransactions.removeAll()
    }
}
#endif