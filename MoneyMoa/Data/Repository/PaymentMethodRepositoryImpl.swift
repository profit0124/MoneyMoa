//
//  PaymentMethodRepositoryImpl.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/28/25.
//

import Foundation
import SwiftData

// MARK: - PaymentMethodRepositoryImpl

public final class PaymentMethodRepositoryImpl: PaymentMethodRepository {
    private let database: Database
    
    public init(database: Database) {
        self.database = database
    }
    
    // MARK: - 조회 (Fetch Operations)
    
    public func fetchPaymentMethods() async throws -> [PaymentMethodDTO] {
        try await database.withModelContext { context in
            let descriptor = FetchDescriptor<PaymentMethod>(
                sortBy: [
                    SortDescriptor(\.orderIndex),
                    SortDescriptor(\.name)
                ]
            )
            let paymentMethods = try context.fetch(descriptor)
            
            return paymentMethods.toDTOs()
        }
    }
    
    public func fetchPaymentMethod(id: UUID) async throws -> PaymentMethodDTO? {
        try await database.withModelContext { context in
            let predicate = #Predicate<PaymentMethod> { $0.id == id }
            let descriptor = FetchDescriptor<PaymentMethod>(predicate: predicate)
            
            guard let paymentMethod = try context.fetch(descriptor).first else {
                return nil
            }
            
            return paymentMethod.toDTO()
        }
    }
    
    public func fetchActivePaymentMethods() async throws -> [PaymentMethodDTO] {
        try await database.withModelContext { context in
            let predicate = #Predicate<PaymentMethod> { $0.isActive == true }
            let descriptor = FetchDescriptor<PaymentMethod>(
                predicate: predicate,
                sortBy: [
                    SortDescriptor(\.orderIndex),
                    SortDescriptor(\.name)
                ]
            )
            let paymentMethods = try context.fetch(descriptor)
            
            return paymentMethods.toDTOs()
        }
    }
    
    public func fetchPaymentMethodsByKind(_ kind: PaymentMethodKind) async throws -> [PaymentMethodDTO] {
        try await database.withModelContext { context in
            let predicate = #Predicate<PaymentMethod> { paymentMethod in
                paymentMethod.kindRawValue == kind.rawValue && paymentMethod.isActive == true
            }
            let descriptor = FetchDescriptor<PaymentMethod>(
                predicate: predicate,
                sortBy: [
                    SortDescriptor(\.orderIndex),
                    SortDescriptor(\.name)
                ]
            )
            let paymentMethods = try context.fetch(descriptor)
            
            return paymentMethods.toDTOs()
        }
    }
    
    // MARK: - 생성/수정 (Create/Update Operations)
    
    public func insertPaymentMethod(_ paymentMethod: PaymentMethodDTO) async throws {
        try await database.withModelContext { context in
            let newPaymentMethod = paymentMethod.toModel()
            
            context.insert(newPaymentMethod)
            try context.save()
        }
    }
    
    public func updatePaymentMethod(_ paymentMethod: PaymentMethodDTO) async throws {
        let id = paymentMethod.id
        try await database.withModelContext { context in
            let predicate = #Predicate<PaymentMethod> { $0.id == id }
            let descriptor = FetchDescriptor<PaymentMethod>(predicate: predicate)
            
            guard let existingPaymentMethod = try context.fetch(descriptor).first else {
                throw RepositoryError.paymentMethodNotFound
            }
            
            existingPaymentMethod.name = paymentMethod.name
            existingPaymentMethod.kind = paymentMethod.kind
            existingPaymentMethod.orderIndex = paymentMethod.orderIndex
            existingPaymentMethod.isActive = paymentMethod.isActive
            
            try context.save()
        }
    }
    
    public func updatePaymentMethodOrder(_ paymentMethods: [PaymentMethodDTO]) async throws {
        try await database.withModelContext { context in
            for (index, paymentMethodDTO) in paymentMethods.enumerated() {
                let paymentMethodId = paymentMethodDTO.id
                let predicate = #Predicate<PaymentMethod> { $0.id == paymentMethodId }
                let descriptor = FetchDescriptor<PaymentMethod>(predicate: predicate)
                
                guard let paymentMethod = try context.fetch(descriptor).first else {
                    throw RepositoryError.paymentMethodNotFound
                }
                
                paymentMethod.orderIndex = index
            }
            
            try context.save()
        }
    }
    
    // MARK: - 활성/비활성 관리 (Activation Management)
    
    public func deactivatePaymentMethod(id: UUID) async throws {
        try await database.withModelContext { context in
            let predicate = #Predicate<PaymentMethod> { $0.id == id }
            let descriptor = FetchDescriptor<PaymentMethod>(predicate: predicate)
            
            guard let paymentMethod = try context.fetch(descriptor).first else {
                throw RepositoryError.paymentMethodNotFound
            }
            
            paymentMethod.isActive = false
            try context.save()
        }
    }
    
    public func activatePaymentMethod(id: UUID) async throws {
        try await database.withModelContext { context in
            let predicate = #Predicate<PaymentMethod> { $0.id == id }
            let descriptor = FetchDescriptor<PaymentMethod>(predicate: predicate)
            
            guard let paymentMethod = try context.fetch(descriptor).first else {
                throw RepositoryError.paymentMethodNotFound
            }
            
            paymentMethod.isActive = true
            try context.save()
        }
    }
    
    // MARK: - 삭제 관련 (Delete Operations)
    
    public func deletePaymentMethod(id: UUID) async throws {
        try await database.withModelContext { context in
            let predicate = #Predicate<PaymentMethod> { $0.id == id }
            let descriptor = FetchDescriptor<PaymentMethod>(predicate: predicate)
            
            guard let paymentMethod = try context.fetch(descriptor).first else {
                throw RepositoryError.paymentMethodNotFound
            }

            if !paymentMethod.transactionTemplates.isEmpty {
                throw RepositoryError.hasActiveTemplates
            }

            if paymentMethod.transactions.isEmpty {
                context.delete(paymentMethod)
            } else {
                paymentMethod.isActive = false
            }

            try context.save()
        }
    }
    
    // MARK: - 검증 (Validation)
    
    public func validatePaymentMethodName(_ name: String, kind: PaymentMethodKind, excludingId: UUID?) async throws -> Bool {
        try await database.withModelContext { context in
            let predicate: Predicate<PaymentMethod>
            
            if let excludingId = excludingId {
                predicate = #Predicate<PaymentMethod> { paymentMethod in
                    paymentMethod.name == name && 
                    paymentMethod.kindRawValue == kind.rawValue &&
                    paymentMethod.id != excludingId
                }
            } else {
                predicate = #Predicate<PaymentMethod> { paymentMethod in
                    paymentMethod.name == name && paymentMethod.kindRawValue == kind.rawValue
                }
            }
            
            let descriptor = FetchDescriptor<PaymentMethod>(predicate: predicate)
            let existingPaymentMethods = try context.fetch(descriptor)
            
            return existingPaymentMethods.isEmpty
        }
    }
    
    public func hasTransactions(paymentMethodId: UUID) async throws -> Bool {
        try await database.withModelContext { context in
            let predicate = #Predicate<PaymentMethod> { $0.id == paymentMethodId }
            let descriptor = FetchDescriptor<PaymentMethod>(predicate: predicate)
            
            guard let paymentMethod = try context.fetch(descriptor).first else {
                throw RepositoryError.paymentMethodNotFound
            }
            
            return !paymentMethod.transactions.isEmpty
        }
    }
    
    // MARK: - 통계 (Statistics)
    
    public func fetchPaymentMethodUsageStats(limit: Int = 10) async throws -> [(paymentMethod: PaymentMethodDTO, usageCount: Int)] {
        try await database.withModelContext { context in
            // 모든 활성 결제수단 조회
            let paymentMethodPredicate = #Predicate<PaymentMethod> { $0.isActive == true }
            let paymentMethodDescriptor = FetchDescriptor<PaymentMethod>(predicate: paymentMethodPredicate)
            let paymentMethods = try context.fetch(paymentMethodDescriptor)
            
            var usageStats: [(paymentMethod: PaymentMethodDTO, usageCount: Int)] = []
            
            for paymentMethod in paymentMethods {
                // 각 결제수단별 거래 횟수 조회
                let paymentMethodId = paymentMethod.id
                let transactionPredicate = #Predicate<Transaction> { $0.paymentMethod.id == paymentMethodId }
                let transactionDescriptor = FetchDescriptor<Transaction>(predicate: transactionPredicate)
                let transactions = try context.fetch(transactionDescriptor)
                
                usageStats.append((
                    paymentMethod: paymentMethod.toDTO(),
                    usageCount: transactions.count
                ))
            }
            
            // 사용 횟수 순으로 정렬하고 제한
            return Array(usageStats.sorted { $0.usageCount > $1.usageCount }.prefix(limit))
        }
    }
    
    public func fetchPaymentMethodAmountSummary(startDate: Date, endDate: Date) async throws -> [(paymentMethod: PaymentMethodDTO, totalAmount: Decimal)] {
        try await database.withModelContext { context in
            // 모든 활성 결제수단 조회
            let paymentMethodPredicate = #Predicate<PaymentMethod> { $0.isActive == true }
            let paymentMethodDescriptor = FetchDescriptor<PaymentMethod>(predicate: paymentMethodPredicate)
            let paymentMethods = try context.fetch(paymentMethodDescriptor)
            
            var amountSummary: [(paymentMethod: PaymentMethodDTO, totalAmount: Decimal)] = []
            
            for paymentMethod in paymentMethods {
                // 각 결제수단별 기간 내 거래 금액 합계 조회
                let paymentMethodId = paymentMethod.id
                let transactionPredicate = #Predicate<Transaction> { transaction in
                    transaction.paymentMethod.id == paymentMethodId &&
                    transaction.date >= startDate &&
                    transaction.date <= endDate
                }
                let transactionDescriptor = FetchDescriptor<Transaction>(predicate: transactionPredicate)
                let transactions = try context.fetch(transactionDescriptor)
                
                let totalAmount = transactions.reduce(Decimal.zero) { $0 + $1.amount }
                
                amountSummary.append((
                    paymentMethod: paymentMethod.toDTO(),
                    totalAmount: totalAmount
                ))
            }
            
            // 금액 순으로 정렬 (내림차순)
            return amountSummary.sorted { $0.totalAmount > $1.totalAmount }
        }
    }
}
