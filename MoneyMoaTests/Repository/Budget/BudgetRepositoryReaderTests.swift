//
//  BudgetRepositoryReaderTests.swift
//  MoneyMoaTests
//
//  Created by Sooik Kim on 9/8/25.
//

import Testing
import Foundation
import SwiftData
@testable import MoneyMoa

struct BudgetRepositoryReaderTests {
    
    private func createTestDatabase() throws -> Database {
        try Database(isStoredInMemoryOnly: true)
    }
    
    private func createTestRepository() throws -> (BudgetRepositoryImpl, Database) {
        let database = try createTestDatabase()
        return (BudgetRepositoryImpl(database: database), database)
    }
    
    private func setupTestData(_ database: Database) async throws {
        // Create a budget template first for tests that need it
        let templateRepository = BudgetTemplateRepositoryImpl(database: database)
        let template = TestDataFactory.createBudgetTemplate(
            totalAmount: 1000000,
            categoryBudgetTemplates: [
                TestDataFactory.createCategoryBudgetTemplate(
                    amount: 300000,
                    categoryID: UUID(),
                    categoryName: "식비",
                    budgetTemplateId: UUID()
                ),
                TestDataFactory.createCategoryBudgetTemplate(
                    amount: 200000,
                    categoryID: UUID(),
                    categoryName: "교통비",
                    budgetTemplateId: UUID()
                )
            ]
        )
        _ = try await templateRepository.createBudgetTemplate(template)
    }
    
    // MARK: - BudgetReader Tests
    
    @Test func testFetchBudget_EmptyDatabase() async throws {
        // Given: empty database
        let (repository, _) = try createTestRepository()
        let testMonth = YearMonth(year: 2025, month: 1)
        
        // When: fetch budget for specific month
        let result = try await repository.fetchBudget(for: testMonth)
        
        // Then: returns nil
        #expect(result == nil)
    }
    
    @Test func testFetchBudget_WithExistingBudget() async throws {
        // Given: repository with existing budget
        let (repository, _) = try createTestRepository()
        let testMonth = YearMonth(year: 2025, month: 1)
        let budget = TestDataFactory.createBudget(month: testMonth, totalAmount: 500000)
        _ = try await repository.createBudget(budget)
        
        // When: fetch budget for that month
        let result = try await repository.fetchBudget(for: testMonth)
        
        // Then: returns the budget
        #expect(result != nil)
        #expect(result?.month == testMonth)
        #expect(result?.totalAmount == 500000)
    }
    
    @Test func testFetchBudgetWithCategories() async throws {
        // Given: repository with budget including category budgets
        let (repository, _) = try createTestRepository()
        let testMonth = YearMonth(year: 2025, month: 1)
        let categoryId = UUID()
        let budget = TestDataFactory.createBudget(
            month: testMonth,
            totalAmount: 500000,
            categoryBudgets: [
                TestDataFactory.createCategoryBudget(
                    amount: 300000,
                    categoryID: categoryId,
                    categoryName: "식비",
                    budgetId: UUID()
                )
            ]
        )
        _ = try await repository.createBudget(budget)
        
        // When: fetch budget with categories
        let result = try await repository.fetchBudgetWithCategories(for: testMonth)
        
        // Then: returns budget with category budgets
        #expect(result != nil)
        #expect(result?.categoryBudgets.count == 1)
        #expect(result?.categoryBudgets.first?.categoryName == "식비")
    }
    
    @Test func testFetchCurrentBudget_CreatesFromTemplate() async throws {
        // Given: repository with template but no current budget
        let (repository, database) = try createTestRepository()
        try await setupTestData(database)
        
        // When: fetch current budget
        let result = try await repository.fetchCurrentBudget()
        
        // Then: creates budget from template
        #expect(result.month == YearMonth.current)
        #expect(result.totalAmount == 1000000)
    }
    
    @Test func testFetchCurrentBudgetWithCategories() async throws {
        // Given: repository with template
        let (repository, database) = try createTestRepository()
        try await setupTestData(database)
        
        // When: fetch current budget with categories
        let result = try await repository.fetchCurrentBudgetWithCategories()
        
        // Then: returns budget with categories from template
        #expect(result.month == YearMonth.current)
        #expect(result.categoryBudgets.count == 2)
        #expect(result.categoryBudgets.contains { $0.categoryName == "식비" })
        #expect(result.categoryBudgets.contains { $0.categoryName == "교통비" })
    }
    
    @Test func testFetchRecentBudgets() async throws {
        // Given: repository with multiple budgets
        let (repository, database) = try createTestRepository()
        try await setupTestData(database)
        
        let month1 = YearMonth(year: 2025, month: 1)
        let month2 = YearMonth(year: 2025, month: 2)
        let budget1 = TestDataFactory.createBudget(month: month1, totalAmount: 500000)
        let budget2 = TestDataFactory.createBudget(month: month2, totalAmount: 600000)
        
        _ = try await repository.createBudget(budget1)
        _ = try await repository.createBudget(budget2)
        
        // When: fetch recent budgets
        let result = try await repository.fetchRecentBudgets(months: 12)
        
        // Then: returns budgets sorted by recent first
        #expect(result.count >= 2)
        #expect(result.first?.month.year == 2025)
        #expect((result.first?.month.month ?? 0) >= 2)
    }
    
    @Test func testEnsureBudgetExists_CreatesIfNotExists() async throws {
        // Given: repository with template but no budget for specific month
        let (repository, database) = try createTestRepository()
        try await setupTestData(database)
        let testMonth = YearMonth(year: 2025, month: 6)
        
        // When: ensure budget exists
        let result = try await repository.ensureBudgetExists(for: testMonth)
        
        // Then: budget is created from template
        #expect(result.month == testMonth)
        #expect(result.totalAmount == 1000000)
        
        // Verify it was actually saved
        let fetchedBudget = try await repository.fetchBudget(for: testMonth)
        #expect(fetchedBudget != nil)
    }
    
    @Test func testEnsureBudgetExists_ReturnsExisting() async throws {
        // Given: repository with existing budget
        let (repository, _) = try createTestRepository()
        let testMonth = YearMonth(year: 2025, month: 6)
        let budget = TestDataFactory.createBudget(month: testMonth, totalAmount: 750000)
        _ = try await repository.createBudget(budget)
        
        // When: ensure budget exists
        let result = try await repository.ensureBudgetExists(for: testMonth)
        
        // Then: returns existing budget
        #expect(result.month == testMonth)
        #expect(result.totalAmount == 750000)
    }
}
