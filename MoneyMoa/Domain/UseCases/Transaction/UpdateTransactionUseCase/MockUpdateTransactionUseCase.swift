//
//  MockUpdateTransactionUseCase.swift
//  MoneyMoa
//
//  Created by profit on 8/20/25.
//

import Foundation

#if DEBUG
final class MockUpdateTransactionUseCase: UpdateTransactionUseCase {
    var shouldFail = false
    var shouldFailWithNotFound = false
    var updatedTransactions: [TransactionDTO] = []
    
    func execute(_ transaction: TransactionDTO) async throws {
        if shouldFailWithNotFound {
            throw TransactionUpdateError.transactionNotFound
        }
        
        if shouldFail {
            throw TransactionUpdateError.invalidAmount
        }
        
        // Mock에서도 동일한 비즈니스 로직 검증
        guard transaction.amount > 0 else {
            throw TransactionUpdateError.invalidAmount
        }
        
        updatedTransactions.append(transaction)
    }
    
    func reset() {
        shouldFail = false
        shouldFailWithNotFound = false
        updatedTransactions.removeAll()
    }
}
#endif
