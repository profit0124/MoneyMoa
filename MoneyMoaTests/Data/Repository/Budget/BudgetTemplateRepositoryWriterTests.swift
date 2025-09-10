//
//  BudgetTemplateRepositoryWriterTests.swift
//  MoneyMoaTests
//
//  Created by Sooik Kim on 9/8/25.
//

import Testing
import Foundation
import SwiftData
@testable import MoneyMoa

struct BudgetTemplateRepositoryWriterTests {
    
    private func createTestDatabase() throws -> Database {
        try Database(isStoredInMemoryOnly: true)
    }
    
    private func createTestRepository() throws -> BudgetTemplateRepositoryImpl {
        let database = try createTestDatabase()
        return BudgetTemplateRepositoryImpl(database: database)
    }
    
    // MARK: - Create Template Tests
    
    @Test func testCreateBudgetTemplate_CategoryBudgetsExceedTotal_ThrowsError() async throws {
        // Given: template with category budgets exceeding total
        let repository = try createTestRepository()
        let templateId = UUID()
        let template = TestDataFactory.createBudgetTemplate(
            id: templateId,
            totalAmount: 500000,
            categoryBudgetTemplates: [
                TestDataFactory.createCategoryBudgetTemplate(
                    amount: 300000,
                    categoryID: UUID(),
                    categoryName: "식비",
                    budgetTemplateId: templateId
                ),
                TestDataFactory.createCategoryBudgetTemplate(
                    amount: 250000, // Total: 550000 > 500000
                    categoryID: UUID(),
                    categoryName: "교통비",
                    budgetTemplateId: templateId
                )
            ]
        )
        
        // When: try to create template with exceeding category budgets
        // Then: throws categoryBudgetsExceedTotalAmount error
        do {
            _ = try await repository.createBudgetTemplate(template)
            #expect(Bool(false), "Expected categoryBudgetsExceedTotalAmount error but no error was thrown")
        } catch {
            switch error {
            case RepositoryError.categoryBudgetsExceedTotalAmount:
                // Expected error
                break
            default:
                #expect(Bool(false), "Expected categoryBudgetsExceedTotalAmount error but got \(error)")
            }
        }
    }
    
    @Test func testCreateBudgetTemplate_Success() async throws {
        // Given: empty repository and new template
        let repository = try createTestRepository()
        let categoryId1 = UUID()
        let categoryId2 = UUID()
        let templateId = UUID()
        let template = TestDataFactory.createBudgetTemplate(
            id: templateId,
            totalAmount: 1500000,
            categoryBudgetTemplates: [
                TestDataFactory.createCategoryBudgetTemplate(
                    amount: 600000,
                    categoryID: categoryId1,
                    categoryName: "식비",
                    budgetTemplateId: templateId
                ),
                TestDataFactory.createCategoryBudgetTemplate(
                    amount: 400000,
                    categoryID: categoryId2,
                    categoryName: "교통비",
                    budgetTemplateId: templateId
                )
            ]
        )
        
        // When: create budget template
        let result = try await repository.createBudgetTemplate(template)
        
        // Then: template is created successfully
        #expect(result.totalAmount == 1500000)
        #expect(result.categoryBudgetTemplates.count == 2)
        #expect(result.categoryBudgetTemplates.contains { $0.categoryName == "식비" && $0.amount == 600000 } == true)
        #expect(result.categoryBudgetTemplates.contains { $0.categoryName == "교통비" && $0.amount == 400000 } == true)
    }
    
    @Test func testCreateBudgetTemplate_EmptyCategories() async throws {
        // Given: template with no category templates
        let repository = try createTestRepository()
        let template = TestDataFactory.createBudgetTemplate(
            totalAmount: 1000000,
            categoryBudgetTemplates: []
        )
        
        // When: create budget template
        let result = try await repository.createBudgetTemplate(template)
        
        // Then: template is created with empty categories
        #expect(result.totalAmount == 1000000)
        #expect(result.categoryBudgetTemplates.isEmpty == true)
    }
    
    // MARK: - Update Template Tests
    
    @Test func testUpdateBudgetTemplate_CategoryBudgetsExceedTotal_ThrowsError() async throws {
        // Given: repository with existing template
        let repository = try createTestRepository()
        let originalTemplate = TestDataFactory.createBudgetTemplate(
            totalAmount: 1000000,
            categoryBudgetTemplates: [
                TestDataFactory.createCategoryBudgetTemplate(
                    amount: 400000,
                    categoryID: UUID(),
                    categoryName: "식비",
                    budgetTemplateId: UUID()
                )
            ]
        )
        _ = try await repository.createBudgetTemplate(originalTemplate)
        
        // When: try to update with category budgets exceeding total
        let templateId = UUID()
        let updatedTemplate = TestDataFactory.createBudgetTemplate(
            id: templateId,
            totalAmount: 500000,
            categoryBudgetTemplates: [
                TestDataFactory.createCategoryBudgetTemplate(
                    amount: 300000,
                    categoryID: UUID(),
                    categoryName: "식비",
                    budgetTemplateId: templateId
                ),
                TestDataFactory.createCategoryBudgetTemplate(
                    amount: 250000, // Total: 550000 > 500000
                    categoryID: UUID(),
                    categoryName: "교통비",
                    budgetTemplateId: templateId
                )
            ]
        )
        
        // Then: throws categoryBudgetsExceedTotalAmount error
        do {
            _ = try await repository.updateBudgetTemplate(updatedTemplate)
            #expect(Bool(false), "Expected categoryBudgetsExceedTotalAmount error but no error was thrown")
        } catch {
            switch error {
            case RepositoryError.categoryBudgetsExceedTotalAmount:
                // Expected error
                break
            default:
                #expect(Bool(false), "Expected categoryBudgetsExceedTotalAmount error but got \(error)")
            }
        }
    }
    
    @Test func testUpdateBudgetTemplate_Success() async throws {
        // Given: repository with existing template
        let repository = try createTestRepository()
        let originalTemplate = TestDataFactory.createBudgetTemplate(
            totalAmount: 1000000,
            categoryBudgetTemplates: [
                TestDataFactory.createCategoryBudgetTemplate(
                    amount: 500000,
                    categoryID: UUID(),
                    categoryName: "식비",
                    budgetTemplateId: UUID()
                )
            ]
        )
        _ = try await repository.createBudgetTemplate(originalTemplate)
        
        // When: update template with new amount and categories
        let categoryId1 = UUID()
        let categoryId2 = UUID()
        let templateId = UUID()
        let updatedTemplate = TestDataFactory.createBudgetTemplate(
            id: templateId,
            totalAmount: 1800000,
            categoryBudgetTemplates: [
                TestDataFactory.createCategoryBudgetTemplate(
                    amount: 700000,
                    categoryID: categoryId1,
                    categoryName: "식비",
                    budgetTemplateId: templateId
                ),
                TestDataFactory.createCategoryBudgetTemplate(
                    amount: 300000,
                    categoryID: categoryId2,
                    categoryName: "교통비",
                    budgetTemplateId: templateId
                ),
                TestDataFactory.createCategoryBudgetTemplate(
                    amount: 200000,
                    categoryID: UUID(),
                    categoryName: "엄마비",
                    budgetTemplateId: templateId
                )
            ]
        )
        let result = try await repository.updateBudgetTemplate(updatedTemplate)
        
        // Then: template is updated successfully
        #expect(result.totalAmount == 1800000)
        #expect(result.categoryBudgetTemplates.count == 3)
        #expect(result.categoryBudgetTemplates.contains { $0.categoryName == "식비" && $0.amount == 700000 } == true)
        #expect(result.categoryBudgetTemplates.contains { $0.categoryName == "교통비" && $0.amount == 300000 } == true)
        #expect(result.categoryBudgetTemplates.contains { $0.categoryName == "엄마비" && $0.amount == 200000 } == true)
    }
    
    @Test func testUpdateBudgetTemplate_NotFound_ThrowsError() async throws {
        // Given: empty repository
        let repository = try createTestRepository()
        let template = TestDataFactory.createBudgetTemplate(
            totalAmount: 1000000
        )
        
        // When: try to update non-existing template
        // Then: throws budgetTemplateNotFound error
        do {
            _ = try await repository.updateBudgetTemplate(template)
            #expect(Bool(false), "Expected budgetTemplateNotFound error but no error was thrown")
        } catch {
            switch error {
            case RepositoryError.budgetTemplateNotFound:
                // Expected error
                break
            default:
                #expect(Bool(false), "Expected budgetTemplateNotFound error but got \(error)")
            }
        }
    }
    
    // MARK: - Update Category Templates Tests
    
    @Test func testUpdateCategoryBudgetTemplates_ExceedsTotalAmount_ThrowsError() async throws {
        // Given: repository with existing template
        let repository = try createTestRepository()
        let originalTemplate = TestDataFactory.createBudgetTemplate(
            totalAmount: 500000,
            categoryBudgetTemplates: [
                TestDataFactory.createCategoryBudgetTemplate(
                    amount: 200000,
                    categoryID: UUID(),
                    categoryName: "식비",
                    budgetTemplateId: UUID()
                )
            ]
        )
        _ = try await repository.createBudgetTemplate(originalTemplate)
        
        // When: try to update category templates with sum exceeding total
        let templateId = UUID()
        let categoryTemplates = [
            TestDataFactory.createCategoryBudgetTemplate(
                amount: 300000,
                categoryID: UUID(),
                categoryName: "식비",
                budgetTemplateId: templateId
            ),
            TestDataFactory.createCategoryBudgetTemplate(
                amount: 250000, // Total: 550000 > 500000
                categoryID: UUID(),
                categoryName: "교통비",
                budgetTemplateId: templateId
            )
        ]
        
        // Then: throws categoryBudgetsExceedTotalAmount error
        do {
            try await repository.updateCategoryBudgetTemplates(categoryTemplates)
            #expect(Bool(false), "Expected categoryBudgetsExceedTotalAmount error but no error was thrown")
        } catch {
            switch error {
            case RepositoryError.categoryBudgetsExceedTotalAmount:
                // Expected error
                break
            default:
                #expect(Bool(false), "Expected categoryBudgetsExceedTotalAmount error but got \(error)")
            }
        }
    }
    
    @Test func testUpdateCategoryBudgetTemplates_Success() async throws {
        // Given: repository with existing template
        let repository = try createTestRepository()
        let originalTemplate = TestDataFactory.createBudgetTemplate(
            totalAmount: 1500000,
            categoryBudgetTemplates: [
                TestDataFactory.createCategoryBudgetTemplate(
                    amount: 500000,
                    categoryID: UUID(),
                    categoryName: "식비",
                    budgetTemplateId: UUID()
                )
            ]
        )
        _ = try await repository.createBudgetTemplate(originalTemplate)
        
        // When: update category budget templates
        let categoryId1 = UUID()
        let categoryId2 = UUID()
        let templateId = UUID()
        let newCategoryTemplates = [
            TestDataFactory.createCategoryBudgetTemplate(
                amount: 600000,
                categoryID: categoryId1,
                categoryName: "식비",
                budgetTemplateId: templateId
            ),
            TestDataFactory.createCategoryBudgetTemplate(
                amount: 400000,
                categoryID: categoryId2,
                categoryName: "교통비",
                budgetTemplateId: templateId
            )
        ]
        try await repository.updateCategoryBudgetTemplates(newCategoryTemplates)
        
        // Then: category templates are updated
        let result = try await repository.fetchBudgetTemplateWithCategories()
        #expect(result?.categoryBudgetTemplates.count == 2)
        #expect(result?.categoryBudgetTemplates.contains { $0.categoryName == "식비" && $0.amount == 600000 } == true)
        #expect(result?.categoryBudgetTemplates.contains { $0.categoryName == "교통비" && $0.amount == 400000 } == true)
    }
    
    @Test func testUpdateCategoryBudgetTemplates_NotFound_ThrowsError() async throws {
        // Given: empty repository
        let repository = try createTestRepository()
        let categoryTemplates = [
            TestDataFactory.createCategoryBudgetTemplate(
                amount: 500000,
                categoryID: UUID(),
                categoryName: "식비",
                budgetTemplateId: UUID()
            )
        ]
        
        // When: try to update category templates without existing template
        // Then: throws budgetTemplateNotFound error
        do {
            try await repository.updateCategoryBudgetTemplates(categoryTemplates)
            #expect(Bool(false), "Expected budgetTemplateNotFound error but no error was thrown")
        } catch {
            switch error {
            case RepositoryError.budgetTemplateNotFound:
                // Expected error
                break
            default:
                #expect(Bool(false), "Expected budgetTemplateNotFound error but got \(error)")
            }
        }
    }
    
    @Test func testUpdateCategoryBudgetTemplates_DiffBasedUpdate() async throws {
        // Given: repository with existing template and categories
        let repository = try createTestRepository()
        let categoryId1 = UUID()
        let categoryId2 = UUID()
        let categoryId3 = UUID()
        let templateId = UUID()
        let originalTemplate = TestDataFactory.createBudgetTemplate(
            totalAmount: 1500000,
            categoryBudgetTemplates: [
                TestDataFactory.createCategoryBudgetTemplate(
                    amount: 500000,
                    categoryID: categoryId1,
                    categoryName: "식비",
                    budgetTemplateId: templateId
                ),
                TestDataFactory.createCategoryBudgetTemplate(
                    amount: 300000,
                    categoryID: categoryId2,
                    categoryName: "교통비",
                    budgetTemplateId: templateId
                )
            ]
        )
        _ = try await repository.createBudgetTemplate(originalTemplate)
        
        // When: update categories (modify existing + add new + remove old)
        let updatedCategoryTemplates = [
            // Update existing category1 with new amount
            TestDataFactory.createCategoryBudgetTemplate(
                amount: 600000, // changed from 500000
                categoryID: categoryId1,
                categoryName: "식비",
                budgetTemplateId: templateId
            ),
            // Add new category3 (category2 will be removed)
            TestDataFactory.createCategoryBudgetTemplate(
                amount: 400000,
                categoryID: categoryId3,
                categoryName: "엄마비",
                budgetTemplateId: templateId
            )
        ]
        try await repository.updateCategoryBudgetTemplates(updatedCategoryTemplates)
        
        // Then: diff-based update is applied correctly
        let result = try await repository.fetchBudgetTemplateWithCategories()
        #expect(result?.categoryBudgetTemplates.count == 2)
        #expect(result?.categoryBudgetTemplates.contains { $0.categoryID == categoryId1 && $0.amount == 600000 } == true) // Updated
        #expect(result?.categoryBudgetTemplates.contains { $0.categoryID == categoryId2 } == false) // Removed
        #expect(result?.categoryBudgetTemplates.contains { $0.categoryID == categoryId3 && $0.categoryName == "엄마비" } == true) // Added
    }
}
