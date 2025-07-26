//
//  DatabaseTests.swift
//  MoneyMoaTests
//
//  Created by Sooik Kim on 7/26/25.
//

import XCTest
import SwiftData
@testable import MoneyMoa

final class DatabaseTests: XCTestCase, @unchecked Sendable {
    
    // 각 테스트마다 새로운 Database 인스턴스를 생성하는 헬퍼 메서드
    private func createFreshDatabase() throws -> Database {
        return try Database(isStoredInMemoryOnly: true)
    }
    
    // MARK: - Database Initialization Tests
    
    func testDatabaseInitialization() throws {
        let database = try createFreshDatabase()
        XCTAssertNotNil(database)
        XCTAssertNotNil(database.modelContainer)
        XCTAssertNotNil(database.modelExecutor)
    }
    
    func testInMemoryDatabaseInitialization() throws {
        let inMemoryDatabase = try createFreshDatabase()
        XCTAssertNotNil(inMemoryDatabase)
        XCTAssertNotNil(inMemoryDatabase.modelContainer)
        XCTAssertNotNil(inMemoryDatabase.modelExecutor)
    }
    
    // MARK: - Basic Model Operations using withModelContext
    
    func testInsertCategoryUsingWithModelContext() async throws {
        let database = try createFreshDatabase()
        let categoryId = UUID()
        
        try await database.withModelContext { context in
            let category = MoneyMoa.Category(
                id: categoryId,
                name: "식비",
                transactionType: .variableExpense
            )
            context.insert(category)
            try context.save()
        }
        
        let categories = try await database.withModelContext { context in
            try context.fetch(FetchDescriptor<MoneyMoa.Category>())
        }
        
        XCTAssertEqual(categories.count, 1)
        XCTAssertEqual(categories.first?.name, "식비")
        XCTAssertEqual(categories.first?.id, categoryId)
    }
    
    func testMultipleOperations() async throws {
        let database = try createFreshDatabase()
        
        // Insert 10 categories
        for i in 0..<10 {
            try await database.withModelContext { context in
                let category = MoneyMoa.Category(
                    name: "카테고리\(i)",
                    transactionType: .variableExpense
                )
                context.insert(category)
                try context.save()
            }
        }
        
        // Fetch all categories
        let categories = try await database.withModelContext { context in
            try context.fetch(FetchDescriptor<MoneyMoa.Category>())
        }
        
        XCTAssertEqual(categories.count, 10)
    }
    
    func testDeleteCategoryUsingWithModelContext() async throws {
        let database = try createFreshDatabase()
        let categoryId = UUID()
        
        // Insert category
        try await database.withModelContext { context in
            let category = MoneyMoa.Category(
                id: categoryId,
                name: "식비",
                transactionType: .variableExpense
            )
            context.insert(category)
            try context.save()
        }
        
        // Verify it exists
        let categoriesBeforeDelete = try await database.withModelContext { context in
            try context.fetch(FetchDescriptor<MoneyMoa.Category>())
        }
        XCTAssertEqual(categoriesBeforeDelete.count, 1)
        
        // Delete category
        try await database.withModelContext { context in
            let predicate = #Predicate<MoneyMoa.Category> { $0.id == categoryId }
            let descriptor = FetchDescriptor<MoneyMoa.Category>(predicate: predicate)
            
            if let category = try context.fetch(descriptor).first {
                context.delete(category)
                try context.save()
            }
        }
        
        // Verify it's deleted
        let categoriesAfterDelete = try await database.withModelContext { context in
            try context.fetch(FetchDescriptor<MoneyMoa.Category>())
        }
        XCTAssertEqual(categoriesAfterDelete.count, 0)
    }
    
    func testUpdateCategoryUsingWithModelContext() async throws {
        let database = try createFreshDatabase()
        let categoryId = UUID()
        
        // Insert category
        try await database.withModelContext { context in
            let category = MoneyMoa.Category(
                id: categoryId,
                name: "식비",
                transactionType: .variableExpense
            )
            context.insert(category)
            try context.save()
        }
        
        // Update category
        try await database.withModelContext { context in
            let predicate = #Predicate<MoneyMoa.Category> { $0.id == categoryId }
            let descriptor = FetchDescriptor<MoneyMoa.Category>(predicate: predicate)
            
            if let category = try context.fetch(descriptor).first {
                category.name = "외식비"
                try context.save()
            }
        }
        
        // Verify update
        let updatedCategories = try await database.withModelContext { context in
            try context.fetch(FetchDescriptor<MoneyMoa.Category>())
        }
        
        XCTAssertEqual(updatedCategories.count, 1)
        XCTAssertEqual(updatedCategories.first?.name, "외식비")
        XCTAssertEqual(updatedCategories.first?.id, categoryId)
    }
    
    // MARK: - Predicate Tests
    
    func testPredicateWithStringComparison() async throws {
        let database = try createFreshDatabase()
        let category1Id = UUID()
        let category2Id = UUID()
        
        // Insert multiple categories
        try await database.withModelContext { context in
            let category1 = MoneyMoa.Category(
                id: category1Id,
                name: "식비",
                transactionType: .variableExpense
            )
            let category2 = MoneyMoa.Category(
                id: category2Id,
                name: "교통비",
                transactionType: .variableExpense
            )
            context.insert(category1)
            context.insert(category2)
            try context.save()
        }
        
        // Test predicate filtering
        let filteredCategories = try await database.withModelContext { context in
            let predicate = #Predicate<MoneyMoa.Category> { $0.name == "식비" }
            let descriptor = FetchDescriptor<MoneyMoa.Category>(predicate: predicate)
            return try context.fetch(descriptor)
        }
        
        XCTAssertEqual(filteredCategories.count, 1)
        XCTAssertEqual(filteredCategories.first?.name, "식비")
    }
    
    func testPredicateWithBooleanComparison() async throws {
        let database = try createFreshDatabase()
        let activeId = UUID()
        let inactiveId = UUID()
        
        // Insert categories with different active states
        try await database.withModelContext { context in
            let activeCategory = MoneyMoa.Category(
                id: activeId,
                name: "활성카테고리",
                transactionType: .variableExpense,
                orderIndex: 0,
                isActive: true
            )
            let inactiveCategory = MoneyMoa.Category(
                id: inactiveId,
                name: "비활성카테고리",
                transactionType: .variableExpense,
                orderIndex: 1,
                isActive: false
            )
            context.insert(activeCategory)
            context.insert(inactiveCategory)
            try context.save()
        }
        
        // Test filtering by active state
        let activeCategories = try await database.withModelContext { context in
            let predicate = #Predicate<MoneyMoa.Category> { $0.isActive == true }
            let descriptor = FetchDescriptor<MoneyMoa.Category>(predicate: predicate)
            return try context.fetch(descriptor)
        }
        
        XCTAssertEqual(activeCategories.count, 1)
        XCTAssertEqual(activeCategories.first?.name, "활성카테고리")
        XCTAssertTrue(activeCategories.first?.isActive ?? false)
    }
    
    // MARK: - Thread Isolation Tests
    
    func testMainThreadVsDatabaseThread() async throws {
        var database: Database!
        var isMainThreadDuringCreation = false
        var isMainThreadDuringOperation = false
        
        // Create database on MainActor and test immediate operation
        await MainActor.run {
            isMainThreadDuringCreation = Thread.isMainThread
            print("Creating database on main thread: \(isMainThreadDuringCreation)")
            
            do {
                database = try createFreshDatabase()
                print("Database created successfully on main thread")
            } catch {
                XCTFail("Failed to create database: \(error)")
            }
        }
        
        XCTAssertTrue(isMainThreadDuringCreation, "Database created on main thread")
        XCTAssertNotNil(database, "Database created successfully")
        
        // Now test that database operations run on different thread
        isMainThreadDuringOperation = try await database.withModelContext { context in
            let isMainThread = Thread.isMainThread
            print("Database operation runs on main thread: \(isMainThread)")
            
            // Insert a test category to ensure ModelContext is working
            let category = MoneyMoa.Category(
                name: "테스트카테고리",
                transactionType: .variableExpense
            )
            context.insert(category)
            try context.save()
            
            return isMainThread
        }
        
        XCTAssertFalse(isMainThreadDuringOperation, "Database operations did not run on main thread")
        
        // Verify the operation actually worked
        let categories = try await database.withModelContext { context in
            try context.fetch(FetchDescriptor<MoneyMoa.Category>())
        }
        
        XCTAssertEqual(categories.count, 1, "Category should be inserted successfully")
    }
}
