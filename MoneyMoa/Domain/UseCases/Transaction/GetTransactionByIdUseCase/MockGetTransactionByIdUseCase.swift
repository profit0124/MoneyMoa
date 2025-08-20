//
//  MockGetTransactionByIdUseCase.swift
//  MoneyMoa
//
//  Created by profit on 8/20/25.
//

import Foundation

#if DEBUG
final class MockGetTransactionByIdUseCase: GetTransactionByIdUseCase {
    var shouldFail = false
    var mockTransactions: [UUID: TransactionDTO] = [:]
    
    func execute(id: UUID) async throws -> TransactionDTO? {
        if shouldFail {
            throw GetTransactionByIdError.fetchFailed
        }
        
        return mockTransactions[id]
    }
    
    func setMockTransaction(_ transaction: TransactionDTO) {
        mockTransactions[transaction.id] = transaction
    }
    
    func reset() {
        shouldFail = false
        mockTransactions.removeAll()
    }
}

// MARK: - Error Types

enum GetTransactionByIdError: Error {
    case fetchFailed
}
#endif
