//
//  TransactionTemplateRepositoryImpl.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/15/25.
//

import Foundation
import SwiftData

// MARK: - TransactionTemplateRepositoryImpl

public final class TransactionTemplateRepositoryImpl: TransactionTemplateRepository {
    private let database: Database

    public init(database: Database) {
        self.database = database
    }

    // MARK: - Common Helper Methods

    /// 공통 템플릿 조회 로직 (중복 제거)
    private func fetchTemplateDTOs(
        predicate: Predicate<TransactionTemplate>? = nil,
        sortBy: [SortDescriptor<TransactionTemplate>] = [SortDescriptor(\.createdAt, order: .reverse)]
    ) async throws -> [TransactionTemplateDTO] {
        try await database.withModelContext { context in
            let descriptor = FetchDescriptor<TransactionTemplate>(
                predicate: predicate,
                sortBy: sortBy
            )
            let templates = try context.fetch(descriptor)
            return templates.map { $0.toDTO() }
        }
    }

    /// 단일 템플릿 조회 로직
    private func fetchTemplateDTO(id: UUID) async throws -> TransactionTemplateDTO? {
        try await database.withModelContext { context in
            let predicate = #Predicate<TransactionTemplate> { $0.id == id }
            let descriptor = FetchDescriptor<TransactionTemplate>(predicate: predicate)

            guard let template = try context.fetch(descriptor).first else {
                return nil
            }

            return template.toDTO()
        }
    }

    // MARK: - TransactionTemplateReader Implementation

    public func fetchTemplate(id: UUID) async throws -> TransactionTemplateDTO? {
        return try await fetchTemplateDTO(id: id)
    }

    public func fetchAllTemplates() async throws -> [TransactionTemplateDTO] {
        return try await fetchTemplateDTOs()
    }

    public func fetchTemplatesDueForProcessing(before date: Date) async throws -> [TransactionTemplateDTO] {
        // reccurecePeriodRawValue !=none 이면 nextDueDate는 무조건 nil 이 아님
        // predicate 에선 unwrapping을 지원하지 않으므로 사용
        let now = Date()
        if let basis = Calendar.current.date(byAdding: .second, value: 1, to: now) {
            let predicate = #Predicate<TransactionTemplate> { template in
                (template.nextDueDate ?? now) < basis && template.recurrencePeriodRawValue != "none"
            }
            return try await fetchTemplateDTOs(
                predicate: predicate,
                sortBy: [SortDescriptor(\.nextDueDate, order: .forward)]
            )
        }

        return []
    }

    // MARK: - TransactionTemplateWriter Implementation

    public func insertTemplate(_ template: TransactionTemplateDTO, shouldSave: Bool = true) async throws {
        let subCategoryId = template.subCategory.id
        let paymentMethodId = template.paymentMethod.id

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
            let newTemplate = template.toModel(
                subCategory: subCategory,
                paymentMethod: paymentMethod
            )

            context.insert(newTemplate)

            if shouldSave {
                try context.save()
            }
        }
    }

    public func updateTemplate(_ template: TransactionTemplateDTO) async throws {
        let id = template.id
        let subCategoryId = template.subCategory.id
        let paymentMethodId = template.paymentMethod.id

        try await database.withModelContext { context in
            // 기존 템플릿 조회
            let predicate = #Predicate<TransactionTemplate> { $0.id == id }
            let descriptor = FetchDescriptor<TransactionTemplate>(predicate: predicate)

            guard let existingTemplate = try context.fetch(descriptor).first else {
                throw RepositoryError.templateNotFound
            }

            // 서브카테고리가 변경되었다면 새 서브카테고리 확인
            if existingTemplate.subCategory.id != subCategoryId {
                let subCategoryPredicate = #Predicate<SubCategory> { $0.id == subCategoryId }
                let subCategoryDescriptor = FetchDescriptor<SubCategory>(predicate: subCategoryPredicate)
                guard let newSubCategory = try context.fetch(subCategoryDescriptor).first else {
                    throw RepositoryError.subCategoryNotFound
                }
                existingTemplate.subCategory = newSubCategory
            }

            // 결제수단이 변경되었다면 새 결제수단 확인
            if existingTemplate.paymentMethod.id != paymentMethodId {
                let paymentMethodPredicate = #Predicate<PaymentMethod> { $0.id == paymentMethodId }
                let paymentMethodDescriptor = FetchDescriptor<PaymentMethod>(predicate: paymentMethodPredicate)
                guard let newPaymentMethod = try context.fetch(paymentMethodDescriptor).first else {
                    throw RepositoryError.paymentMethodNotFound
                }
                existingTemplate.paymentMethod = newPaymentMethod
            }

            // 템플릿 정보 업데이트
            existingTemplate.amount = template.amount
            existingTemplate.place = template.place
            existingTemplate.memo = template.memo
            existingTemplate.transactionTypeRawValue = template.transactionType.rawValue
            existingTemplate.recurrencePeriodRawValue = template.recurrencePeriod.rawValue
            existingTemplate.createdAt = template.createdAt.toUTC
            existingTemplate.processedCount = template.processedCount
            existingTemplate.lastAddedAt = template.lastAddedAt.toUTC
            existingTemplate.nextDueDate = template.nextDueDate?.toUTC
            existingTemplate.timeZoneIdentifier = template.timeContext.timeZoneIdentifier
            existingTemplate.calendarIdentifier = template.timeContext.calendarIdentifier
            existingTemplate.localeIdentifier = template.timeContext.localeIdentifier

            try context.save()
        }
    }

    public func updateTemplateProcessing(
        id: UUID,
        processedCount: Int,
        lastAddedAt: Date,
        nextDueDate: Date?
    ) async throws {
        try await database.withModelContext { context in
            let predicate = #Predicate<TransactionTemplate> { $0.id == id }
            let descriptor = FetchDescriptor<TransactionTemplate>(predicate: predicate)

            guard let template = try context.fetch(descriptor).first else {
                throw RepositoryError.templateNotFound
            }

            // 처리 상태 업데이트
            template.processedCount = processedCount
            template.lastAddedAt = lastAddedAt.toUTC
            template.nextDueDate = nextDueDate?.toUTC

            try context.save()
        }
    }

    public func deleteTemplate(id: UUID) async throws {
        try await database.withModelContext { context in
            let predicate = #Predicate<TransactionTemplate> { $0.id == id }
            let descriptor = FetchDescriptor<TransactionTemplate>(predicate: predicate)

            guard let template = try context.fetch(descriptor).first else {
                throw RepositoryError.templateNotFound
            }

            context.delete(template)
            try context.save()
        }
    }

}

// MARK: - Repository Error Extension

extension RepositoryError {
    static let templateNotFound = RepositoryError.custom("Transaction template not found")
}
