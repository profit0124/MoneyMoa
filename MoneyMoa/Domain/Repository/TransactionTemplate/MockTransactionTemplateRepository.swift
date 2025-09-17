//
//  MockTransactionTemplateRepository.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/15/25.
//

import Foundation

#if DEBUG

/// Mock TransactionTemplate Repository for Testing and Previews
/// - Provides realistic test data with configurable scenarios
/// - Supports error simulation and delay testing
public final class MockTransactionTemplateRepository: @unchecked Sendable, TransactionTemplateRepository {

    // MARK: - Mock Control Properties

    /// Simulated delay for async operations (seconds)
    public var delay: TimeInterval = 0

    /// Flag to simulate failures
    public var shouldFail = false

    /// Custom error to throw when shouldFail is true
    public var errorToThrow: Error = MockError.simulatedFailure

    // MARK: - Data Storage

    private var templates: [TransactionTemplateDTO] = []

    // MARK: - Thread Safety

    private let serialQueue = DispatchQueue(label: "MockTransactionTemplateRepository.serialQueue", qos: .utility)

    // MARK: - Scenarios

    public enum DataScenario {
        case empty
        case standard
        case dueOnly
        case notDueOnly
        case monthlyOnly
        case yearlyOnly
        case oneTimeOnly
        case custom(count: Int)
    }

    // MARK: - Initialization

    public init(scenario: DataScenario = .standard) {
        loadScenario(scenario)
    }

    public func loadScenario(_ scenario: DataScenario) {
        switch scenario {
        case .empty:
            templates = []
        case .standard:
            templates = TransactionTemplateFactory.standardSet()
        case .dueOnly:
            templates = TransactionTemplateFactory.dueTemplates()
        case .notDueOnly:
            templates = TransactionTemplateFactory.notDueTemplates()
        case .monthlyOnly:
            templates = TransactionTemplateFactory.monthlyTemplates()
        case .yearlyOnly:
            templates = TransactionTemplateFactory.yearlyTemplates()
        case .oneTimeOnly:
            templates = TransactionTemplateFactory.oneTimeTemplates()
        case .custom(let count):
            templates = TransactionTemplateFactory.randomSet(count: count)
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

    // MARK: - TransactionTemplateReader Implementation

    public func fetchTemplate(id: UUID) async throws -> TransactionTemplateDTO? {
        try await simulateDelay()
        try checkFailure()

        return await withCheckedContinuation { continuation in
            serialQueue.async {
                let result = self.templates.first { $0.id == id }
                continuation.resume(returning: result)
            }
        }
    }

    public func fetchAllTemplates() async throws -> [TransactionTemplateDTO] {
        try await simulateDelay()
        try checkFailure()

        return await withCheckedContinuation { continuation in
            serialQueue.async {
                let result = self.templates.sorted { $0.createdAt > $1.createdAt }
                continuation.resume(returning: result)
            }
        }
    }

    public func fetchTemplatesDueForProcessing(before date: Date) async throws -> [TransactionTemplateDTO] {
        try await simulateDelay()
        try checkFailure()

        return await withCheckedContinuation { continuation in
            serialQueue.async {
                let result = self.templates
                    .filter { template in
                        template.recurrencePeriod != .none
                        && (template.nextDueDate ?? .distantFuture) <= date
                    }
                    .sorted {
                        ($0.nextDueDate ?? Date.distantPast) < ($1.nextDueDate ?? Date.distantPast)
                    }
                continuation.resume(returning: result)
            }
        }
    }

    // MARK: - TransactionTemplateWriter Implementation

    public func insertTemplate(_ template: TransactionTemplateDTO, shouldSave: Bool = false) async throws {
        try await simulateDelay()
        try checkFailure()

        return await withCheckedContinuation { continuation in
            serialQueue.async {
                self.templates.append(template)
                continuation.resume()
            }
        }
    }

    public func updateTemplate(_ template: TransactionTemplateDTO) async throws {
        try await simulateDelay()
        try checkFailure()

        return try await withCheckedThrowingContinuation { continuation in
            serialQueue.async {
                if let index = self.templates.firstIndex(where: { $0.id == template.id }) {
                    self.templates[index] = template
                    continuation.resume()
                } else {
                    continuation.resume(throwing: MockError.templateNotFound)
                }
            }
        }
    }

    public func updateTemplateProcessing(
        id: UUID,
        processedCount: Int,
        lastAddedAt: Date,
        nextDueDate: Date?
    ) async throws {
        try await simulateDelay()
        try checkFailure()

        return try await withCheckedThrowingContinuation { continuation in
            serialQueue.async {
                if let index = self.templates.firstIndex(where: { $0.id == id }) {
                    var template = self.templates[index]

                    // 새로운 템플릿 인스턴스 생성 (값 타입이므로)
                    template = TransactionTemplateDTO(
                        id: template.id,
                        amount: template.amount,
                        place: template.place,
                        memo: template.memo,
                        transactionType: template.transactionType,
                        recurrencePeriod: template.recurrencePeriod,
                        createdAt: template.createdAt,
                        processedCount: processedCount,
                        lastAddedAt: lastAddedAt,
                        nextDueDate: nextDueDate,
                        timeContext: template.timeContext,
                        subCategory: template.subCategory,
                        paymentMethod: template.paymentMethod
                    )

                    self.templates[index] = template
                    continuation.resume()
                } else {
                    continuation.resume(throwing: MockError.templateNotFound)
                }
            }
        }
    }

    public func deleteTemplate(id: UUID) async throws {
        try await simulateDelay()
        try checkFailure()

        return try await withCheckedThrowingContinuation { continuation in
            serialQueue.async {
                if let index = self.templates.firstIndex(where: { $0.id == id }) {
                    self.templates.remove(at: index)
                    continuation.resume()
                } else {
                    continuation.resume(throwing: MockError.templateNotFound)
                }
            }
        }
    }

    // MARK: - Mock Utilities

    public func removeAllTemplates() {
        templates.removeAll()
    }

    public func getTemplateCount() -> Int {
        return templates.count
    }

    /// 테스트를 위한 템플릿 조회 메서드
    public func fetchTemplates() async throws -> [TransactionTemplateDTO] {
        return try await fetchAllTemplates()
    }
}

#endif
