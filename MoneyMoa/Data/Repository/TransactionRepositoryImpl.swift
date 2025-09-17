//
//  TransactionRepositoryImpl.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/27/25.
//

import Foundation
import SwiftData

// MARK: - TransactionRepositoryImpl

public final class TransactionRepositoryImpl: TransactionRepository {
    private let database: Database
    
    public init(database: Database) {
        self.database = database
    }
    
    // MARK: - Common Helper Methods
    
    /// 공통 거래 조회 로직 (중복 제거)
    private func fetchTransactionDTOs(
        predicate: Predicate<Transaction>? = nil,
        sortBy: [SortDescriptor<Transaction>] = [SortDescriptor(\.date, order: .reverse)]
    ) async throws -> [TransactionDTO] {
        try await database.withModelContext { context in
            let descriptor = FetchDescriptor<Transaction>(
                predicate: predicate,
                sortBy: sortBy
            )
            let transactions = try context.fetch(descriptor)
            return transactions.toDTOs()
        }
    }
    
    /// 단일 거래 조회 로직
    private func fetchTransactionDTO(id: UUID) async throws -> TransactionDTO? {
        try await database.withModelContext { context in
            let predicate = #Predicate<Transaction> { $0.id == id }
            let descriptor = FetchDescriptor<Transaction>(predicate: predicate)
            
            guard let transaction = try context.fetch(descriptor).first else {
                return nil
            }
            
            return transaction.toDTO()
        }
    }
    
    /// YearMonth를 Date 범위로 변환하는 헬퍼
    private func dateRange(for yearMonth: YearMonth) -> (start: Date, end: Date) {
        return (yearMonth.startOfMonth, yearMonth.endOfMonth)
    }
    
    // MARK: - TransactionReader Implementation
    
    public func fetchTransaction(id: UUID) async throws -> TransactionDTO? {
        return try await fetchTransactionDTO(id: id)
    }
    
    public func fetchTransactions(for yearMonth: YearMonth) async throws -> [TransactionDTO] {
        let range = dateRange(for: yearMonth)
        return try await fetchTransactions(from: range.start, to: range.end)
    }

    /// 기간 검색 공용 함수
    /// startDate, endDate => 기기설정 기준
    /// toUTC 로 변환 후 predicate 생성
    public func fetchTransactions(from startDate: Date, to endDate: Date) async throws -> [TransactionDTO] {
        let startDate = startDate.toUTC
        let endDate = endDate.toUTC
        let predicate = #Predicate<Transaction> { transaction in
            transaction.date >= startDate && transaction.date <= endDate
        }
        return try await fetchTransactionDTOs(predicate: predicate)
    }
    
    public func fetchFavoriteTransactions() async throws -> [TransactionDTO] {
        let predicate = #Predicate<Transaction> { $0.template != nil }
        return try await fetchTransactionDTOs(predicate: predicate)
    }
    
    // MARK: - Statistics (통계 집계)
    
    public func getTotalAmountByType(from startDate: Date, to endDate: Date) async throws -> [(TransactionType, Decimal)] {
        return try await database.withModelContext { context in
            let startDate = startDate.toUTC
            let endDate = endDate.toUTC
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
    
    public func getTotalAmountBySubCategory(from startDate: Date, to endDate: Date) async throws -> [(SubCategoryDTO, Decimal)] {
        return try await database.withModelContext { context in
            let startDate = startDate.toUTC
            let endDate = endDate.toUTC
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
    
    // MARK: - TransactionWriter Implementation
    
    public func insertTransaction(_ transaction: TransactionDTO, shouldSave: Bool = true) async throws {
        let subCategoryId = transaction.subCategory.id
        let paymentMethodId = transaction.paymentMethod.id
        let transactionTemplateId = transaction.transactionTemplate?.id

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

            let newTransaction = transaction.toModel(
                subCategory: subCategory,
                paymentMethod: paymentMethod
            )

            // template 조회
            if let transactionTemplateId {
                let templatePredicate = #Predicate<TransactionTemplate> { $0.id == transactionTemplateId }
                let templateDescriptor = FetchDescriptor<TransactionTemplate>(predicate: templatePredicate)
                let template = try context.fetch(templateDescriptor).first
                newTransaction.template = template
            }

            context.insert(newTransaction)
            if shouldSave {
                try context.save()
            }
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
            // TransactionDTO -> Transaction 일 땐 toUTC
            existingTransaction.amount = transaction.amount
            existingTransaction.date = transaction.date.toUTC
            existingTransaction.place = transaction.place
            existingTransaction.memo = transaction.memo
            existingTransaction.transactionType = transaction.transactionType
//            existingTransaction.isFavorite = transaction.isFavorite
            existingTransaction.timeZoneIdentifier = transaction.timeContext.timeZoneIdentifier
            existingTransaction.calendarIdentifier = transaction.timeContext.calendarIdentifier
            existingTransaction.localeIdentifier = transaction.timeContext.localeIdentifier

            try context.save()
        }
    }
    
    public func deleteTransaction(id: UUID) async throws {
        try await database.withModelContext { context in
            let predicate = #Predicate<Transaction> { $0.id == id }
            let descriptor = FetchDescriptor<Transaction>(predicate: predicate)
            
            guard let transaction = try context.fetch(descriptor).first else {
                throw RepositoryError.transactionNotFound
            }
            
            context.delete(transaction)
            try context.save()
        }
    }
}
