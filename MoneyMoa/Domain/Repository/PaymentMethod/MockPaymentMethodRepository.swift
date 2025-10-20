//
//  MockPaymentMethodRepository.swift
//  MoneyMoa
//
//  Created by Claude on 9/4/25.
//

import Foundation

#if DEBUG

/// Mock Payment Method Repository for Testing and Previews
/// - Provides realistic test data with configurable scenarios
/// - Supports error simulation and delay testing
/// - Thread-safe implementation using serial queue
public final class MockPaymentMethodRepository: @unchecked Sendable, PaymentMethodRepository {
    
    // MARK: - Mock Control Properties
    
    /// Simulated delay for async operations (seconds)
    public var delay: TimeInterval = 0
    
    /// Flag to simulate failures
    public var shouldFail = false
    
    /// Custom error to throw when shouldFail is true
    public var errorToThrow: Error = MockError.simulatedFailure
    
    // MARK: - Data Storage
    
    private var paymentMethods: [PaymentMethodDTO] = []
    
    // MARK: - Thread Safety
    
    private let serialQueue = DispatchQueue(label: "MockPaymentMethodRepository.serialQueue", qos: .utility)
    
    // MARK: - Scenarios
    
    public enum DataScenario {
        case empty
        case minimal(count: Int = 3)
        case normal(count: Int = 8)
        case realistic
        case stress(count: Int = 100)
    }
    
    // MARK: - Initialization
    
    public init(scenario: DataScenario = .normal()) {
        loadScenario(scenario)
    }
    
    public func loadScenario(_ scenario: DataScenario) {
        switch scenario {
        case .empty:
            paymentMethods = []
        case .minimal(let count):
            paymentMethods = PaymentMethodFactory.randomSet(count: count)
        case .normal(let count):
            paymentMethods = PaymentMethodFactory.standardSet() + 
                            PaymentMethodFactory.randomSet(count: count - 4)
        case .realistic:
            paymentMethods = PaymentMethodFactory.koreanBankCards()
        case .stress(let count):
            paymentMethods = PaymentMethodFactory.randomSet(count: count)
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
    
    // MARK: - PaymentMethodReader Implementation
    
    public func fetchPaymentMethods() async throws -> [PaymentMethodDTO] {
        try await simulateDelay()
        try checkFailure()
        
        return await withCheckedContinuation { continuation in
            serialQueue.async {
                let result = self.paymentMethods.sorted()
                continuation.resume(returning: result)
            }
        }
    }
    
    public func fetchPaymentMethod(id: UUID) async throws -> PaymentMethodDTO? {
        try await simulateDelay()
        try checkFailure()
        
        return await withCheckedContinuation { continuation in
            serialQueue.async {
                let result = self.paymentMethods.first { $0.id == id }
                continuation.resume(returning: result)
            }
        }
    }
    
    public func fetchActivePaymentMethods() async throws -> [PaymentMethodDTO] {
        try await simulateDelay()
        try checkFailure()
        
        return await withCheckedContinuation { continuation in
            serialQueue.async {
                let result = self.paymentMethods.filter { $0.isActive }.sorted()
                continuation.resume(returning: result)
            }
        }
    }
    
    public func fetchPaymentMethodsByKind(_ kind: PaymentMethodKind) async throws -> [PaymentMethodDTO] {
        try await simulateDelay()
        try checkFailure()
        
        return await withCheckedContinuation { continuation in
            serialQueue.async {
                let result = self.paymentMethods.filter { $0.kind == kind && $0.isActive }.sorted()
                continuation.resume(returning: result)
            }
        }
    }
    
    public func validatePaymentMethodName(_ name: String, kind: PaymentMethodKind, excludingId: UUID?) async throws -> Bool {
        try await simulateDelay()
        try checkFailure()
        
        return await withCheckedContinuation { continuation in
            serialQueue.async {
                let exists = self.paymentMethods.contains { paymentMethod in
                    paymentMethod.name == name && 
                    paymentMethod.kind == kind && 
                    paymentMethod.id != excludingId
                }
                continuation.resume(returning: !exists)
            }
        }
    }
    
    public func hasTransactions(paymentMethodId: UUID) async throws -> Bool {
        try await simulateDelay()
        try checkFailure()
        
        return await withCheckedContinuation { continuation in
            serialQueue.async {
                // Mock에서는 랜덤하게 거래 내역 존재 여부 반환
                let result = Bool.random()
                continuation.resume(returning: result)
            }
        }
    }
    
    public func fetchPaymentMethodUsageStats(limit: Int = 10) async throws -> [(paymentMethod: PaymentMethodDTO, usageCount: Int)] {
        try await simulateDelay()
        try checkFailure()
        
        return await withCheckedContinuation { continuation in
            serialQueue.async {
                let activePaymentMethods = self.paymentMethods.filter { $0.isActive }
                let stats = activePaymentMethods.map { paymentMethod in
                    (paymentMethod: paymentMethod, usageCount: Int.random(in: 0...50))
                }
                let result = Array(stats.sorted { $0.usageCount > $1.usageCount }.prefix(limit))
                continuation.resume(returning: result)
            }
        }
    }
    
    public func fetchPaymentMethodAmountSummary(startDate: Date, endDate: Date) async throws -> [(paymentMethod: PaymentMethodDTO, totalAmount: Decimal)] {
        try await simulateDelay()
        try checkFailure()
        
        return await withCheckedContinuation { continuation in
            serialQueue.async {
                let activePaymentMethods = self.paymentMethods.filter { $0.isActive }
                let summary = activePaymentMethods.map { paymentMethod in
                    (paymentMethod: paymentMethod, totalAmount: Decimal(Int.random(in: 10000...500000)))
                }
                let result = summary.sorted { $0.totalAmount > $1.totalAmount }
                continuation.resume(returning: result)
            }
        }
    }
    
    // MARK: - PaymentMethodWriter Implementation
    
    public func insertPaymentMethod(_ paymentMethod: PaymentMethodDTO) async throws {
        try await simulateDelay()
        try checkFailure()
        
        return await withCheckedContinuation { continuation in
            serialQueue.async {
                self.paymentMethods.append(paymentMethod)
                continuation.resume()
            }
        }
    }
    
    public func updatePaymentMethod(_ paymentMethod: PaymentMethodDTO) async throws {
        try await simulateDelay()
        try checkFailure()
        
        return try await withCheckedThrowingContinuation { continuation in
            serialQueue.async {
                if let index = self.paymentMethods.firstIndex(where: { $0.id == paymentMethod.id }) {
                    self.paymentMethods[index] = paymentMethod
                    continuation.resume()
                } else {
                    continuation.resume(throwing: MockError.paymentMethodNotFound)
                }
            }
        }
    }
    
    public func updatePaymentMethodOrder(_ paymentMethods: [PaymentMethodDTO]) async throws {
        try await simulateDelay()
        try checkFailure()
        
        return await withCheckedContinuation { continuation in
            serialQueue.async {
                for (index, paymentMethodDTO) in paymentMethods.enumerated() {
                    if let existingIndex = self.paymentMethods.firstIndex(where: { $0.id == paymentMethodDTO.id }) {
                        var updatedPaymentMethod = self.paymentMethods[existingIndex]
                        updatedPaymentMethod = PaymentMethodDTO(
                            id: updatedPaymentMethod.id,
                            name: updatedPaymentMethod.name,
                            kind: updatedPaymentMethod.kind,
                            iconName: updatedPaymentMethod.iconName,
                            orderIndex: index,
                            isActive: updatedPaymentMethod.isActive
                        )
                        self.paymentMethods[existingIndex] = updatedPaymentMethod
                    }
                }
                continuation.resume()
            }
        }
    }
    
    public func deactivatePaymentMethod(id: UUID) async throws {
        try await simulateDelay()
        try checkFailure()
        
        return try await withCheckedThrowingContinuation { continuation in
            serialQueue.async {
                if let index = self.paymentMethods.firstIndex(where: { $0.id == id }) {
                    let paymentMethod = self.paymentMethods[index]
                    self.paymentMethods[index] = PaymentMethodDTO(
                        id: paymentMethod.id,
                        name: paymentMethod.name,
                        kind: paymentMethod.kind,
                        iconName: paymentMethod.iconName,
                        orderIndex: paymentMethod.orderIndex,
                        isActive: false
                    )
                    continuation.resume()
                } else {
                    continuation.resume(throwing: MockError.paymentMethodNotFound)
                }
            }
        }
    }
    
    public func activatePaymentMethod(id: UUID) async throws {
        try await simulateDelay()
        try checkFailure()
        
        return try await withCheckedThrowingContinuation { continuation in
            serialQueue.async {
                if let index = self.paymentMethods.firstIndex(where: { $0.id == id }) {
                    let paymentMethod = self.paymentMethods[index]
                    self.paymentMethods[index] = PaymentMethodDTO(
                        id: paymentMethod.id,
                        name: paymentMethod.name,
                        kind: paymentMethod.kind,
                        iconName: paymentMethod.iconName,
                        orderIndex: paymentMethod.orderIndex,
                        isActive: true
                    )
                    continuation.resume()
                } else {
                    continuation.resume(throwing: MockError.paymentMethodNotFound)
                }
            }
        }
    }
    
    public var deletePaymentMethodCalled = false
    public var lastDeletedPaymentMethodId: UUID?

    public func deletePaymentMethod(id: UUID) async throws {
        try await simulateDelay()
        try checkFailure()

        return try await withCheckedThrowingContinuation { continuation in
            serialQueue.async {
                self.deletePaymentMethodCalled = true
                self.lastDeletedPaymentMethodId = id

                if let index = self.paymentMethods.firstIndex(where: { $0.id == id }) {
                    // Mock: 단순 삭제 (soft delete 로직은 실제 Repository에서 테스트)
                    self.paymentMethods.remove(at: index)
                    continuation.resume()
                } else {
                    continuation.resume(throwing: RepositoryError.paymentMethodNotFound)
                }
            }
        }
    }
    
    // MARK: - Test Helper Methods
    
    public func reset() {
        serialQueue.async(flags: .barrier) {
            self.paymentMethods.removeAll()
            self.delay = 0
            self.shouldFail = false
            self.errorToThrow = MockError.simulatedFailure
        }
    }
    
    public func count() async -> Int {
        return await withCheckedContinuation { continuation in
            serialQueue.async {
                continuation.resume(returning: self.paymentMethods.count)
            }
        }
    }
}

#endif
