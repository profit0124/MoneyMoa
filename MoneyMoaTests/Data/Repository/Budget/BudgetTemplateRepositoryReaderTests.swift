//
//  BudgetTemplateRepositoryReaderTests.swift
//  MoneyMoaTests
//
//  Created by Sooik Kim on 9/8/25.
//

import Testing
import Foundation
import SwiftData
@testable import MoneyMoa

struct BudgetTemplateRepositoryReaderTests {
    
    private func createTestDatabase() throws -> Database {
        try Database(isStoredInMemoryOnly: true)
    }
    
    private func createTestRepository() throws -> BudgetTemplateRepositoryImpl {
        let database = try createTestDatabase()
        return BudgetTemplateRepositoryImpl(database: database)
    }
    
    // MARK: - BudgetTemplateReader Tests
    
    @Test func testFetchBudgetTemplate_EmptyDatabase() async throws {
        // Given: empty database
        let repository = try createTestRepository()
        
        // When: fetch budget template
        let result = try await repository.fetchBudgetTemplate()
        
        // Then: returns nil
        #expect(result == nil)
    }
    
    @Test func testFetchBudgetTemplate_WithExistingTemplate() async throws {
        // Given: repository with existing template
        let repository = try createTestRepository()
        let template = TestDataFactory.createBudgetTemplate(
            totalAmount: 2000000,
            categoryBudgetTemplates: [
                TestDataFactory.createCategoryBudgetTemplate(
                    amount: 800000,
                    categoryID: UUID(),
                    categoryName: "식비",
                    budgetTemplateId: UUID()
                )
            ]
        )
        _ = try await repository.createBudgetTemplate(template)
        
        // When: fetch budget template
        let result = try await repository.fetchBudgetTemplate()
        
        // Then: returns template without category budgets
        #expect(result != nil)
        #expect(result?.totalAmount == 2000000)
        #expect(result?.categoryBudgetTemplates.isEmpty == true)
    }
    
    @Test func testFetchBudgetTemplateWithCategories() async throws {
        // Given: repository with template including category templates
        let repository = try createTestRepository()
        let categoryId = UUID()
        let template = TestDataFactory.createBudgetTemplate(
            totalAmount: 2000000,
            categoryBudgetTemplates: [
                TestDataFactory.createCategoryBudgetTemplate(
                    amount: 800000,
                    categoryID: categoryId,
                    categoryName: "식비",
                    budgetTemplateId: UUID()
                ),
                TestDataFactory.createCategoryBudgetTemplate(
                    amount: 500000,
                    categoryID: UUID(),
                    categoryName: "교통비",
                    budgetTemplateId: UUID()
                )
            ]
        )
        _ = try await repository.createBudgetTemplate(template)
        
        // When: fetch template with categories
        let result = try await repository.fetchBudgetTemplateWithCategories()
        
        // Then: returns template with category templates
        #expect(result != nil)
        #expect(result?.totalAmount == 2000000)
        #expect(result?.categoryBudgetTemplates.count == 2)
        #expect(result?.categoryBudgetTemplates.contains { $0.categoryName == "식비" } == true)
        #expect(result?.categoryBudgetTemplates.contains { $0.categoryName == "교통비" } == true)
    }
    
    @Test func testTemplateLifecycle_CreateUpdateFetch() async throws {
        // Given: empty repository
        let repository = try createTestRepository()
        
        // When: create, update, and fetch template through complete lifecycle
        
        // 1. Create initial template
        let categoryId = UUID()
        let templateId = UUID()
        let initialTemplate = TestDataFactory.createBudgetTemplate(
            id: templateId,
            totalAmount: 1000000,
            categoryBudgetTemplates: [
                TestDataFactory.createCategoryBudgetTemplate(
                    amount: 400000,
                    categoryID: categoryId,
                    categoryName: "식비",
                    budgetTemplateId: templateId
                )
            ]
        )
        let createdTemplate = try await repository.createBudgetTemplate(initialTemplate)
        
        // 2. Update template
        let updatedTemplate = TestDataFactory.createBudgetTemplate(
            id: createdTemplate.id,
            totalAmount: 1500000,
            categoryBudgetTemplates: [
                TestDataFactory.createCategoryBudgetTemplate(
                    amount: 600000,
                    categoryID: categoryId,
                    categoryName: "식비",
                    budgetTemplateId: createdTemplate.id
                ),
                TestDataFactory.createCategoryBudgetTemplate(
                    amount: 300000,
                    categoryID: UUID(),
                    categoryName: "교통비",
                    budgetTemplateId: createdTemplate.id
                )
            ]
        )
        let finalTemplate = try await repository.updateBudgetTemplate(updatedTemplate)
        
        // 3. Fetch and verify final state
        let fetchedTemplate = try await repository.fetchBudgetTemplateWithCategories()
        
        // Then: template lifecycle works correctly
        #expect(fetchedTemplate?.id == finalTemplate.id)
        #expect(fetchedTemplate?.totalAmount == 1500000)
        #expect(fetchedTemplate?.categoryBudgetTemplates.count == 2)
        #expect(fetchedTemplate?.categoryBudgetTemplates.contains { $0.categoryName == "식비" && $0.amount == 600000 } == true)
        #expect(fetchedTemplate?.categoryBudgetTemplates.contains { $0.categoryName == "교통비" && $0.amount == 300000 } == true)
    }
}
