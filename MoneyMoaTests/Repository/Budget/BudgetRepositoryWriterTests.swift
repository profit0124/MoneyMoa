//
//  BudgetRepositoryWriterTests.swift
//  MoneyMoaTests
//
//  Created by Sooik Kim on 9/8/25.
//

import Testing
import Foundation
import SwiftData
@testable import MoneyMoa

struct BudgetRepositoryWriterTests {
    
    private func createTestDatabase() throws -> Database {
        try Database(isStoredInMemoryOnly: true)
    }
    
    private func createTestRepository() throws -> (BudgetRepositoryImpl, Database) {
        let database = try createTestDatabase()
        return (BudgetRepositoryImpl(database: database), database)
    }
    
    // MARK: - Create Budget Tests
    
    @Test func testCreateBudget_CategoryBudgetsExceedTotal_ThrowsError() async throws {
        // Given: new budget with category budgets exceeding total
        let (repository, _) = try createTestRepository()
        let testMonth = YearMonth(year: 2025, month: 3)
        let budget = TestDataFactory.createBudget(
            month: testMonth,
            totalAmount: 500000,
            categoryBudgets: [
                TestDataFactory.createCategoryBudget(
                    amount: 300000,
                    categoryID: UUID(),
                    categoryName: "식비",
                    budgetId: UUID()
                ),
                TestDataFactory.createCategoryBudget(
                    amount: 250000, // Total: 550000 > 500000
                    categoryID: UUID(),
                    categoryName: "교통비",
                    budgetId: UUID()
                )
            ]
        )
        
        // When: try to create budget with exceeding category budgets
        // Then: throws categoryBudgetsExceedTotalAmount error
        do {
            _ = try await repository.createBudget(budget)
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
    
    @Test func testCreateBudget_Success() async throws {
        // Given: empty repository and new budget
        let (repository, _) = try createTestRepository()
        let testMonth = YearMonth(year: 2025, month: 3)
        let categoryId = UUID()
        let budget = TestDataFactory.createBudget(
            month: testMonth,
            totalAmount: 800000,
            categoryBudgets: [
                TestDataFactory.createCategoryBudget(
                    amount: 400000,
                    categoryID: categoryId,
                    categoryName: "식비",
                    budgetId: UUID()
                )
            ]
        )
        
        // When: create budget
        let result = try await repository.createBudget(budget)
        
        // Then: budget is created successfully
        #expect(result.month == testMonth)
        #expect(result.totalAmount == 800000)
        #expect(result.categoryBudgets.count == 1)
        #expect(result.categoryBudgets.first?.categoryName == "식비")
    }
    
    @Test func testCreateBudget_AlreadyExists_ThrowsError() async throws {
        // Given: repository with existing budget
        let (repository, _) = try createTestRepository()
        let testMonth = YearMonth(year: 2025, month: 3)
        let budget1 = TestDataFactory.createBudget(month: testMonth, totalAmount: 500000)
        _ = try await repository.createBudget(budget1)
        
        // When: try to create another budget for same month
        let budget2 = TestDataFactory.createBudget(month: testMonth, totalAmount: 600000)
        
        // Then: throws budgetAlreadyExists error
        do {
            _ = try await repository.createBudget(budget2)
            #expect(Bool(false), "Expected budgetAlreadyExists error but no error was thrown")
        } catch {
            switch error {
            case RepositoryError.budgetAlreadyExists:
                // Expected error
                break
            default:
                #expect(Bool(false), "Expected budgetAlreadyExists error but got \(error)")
            }
        }
    }
    
    @Test func testCreateBudget_ForMonth_ReplacesExisting() async throws {
        // Given: repository with existing budget
        let (repository, _) = try createTestRepository()
        let testMonth = YearMonth(year: 2025, month: 3)
        let budget1 = TestDataFactory.createBudget(month: testMonth, totalAmount: 500000)
        _ = try await repository.createBudget(budget1)
        
        // When: create budget for same month (replace)
        let budget2 = TestDataFactory.createBudget(month: testMonth, totalAmount: 700000)
        try await repository.createBudget(for: testMonth, budget: budget2)
        
        // Then: budget is replaced
        let result = try await repository.fetchBudget(for: testMonth)
        #expect(result?.totalAmount == 700000)
    }
    
    // MARK: - Update Budget Tests
    
    @Test func testUpdateBudget_CategoryBudgetsExceedTotal_ThrowsError() async throws {
        // Given: repository with existing budget
        let (repository, _) = try createTestRepository()
        let testMonth = YearMonth(year: 2025, month: 3)
        let originalBudget = TestDataFactory.createBudget(
            month: testMonth,
            totalAmount: 800000
        )
        _ = try await repository.createBudget(originalBudget)
        
        // When: try to update with category budgets exceeding total
        let updatedBudget = TestDataFactory.createBudget(
            month: testMonth,
            totalAmount: 500000,
            categoryBudgets: [
                TestDataFactory.createCategoryBudget(
                    amount: 300000,
                    categoryID: UUID(),
                    categoryName: "식비",
                    budgetId: UUID()
                ),
                TestDataFactory.createCategoryBudget(
                    amount: 250000, // Total: 550000 > 500000
                    categoryID: UUID(),
                    categoryName: "교통비",
                    budgetId: UUID()
                )
            ]
        )
        
        // Then: throws categoryBudgetsExceedTotalAmount error
        do {
            try await repository.updateBudget(for: testMonth, budget: updatedBudget)
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
    
    @Test func testUpdateBudget_Success() async throws {
        // Given: repository with existing budget
        let (repository, _) = try createTestRepository()
        let testMonth = YearMonth(year: 2025, month: 3)
        let categoryId = UUID()
        let originalBudget = TestDataFactory.createBudget(
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
        _ = try await repository.createBudget(originalBudget)
        
        // When: update budget with new amount and categories
        let updatedBudget = TestDataFactory.createBudget(
            month: testMonth,
            totalAmount: 800000,
            categoryBudgets: [
                TestDataFactory.createCategoryBudget(
                    amount: 400000,
                    categoryID: categoryId,
                    categoryName: "식비",
                    budgetId: UUID()
                ),
                TestDataFactory.createCategoryBudget(
                    amount: 200000,
                    categoryID: UUID(),
                    categoryName: "교통비",
                    budgetId: UUID()
                )
            ]
        )
        try await repository.updateBudget(for: testMonth, budget: updatedBudget)
        
        // Then: budget is updated
        let result = try await repository.fetchBudgetWithCategories(for: testMonth)
        #expect(result?.totalAmount == 800000)
        #expect(result?.categoryBudgets.count == 2)
    }
    
    @Test func testUpdateBudget_NotFound_ThrowsError() async throws {
        // Given: empty repository
        let (repository, _) = try createTestRepository()
        let testMonth = YearMonth(year: 2025, month: 3)
        let budget = TestDataFactory.createBudget(month: testMonth, totalAmount: 500000)
        
        // When: try to update non-existing budget
        // Then: throws budgetNotFound error
        do {
            try await repository.updateBudget(for: testMonth, budget: budget)
            #expect(Bool(false), "Expected budgetNotFound error but no error was thrown")
        } catch {
            switch error {
            case RepositoryError.budgetNotFound:
                // Expected error
                break
            default:
                #expect(Bool(false), "Expected budgetNotFound error but got \(error)")
            }
        }
    }
    
    // MARK: - Update Total Amount Tests
    
    @Test func testUpdateBudgetTotalAmount_Success() async throws {
        // Given: repository with existing budget
        let (repository, _) = try createTestRepository()
        let testMonth = YearMonth(year: 2025, month: 3)
        let budget = TestDataFactory.createBudget(month: testMonth, totalAmount: 500000)
        _ = try await repository.createBudget(budget)
        
        // When: update total amount
        try await repository.updateBudgetTotalAmount(for: testMonth, totalAmount: 800000)
        
        // Then: total amount is updated
        let result = try await repository.fetchBudget(for: testMonth)
        #expect(result?.totalAmount == 800000)
    }
    
    @Test func testUpdateBudgetTotalAmount_ExceedsCategories_ThrowsError() async throws {
        // Given: repository with budget having category budgets
        let (repository, _) = try createTestRepository()
        let testMonth = YearMonth(year: 2025, month: 3)
        let budget = TestDataFactory.createBudget(
            month: testMonth,
            totalAmount: 500000,
            categoryBudgets: [
                TestDataFactory.createCategoryBudget(
                    amount: 300000,
                    categoryID: UUID(),
                    categoryName: "식비",
                    budgetId: UUID()
                )
            ]
        )
        _ = try await repository.createBudget(budget)
        
        // When: try to update total amount below category sum
        // Then: throws categoryBudgetsExceedTotalAmount error
        do {
            try await repository.updateBudgetTotalAmount(for: testMonth, totalAmount: 200000)
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
    
    // MARK: - Update Category Budgets Tests
    
    @Test func testUpdateCategoryBudgets_ExceedsTotalAmount_ThrowsError() async throws {
        // Given: repository with existing budget
        let (repository, _) = try createTestRepository()
        let testMonth = YearMonth(year: 2025, month: 3)
        let budget = TestDataFactory.createBudget(
            month: testMonth,
            totalAmount: 500000
        )
        _ = try await repository.createBudget(budget)
        
        // When: try to update category budgets with sum exceeding total amount
        let categoryBudgets = [
            TestDataFactory.createCategoryBudget(
                amount: 300000,
                categoryID: UUID(),
                categoryName: "식비",
                budgetId: UUID()
            ),
            TestDataFactory.createCategoryBudget(
                amount: 250000, // Total: 550000 > 500000
                categoryID: UUID(),
                categoryName: "교통비",
                budgetId: UUID()
            )
        ]
        
        // Then: throws categoryBudgetsExceedTotalAmount error
        do {
            try await repository.updateCategoryBudgets(for: testMonth, categoryBudgets: categoryBudgets)
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
    
    @Test func testUpdateCategoryBudgets_Success() async throws {
        // Given: repository with existing budget
        let (repository, _) = try createTestRepository()
        let testMonth = YearMonth(year: 2025, month: 3)
        let categoryId = UUID()
        let budget = TestDataFactory.createBudget(
            month: testMonth,
            totalAmount: 800000,
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
        
        // When: update category budgets
        let newCategoryBudgets = [
            TestDataFactory.createCategoryBudget(
                amount: 400000,
                categoryID: categoryId,
                categoryName: "식비",
                budgetId: UUID()
            ),
            TestDataFactory.createCategoryBudget(
                amount: 200000,
                categoryID: UUID(),
                categoryName: "교통비",
                budgetId: UUID()
            )
        ]
        try await repository.updateCategoryBudgets(for: testMonth, categoryBudgets: newCategoryBudgets)
        
        // Then: category budgets are updated
        let result = try await repository.fetchBudgetWithCategories(for: testMonth)
        #expect(result?.categoryBudgets.count == 2)
        #expect(result?.categoryBudgets.contains { $0.amount == 400000 && $0.categoryName == "식비" } == true)
    }
    
    // MARK: - Update Single Category Budget Tests
    
    @Test func testUpdateCategoryBudget_ExceedsTotalAmount_ThrowsError() async throws {
        // Given: repository with existing budget and category budget
        let (repository, _) = try createTestRepository()
        let testMonth = YearMonth(year: 2025, month: 3)
        let categoryId1 = UUID()
        let categoryId2 = UUID()
        let budget = TestDataFactory.createBudget(
            month: testMonth,
            totalAmount: 500000,
            categoryBudgets: [
                TestDataFactory.createCategoryBudget(
                    amount: 200000,
                    categoryID: categoryId1,
                    categoryName: "식비",
                    budgetId: UUID()
                ),
                TestDataFactory.createCategoryBudget(
                    amount: 200000,
                    categoryID: categoryId2,
                    categoryName: "교통비",
                    budgetId: UUID()
                )
            ]
        )
        _ = try await repository.createBudget(budget)
        
        // When: try to update category budget to exceed total
        // Then: throws categoryBudgetsExceedTotalAmount error
        do {
            try await repository.updateCategoryBudget(
                categoryId: categoryId1,
                amount: 350000, // 350000 + 200000 = 550000 > 500000
                for: testMonth
            )
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
    
    @Test func testUpdateCategoryBudget_Success() async throws {
        // Given: repository with existing budget and category budget
        let (repository, _) = try createTestRepository()
        let testMonth = YearMonth(year: 2025, month: 3)
        let categoryId = UUID()
        let budget = TestDataFactory.createBudget(
            month: testMonth,
            totalAmount: 800000,
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
        
        // When: update specific category budget amount
        try await repository.updateCategoryBudget(
            categoryId: categoryId,
            amount: 450000,
            for: testMonth
        )
        
        // Then: category budget amount is updated
        let result = try await repository.fetchBudgetWithCategories(for: testMonth)
        let updatedCategory = result?.categoryBudgets.first { $0.categoryID == categoryId }
        #expect(updatedCategory?.amount == 450000)
    }
    
    @Test func testUpdateCategoryBudget_NotFound_ThrowsError() async throws {
        // Given: repository with existing budget but no matching category
        let (repository, _) = try createTestRepository()
        let testMonth = YearMonth(year: 2025, month: 3)
        let budget = TestDataFactory.createBudget(month: testMonth, totalAmount: 500000)
        _ = try await repository.createBudget(budget)
        
        // When: try to update non-existing category budget
        let nonExistingCategoryId = UUID()
        
        // Then: throws categoryBudgetNotFound error
        do {
            try await repository.updateCategoryBudget(
                categoryId: nonExistingCategoryId,
                amount: 300000,
                for: testMonth
            )
            #expect(Bool(false), "Expected categoryBudgetNotFound error but no error was thrown")
        } catch {
            switch error {
            case RepositoryError.categoryBudgetNotFound:
                // Expected error
                break
            default:
                #expect(Bool(false), "Expected categoryBudgetNotFound error but got \(error)")
            }
        }
    }
}
