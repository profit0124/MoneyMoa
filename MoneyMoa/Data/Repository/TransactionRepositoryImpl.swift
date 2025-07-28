//
//  TransactionRepositoryImpl.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/27/25.
//

import Foundation
import SwiftData

// MARK: - TransactionRepositoryImpl

public class TransactionRepositoryImpl: TransactionRepository {
    private let database: Database
    
    public init(database: Database) {
        self.database = database
    }
    
    // MARK: - 조회 (Fetch Operations)
    
    public func fetchTransactions() async throws -> [TransactionDTO] {
        try await database.withModelContext { context in
            let descriptor = FetchDescriptor<Transaction>(
                sortBy: [SortDescriptor(\.date, order: .reverse)]  // 최신순
            )
            let transactions = try context.fetch(descriptor)
            
            return transactions.toDTOs()
        }
    }
    
    public func fetchTransaction(id: UUID) async throws -> TransactionDTO? {
        try await database.withModelContext { context in
            let predicate = #Predicate<Transaction> { $0.id == id }
            let descriptor = FetchDescriptor<Transaction>(predicate: predicate)
            
            guard let transaction = try context.fetch(descriptor).first else {
                return nil
            }
            
            return transaction.toDTO()
        }
    }
    
    public func fetchTransactions(from startDate: Date, to endDate: Date) async throws -> [TransactionDTO] {
        try await database.withModelContext { context in
            let predicate = #Predicate<Transaction> { transaction in
                transaction.date >= startDate && transaction.date <= endDate
            }
            let descriptor = FetchDescriptor<Transaction>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            let transactions = try context.fetch(descriptor)
            
            return transactions.toDTOs()
        }
    }
    
    public func fetchTransactions(for yearMonth: YearMonth) async throws -> [TransactionDTO] {
        let startDate = yearMonth.startOfMonth
        let endDate = yearMonth.endOfMonth
        return try await fetchTransactions(from: startDate, to: endDate)
    }
    
    public func fetchTransactions(subCategoryId: UUID) async throws -> [TransactionDTO] {
        try await database.withModelContext { context in
            let predicate = #Predicate<Transaction> { $0.subCategory.id == subCategoryId }
            let descriptor = FetchDescriptor<Transaction>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            let transactions = try context.fetch(descriptor)
            
            return transactions.toDTOs()
        }
    }
    
    public func fetchTransactions(paymentMethodId: UUID) async throws -> [TransactionDTO] {
        try await database.withModelContext { context in
            let predicate = #Predicate<Transaction> { $0.paymentMethod.id == paymentMethodId }
            let descriptor = FetchDescriptor<Transaction>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            let transactions = try context.fetch(descriptor)
            
            return transactions.toDTOs()
        }
    }
    
    public func fetchTransactionsByType(_ type: TransactionType) async throws -> [TransactionDTO] {
        try await database.withModelContext { context in
            let predicate = #Predicate<Transaction> { transaction in
                transaction.transactionTypeRawValue == type.rawValue
            }
            let descriptor = FetchDescriptor<Transaction>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            let transactions = try context.fetch(descriptor)
            
            return transactions.toDTOs()
        }
    }
    
    public func fetchFavoriteTransactions() async throws -> [TransactionDTO] {
        try await database.withModelContext { context in
            let predicate = #Predicate<Transaction> { $0.isFavorite == true }
            let descriptor = FetchDescriptor<Transaction>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            let transactions = try context.fetch(descriptor)
            
            return transactions.toDTOs()
        }
    }
    
    public func searchTransactions(keyword: String) async throws -> [TransactionDTO] {
        try await database.withModelContext { context in
            let predicate = #Predicate<Transaction> { transaction in
                (transaction.memo?.contains(keyword) == true) ||
                (transaction.place?.contains(keyword) == true)
            }
            let descriptor = FetchDescriptor<Transaction>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            let transactions = try context.fetch(descriptor)
            
            return transactions.toDTOs()
        }
    }
    
    // MARK: - 집계 및 통계 (Aggregation & Statistics)
    
    public func getTotalAmountByType(from startDate: Date, to endDate: Date) async throws -> [(TransactionType, Decimal)] {
        try await database.withModelContext { context in
            let predicate = #Predicate<Transaction> { transaction in
                transaction.date >= startDate && transaction.date <= endDate
            }
            let descriptor = FetchDescriptor<Transaction>(predicate: predicate)
            let transactions = try context.fetch(descriptor)
            
            // 거래 유형별로 그룹화하여 합계 계산
            var totals: [TransactionType: Decimal] = [:]
            for transaction in transactions {
                let type = transaction.transactionType
                totals[type, default: 0] += transaction.amount
            }
            
            // 튜플 배열로 변환하여 반환
            return totals.map { (type, amount) in (type, amount) }
        }
    }
    
    public func getTotalAmountByType(for yearMonth: YearMonth) async throws -> [(TransactionType, Decimal)] {
        let startDate = yearMonth.startOfMonth
        let endDate = yearMonth.endOfMonth
        return try await getTotalAmountByType(from: startDate, to: endDate)
    }
    
    public func getTotalAmountBySubCategory(from startDate: Date, to endDate: Date) async throws -> [(SubCategoryDTO, Decimal)] {
        try await database.withModelContext { context in
            let predicate = #Predicate<Transaction> { transaction in
                transaction.date >= startDate && transaction.date <= endDate
            }
            let descriptor = FetchDescriptor<Transaction>(predicate: predicate)
            let transactions = try context.fetch(descriptor)
            
            // 서브카테고리별로 그룹화하여 합계 계산
            var totals: [UUID: (SubCategoryDTO, Decimal)] = [:]
            for transaction in transactions {
                let subCategoryDTO = transaction.subCategory.toDTO()
                let subCategoryId = subCategoryDTO.id
                 
                if let existing = totals[subCategoryId] {
                    totals[subCategoryId] = (existing.0, existing.1 + transaction.amount)
                } else {
                    totals[subCategoryId] = (subCategoryDTO, transaction.amount)
                }
            }
            
            // 튜플 배열로 변환하여 반환
            return totals.values.map { $0 }
        }
    }
    
    public func getTotalAmountBySubCategory(for yearMonth: YearMonth) async throws -> [(SubCategoryDTO, Decimal)] {
        let startDate = yearMonth.startOfMonth
        let endDate = yearMonth.endOfMonth
        return try await getTotalAmountBySubCategory(from: startDate, to: endDate)
    }
    
    public func getDailyTotals(from startDate: Date, to endDate: Date, type: TransactionType?) async throws -> [(Date, Decimal)] {
        try await database.withModelContext { context in
            let predicate: Predicate<Transaction>
            
            if let type = type {
                predicate = #Predicate<Transaction> { transaction in
                    transaction.date >= startDate && 
                    transaction.date <= endDate &&
                    transaction.transactionTypeRawValue == type.rawValue
                }
            } else {
                predicate = #Predicate<Transaction> { transaction in
                    transaction.date >= startDate && transaction.date <= endDate
                }
            }
            
            let descriptor = FetchDescriptor<Transaction>(predicate: predicate)
            let transactions = try context.fetch(descriptor)
            
            // 날짜별로 그룹화하여 합계 계산
            var dailyTotals: [Date: Decimal] = [:]
            let calendar = Calendar.current
            
            for transaction in transactions {
                let dateKey = calendar.startOfDay(for: transaction.date)
                dailyTotals[dateKey, default: 0] += transaction.amount
            }
            
            // 날짜순으로 정렬하여 반환
            return dailyTotals.sorted { $0.key < $1.key }
        }
    }
    
    public func getDailyTotals(for yearMonth: YearMonth, type: TransactionType?) async throws -> [(Date, Decimal)] {
        let startDate = yearMonth.startOfMonth
        let endDate = yearMonth.endOfMonth
        return try await getDailyTotals(from: startDate, to: endDate, type: type)
    }
    
    // MARK: - 생성/수정 (Create/Update Operations)
    
    public func insertTransaction(_ transaction: TransactionDTO) async throws {
        let subCategoryId = transaction.subCategory.id
        let paymentMethodId = transaction.paymentMethod.id
        
        try await database.withModelContext { context in
            // 서브카테고리 조회 (반드시 필요)
            let subCategoryPredicate = #Predicate<SubCategory> { $0.id == subCategoryId }
            let subCategoryDescriptor = FetchDescriptor<SubCategory>(predicate: subCategoryPredicate)
            guard let subCategory = try context.fetch(subCategoryDescriptor).first else {
                throw RepositoryError.subCategoryNotFound
            }
            
            // 결제수단 조회 (반드시 필요)
            let paymentMethodPredicate = #Predicate<PaymentMethod> { $0.id == paymentMethodId }
            let paymentMethodDescriptor = FetchDescriptor<PaymentMethod>(predicate: paymentMethodPredicate)
            guard let paymentMethod = try context.fetch(paymentMethodDescriptor).first else {
                throw RepositoryError.paymentMethodNotFound
            }
            
            // DTO를 SwiftData 모델로 변환
            let newTransaction = transaction.toModel(
                subCategory: subCategory,
                paymentMethod: paymentMethod
            )
            
            context.insert(newTransaction)
            try context.save()
        }
    }
    
    public func updateTransaction(_ transaction: TransactionDTO) async throws {
        let id = transaction.id
        let subCategoryId = transaction.subCategory.id
        let paymentMethodId = transaction.paymentMethod.id
        
        try await database.withModelContext { context in
            // 기존 거래 조회
            let predicate = #Predicate<Transaction> { $0.id == id }
            let descriptor = FetchDescriptor<Transaction>(predicate: predicate)
            
            guard let existingTransaction = try context.fetch(descriptor).first else {
                throw RepositoryError.transactionNotFound
            }
            
            // 서브카테고리가 변경되었다면 새 서브카테고리 확인
            if existingTransaction.subCategory.id != subCategoryId {
                let subCategoryPredicate = #Predicate<SubCategory> { $0.id == subCategoryId }
                let subCategoryDescriptor = FetchDescriptor<SubCategory>(predicate: subCategoryPredicate)
                guard let newSubCategory = try context.fetch(subCategoryDescriptor).first else {
                    throw RepositoryError.subCategoryNotFound
                }
                existingTransaction.subCategory = newSubCategory
            }
            
            // 결제수단이 변경되었다면 새 결제수단 확인
            if existingTransaction.paymentMethod.id != paymentMethodId {
                let paymentMethodPredicate = #Predicate<PaymentMethod> { $0.id == paymentMethodId }
                let paymentMethodDescriptor = FetchDescriptor<PaymentMethod>(predicate: paymentMethodPredicate)
                guard let newPaymentMethod = try context.fetch(paymentMethodDescriptor).first else {
                    throw RepositoryError.paymentMethodNotFound
                }
                existingTransaction.paymentMethod = newPaymentMethod
            }
            
            // 거래 정보 업데이트
            existingTransaction.amount = transaction.amount
            existingTransaction.date = transaction.date
            existingTransaction.place = transaction.place
            existingTransaction.memo = transaction.memo
            existingTransaction.transactionType = transaction.transactionType
            existingTransaction.isFavorite = transaction.isFavorite
            
            try context.save()
        }
    }
    
    public func toggleFavorite(id: UUID) async throws {
        try await database.withModelContext { context in
            let predicate = #Predicate<Transaction> { $0.id == id }
            let descriptor = FetchDescriptor<Transaction>(predicate: predicate)
            
            guard let transaction = try context.fetch(descriptor).first else {
                throw RepositoryError.transactionNotFound
            }
            
            transaction.isFavorite.toggle()
            try context.save()
        }
    }
    
    // MARK: - 삭제 관련 (Delete Operations)
    
    public func deleteTransaction(id: UUID) async throws {
        try await database.withModelContext { context in
            let predicate = #Predicate<Transaction> { $0.id == id }
            let descriptor = FetchDescriptor<Transaction>(predicate: predicate)
            
            guard let transaction = try context.fetch(descriptor).first else {
                throw RepositoryError.transactionNotFound
            }
            
            // 거래는 즉시 삭제 (활성/비활성 단계 없음)
            context.delete(transaction)
            try context.save()
        }
    }
    
    public func deleteTransactions(ids: [UUID]) async throws {
        try await database.withModelContext { context in
            for id in ids {
                let predicate = #Predicate<Transaction> { $0.id == id }
                let descriptor = FetchDescriptor<Transaction>(predicate: predicate)
                
                if let transaction = try context.fetch(descriptor).first {
                    context.delete(transaction)
                }
            }
            
            try context.save()
        }
    }
    
    // MARK: - 검증 (Validation)
    
    public func validateSubCategoryExists(id: UUID) async throws -> Bool {
        try await database.withModelContext { context in
            let predicate = #Predicate<SubCategory> { $0.id == id && $0.isActive == true }
            let descriptor = FetchDescriptor<SubCategory>(predicate: predicate)
            let subCategories = try context.fetch(descriptor)
            
            return !subCategories.isEmpty
        }
    }
    
    public func validatePaymentMethodExists(id: UUID) async throws -> Bool {
        try await database.withModelContext { context in
            let predicate = #Predicate<PaymentMethod> { $0.id == id && $0.isActive == true }
            let descriptor = FetchDescriptor<PaymentMethod>(predicate: predicate)
            let paymentMethods = try context.fetch(descriptor)
            
            return !paymentMethods.isEmpty
        }
    }
}
