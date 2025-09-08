//
//  BudgetTemplateRepositoryImpl.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/8/25.
//

import Foundation
import SwiftData

/// BudgetTemplate Repository 구현체
public final class BudgetTemplateRepositoryImpl: BudgetTemplateRepository {
    private let database: Database

    public init(database: Database) {
        self.database = database
    }

    // MARK: - Helper Methods

    private func updateCategoryTemplatesWithDiff(
        existing: [CategoryBudgetTemplate],
        new: [CategoryBudgetTemplateDTO],
        template: BudgetTemplate,
        context: ModelContext
    ) {
        // 기존 템플릿을 Map으로 변환
        var existingMap = Dictionary(uniqueKeysWithValues:
            existing.map { ($0.categoryID, $0) }
        )

        // 새로운 템플릿 처리
        for dto in new {
            if let existing = existingMap[dto.categoryID] {
                // UPDATE: 기존 항목 수정
                existing.amount = dto.amount
                existing.categoryName = dto.categoryName
                existingMap.removeValue(forKey: dto.categoryID)
            } else {
                // INSERT: 새 항목 추가
                let categoryTemplate = dto.toModel(budgetTemplate: template)
                context.insert(categoryTemplate)
            }
        }

        // DELETE: 남은 기존 항목 삭제
        for (_, categoryTemplate) in existingMap {
            context.delete(categoryTemplate)
        }
    }

    private func validateCategoryBudgetsSum(_ budgets: [CategoryBudgetTemplateDTO], totalAmount: Decimal) throws {
        let sum = budgets.reduce(0) { $0 + $1.amount }
        guard sum <= totalAmount else {
            throw RepositoryError.categoryBudgetsExceedTotalAmount
        }
    }

    // MARK: - BudgetTemplateReader Implementation

    public func fetchBudgetTemplate() async throws -> BudgetTemplateDTO? {
        try await database.withModelContext { context in
            let descriptor = FetchDescriptor<BudgetTemplate>()
            let templates = try context.fetch(descriptor)
            return templates.first?.toDTO(includeCategoryBudgets: false)
        }
    }

    public func fetchBudgetTemplateWithCategories() async throws -> BudgetTemplateDTO? {
        try await database.withModelContext { context in
            let descriptor = FetchDescriptor<BudgetTemplate>()
            let templates = try context.fetch(descriptor)
            return templates.first?.toDTO(includeCategoryBudgets: true)
        }
    }

    // MARK: - BudgetTemplateWriter Implementation
    @discardableResult
    public func createBudgetTemplate(_ template: BudgetTemplateDTO) async throws -> BudgetTemplateDTO {
        try await database.withModelContext { context in
            try self.validateCategoryBudgetsSum(template.categoryBudgetTemplates, totalAmount: template.totalAmount)
            let newTemplate = template.toModelWithCategories()
            context.insert(newTemplate)
            try context.save()

            return newTemplate.toDTO(includeCategoryBudgets: true)
        }
    }

    @discardableResult
    public func updateBudgetTemplate(_ template: BudgetTemplateDTO) async throws -> BudgetTemplateDTO {
        try await database.withModelContext { context in
            try self.validateCategoryBudgetsSum(template.categoryBudgetTemplates, totalAmount: template.totalAmount)

            let descriptor = FetchDescriptor<BudgetTemplate>()

            guard let existingTemplate = try context.fetch(descriptor).first else {
                throw RepositoryError.budgetTemplateNotFound
            }

            // Update template
            existingTemplate.totalAmount = template.totalAmount

            // Diff-based category templates update
            self.updateCategoryTemplatesWithDiff(
                existing: existingTemplate.categoryBudgetTemplates,
                new: template.categoryBudgetTemplates,
                template: existingTemplate,
                context: context
            )

            try context.save()

            return existingTemplate.toDTO(includeCategoryBudgets: true)
        }
    }

    public func updateCategoryBudgetTemplates(_ categoryBudgetTemplates: [CategoryBudgetTemplateDTO]) async throws {
        try await database.withModelContext { context in
            guard let template = try context.fetch(FetchDescriptor<BudgetTemplate>()).first else {
                throw RepositoryError.budgetTemplateNotFound
            }

            try self.validateCategoryBudgetsSum(categoryBudgetTemplates, totalAmount: template.totalAmount)

            // Diff-based update instead of delete-all & recreate
            self.updateCategoryTemplatesWithDiff(
                existing: Array(template.categoryBudgetTemplates),
                new: categoryBudgetTemplates,
                template: template,
                context: context
            )

            try context.save()
        }
    }
}
