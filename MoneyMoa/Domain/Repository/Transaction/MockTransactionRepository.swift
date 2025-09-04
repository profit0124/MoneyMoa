//
//  MockTransactionRepository.swift
//  MoneyMoa
//
//  Created by Claude Code on 9/3/25.
//

import Foundation

/// Mock Transaction Repository for Testing and Previews
/// - Provides realistic test data with configurable scenarios  
/// - Supports error simulation and delay testing
public final class MockTransactionRepository: @unchecked Sendable, TransactionRepository {
    
    // MARK: - Mock Control Properties
    
    /// Simulated delay for async operations (seconds)
    public var delay: TimeInterval = 0
    
    /// Flag to simulate failures
    public var shouldFail = false
    
    /// Custom error to throw when shouldFail is true
    public var errorToThrow: Error = MockError.simulatedFailure
    
    // MARK: - Data Storage
    
    private var transactions: [TransactionDTO] = []
    
    // MARK: - Thread Safety
    
    private let serialQueue = DispatchQueue(label: "MockTransactionRepository.serialQueue", qos: .utility)
    
    // MARK: - Scenarios
    
    public enum DataScenario {
        case empty
        case minimal(count: Int = 10)
        case normal(count: Int = 50)
        case stress(count: Int = 1000)
        case realistic
    }
    
    // MARK: - Initialization
    
    public init(scenario: DataScenario = .normal()) {
        loadScenario(scenario)
    }
    
    public func loadScenario(_ scenario: DataScenario) {
        switch scenario {
        case .empty:
            transactions = []
        case .minimal(let count):
            transactions = TransactionFactory.randomSet(count: count)
        case .normal(let count):
            transactions = TransactionFactory.randomSet(count: count)
        case .stress(let count):
            transactions = TransactionFactory.randomSet(count: count)
        case .realistic:
            transactions = TransactionFactory.realistic()
        }
    }
    
    // MARK: - Helper Methods
    
    private func simulateDelay() async throws {
        if delay > 0 {
            try await Task.sleep(for: .seconds(delay))
        }
    }
    
    private func checkFailure() throws {
        if shouldFail {
            throw errorToThrow
        }
    }
    
    // MARK: - TransactionReader Implementation
    
    public func fetchTransaction(id: UUID) async throws -> TransactionDTO? {
        try await simulateDelay()
        try checkFailure()
        
        return await withCheckedContinuation { continuation in
            serialQueue.async {
                let result = self.transactions.first { $0.id == id }
                continuation.resume(returning: result)
            }
        }
    }
    
    public func fetchTransactions(for yearMonth: YearMonth) async throws -> [TransactionDTO] {
        try await simulateDelay()
        try checkFailure()
        
        let startDate = yearMonth.startOfMonth
        let endDate = yearMonth.endOfMonth
        
        return await withCheckedContinuation { continuation in
            serialQueue.async {
                let result = self.transactions.filter { transaction in
                    transaction.date >= startDate && transaction.date <= endDate
                }
                .sorted { $0.date > $1.date }
                continuation.resume(returning: result)
            }
        }
    }
    
    public func fetchTransactions(from startDate: Date, to endDate: Date) async throws -> [TransactionDTO] {
        try await simulateDelay()
        try checkFailure()
        
        return await withCheckedContinuation { continuation in
            serialQueue.async {
                let result = self.transactions.filter { transaction in
                    transaction.date >= startDate && transaction.date <= endDate
                }
                .sorted { $0.date > $1.date }
                continuation.resume(returning: result)
            }
        }
    }
    
    public func fetchFavoriteTransactions() async throws -> [TransactionDTO] {
        try await simulateDelay()
        try checkFailure()
        
        return await withCheckedContinuation { continuation in
            serialQueue.async {
                let result = self.transactions.filter { $0.isFavorite }
                    .sorted { $0.date > $1.date }
                continuation.resume(returning: result)
            }
        }
    }
    
    public func getTotalAmountByType(from startDate: Date, to endDate: Date) async throws -> [(TransactionType, Decimal)] {
        try await simulateDelay()
        try checkFailure()
        
        return await withCheckedContinuation { continuation in
            serialQueue.async {
                let periodTransactions = self.transactions.filter { transaction in
                    return transaction.date >= startDate && transaction.date <= endDate
                }
                
                var totals: [TransactionType: Decimal] = [:]
                for transaction in periodTransactions {
                    totals[transaction.transactionType, default: 0] += transaction.amount
                }
                
                let result = totals.map { (type, amount) in (type, amount) }
                continuation.resume(returning: result)
            }
        }
    }
    
    public func getTotalAmountBySubCategory(from startDate: Date, to endDate: Date) async throws -> [(SubCategoryDTO, Decimal)] {
        try await simulateDelay()
        try checkFailure()
        
        return await withCheckedContinuation { continuation in
            serialQueue.async {
                let periodTransactions = self.transactions.filter { transaction in
                    return transaction.date >= startDate && transaction.date <= endDate
                }
                
                var totals: [UUID: (SubCategoryDTO, Decimal)] = [:]
                for transaction in periodTransactions {
                    let subCategory = transaction.subCategory
                    let subCategoryId = subCategory.id
                    
                    if let existing = totals[subCategoryId] {
                        totals[subCategoryId] = (existing.0, existing.1 + transaction.amount)
                    } else {
                        totals[subCategoryId] = (subCategory, transaction.amount)
                    }
                }
                
                let result = totals.values.map { $0 }
                continuation.resume(returning: result)
            }
        }
    }
    
    // MARK: - TransactionWriter Implementation
    
    public func insertTransaction(_ transaction: TransactionDTO) async throws {
        try await simulateDelay()
        try checkFailure()
        
        return await withCheckedContinuation { continuation in
            serialQueue.async {
                self.transactions.append(transaction)
                continuation.resume()
            }
        }
    }
    
    public func updateTransaction(_ transaction: TransactionDTO) async throws {
        try await simulateDelay()
        try checkFailure()
        
        return try await withCheckedThrowingContinuation { continuation in
            serialQueue.async {
                if let index = self.transactions.firstIndex(where: { $0.id == transaction.id }) {
                    self.transactions[index] = transaction
                    continuation.resume()
                } else {
                    continuation.resume(throwing: MockError.transactionNotFound)
                }
            }
        }
    }

    public func deleteTransaction(id: UUID) async throws {
        try await simulateDelay()
        try checkFailure()
        
        return try await withCheckedThrowingContinuation { continuation in
            serialQueue.async {
                if let index = self.transactions.firstIndex(where: { $0.id == id }) {
                    self.transactions.remove(at: index)
                    continuation.resume()
                } else {
                    continuation.resume(throwing: MockError.transactionNotFound)
                }
            }
        }
    }
}
