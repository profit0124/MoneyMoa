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
public final class MockTransactionRepository: TransactionRepository {
    
    // MARK: - Mock Control Properties
    
    /// Simulated delay for async operations (seconds)
    public var delay: TimeInterval = 0
    
    /// Flag to simulate failures
    public var shouldFail = false
    
    /// Custom error to throw when shouldFail is true
    public var errorToThrow: Error = MockError.simulatedFailure
    
    // MARK: - Data Storage
    
    private var transactions: [TransactionDTO] = []
    
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
        
        return transactions.first { $0.id == id }
    }
    
    public func fetchTransactions(for yearMonth: YearMonth) async throws -> [TransactionDTO] {
        try await simulateDelay()
        try checkFailure()
        
        let startDate = yearMonth.startOfMonth
        let endDate = yearMonth.endOfMonth
        
        return transactions.filter { transaction in
            transaction.date >= startDate && transaction.date <= endDate
        }
        .sorted { $0.date > $1.date }
    }
    
    public func fetchTransactions(from startDate: Date, to endDate: Date) async throws -> [TransactionDTO] {
        try await simulateDelay()
        try checkFailure()
        
        return transactions.filter { transaction in
            transaction.date >= startDate && transaction.date <= endDate
        }
        .sorted { $0.date > $1.date }
    }
    
    public func fetchFavoriteTransactions() async throws -> [TransactionDTO] {
        try await simulateDelay()
        try checkFailure()
        
        return transactions.filter { $0.isFavorite }
            .sorted { $0.date > $1.date }
    }
    
    public func getTotalAmountByType(from startDate: Date, to endDate: Date) async throws -> [(TransactionType, Decimal)] {
        try await simulateDelay()
        try checkFailure()
        
        let periodTransactions = transactions.filter { transaction in
            return transaction.date >= startDate && transaction.date <= endDate
        }
        
        var totals: [TransactionType: Decimal] = [:]
        for transaction in periodTransactions {
            totals[transaction.transactionType, default: 0] += transaction.amount
        }
        
        return totals.map { (type, amount) in (type, amount) }
    }
    
    public func getTotalAmountBySubCategory(from startDate: Date, to endDate: Date) async throws -> [(SubCategoryDTO, Decimal)] {
        try await simulateDelay()
        try checkFailure()
        
        let periodTransactions = transactions.filter { transaction in
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
        
        return totals.values.map { $0 }
    }
    
    // MARK: - TransactionWriter Implementation
    
    public func insertTransaction(_ transaction: TransactionDTO) async throws {
        try await simulateDelay()
        try checkFailure()
        
        transactions.append(transaction)
    }
    
    public func updateTransaction(_ transaction: TransactionDTO) async throws {
        try await simulateDelay()
        try checkFailure()
        
        if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
            transactions[index] = transaction
        } else {
            throw MockError.transactionNotFound
        }
    }

    public func deleteTransaction(id: UUID) async throws {
        try await simulateDelay()
        try checkFailure()
        
        if let index = transactions.firstIndex(where: { $0.id == id }) {
            transactions.remove(at: index)
        } else {
            throw MockError.transactionNotFound
        }
    }
}
