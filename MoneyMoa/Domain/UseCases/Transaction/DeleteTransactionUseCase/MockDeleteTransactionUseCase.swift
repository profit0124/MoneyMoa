//
//  MockDeleteTransactionUseCase.swift
//  MoneyMoa
//
//  Created by profit on 8/20/25.
//

import Foundation

#if DEBUG
final class MockDeleteTransactionUseCase: DeleteTransactionUseCase {
    var shouldFail = false
    var deletedTransactionIds: [UUID] = []
    var existingTransactionIds: Set<UUID> = []
    
    func execute(transactionId: UUID) async throws {
        if shouldFail {
            throw TransactionDeletionError.transactionNotFound
        }
        
        // Mock에서도 동일한 비즈니스 로직 검증
        guard existingTransactionIds.contains(transactionId) else {
            throw TransactionDeletionError.transactionNotFound
        }
        
        deletedTransactionIds.append(transactionId)
        existingTransactionIds.remove(transactionId)
    }
    
    func reset() {
        shouldFail = false
        deletedTransactionIds.removeAll()
        existingTransactionIds.removeAll()
    }
    
    func addExistingTransaction(id: UUID) {
        existingTransactionIds.insert(id)
    }
}
#endif
