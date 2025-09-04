//
//  CategoryFactoryTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 9/3/25.
//

import XCTest
@testable import MoneyMoa

// MARK: - CategoryFactoryTests

final class CategoryFactoryTests: XCTestCase {
    
    // MARK: - Basic Builder Tests
    
    func test_sampleCategory_returnsValidCategoryDTO() {
        // When
        let category = CategoryFactory.sampleCategory()
        
        // Then
        XCTAssertEqual(category.name, "샘플 카테고리")
        XCTAssertEqual(category.iconName, "folder")
        XCTAssertEqual(category.transactionType, .variableExpense)
        XCTAssertTrue(category.isActive)
        XCTAssertEqual(category.orderIndex, 0)
        XCTAssertTrue(category.subCategories.isEmpty)
    }
    
    func test_sampleSubCategory_returnsValidSubCategoryDTO() {
        // When
        let subCategory = CategoryFactory.sampleSubCategory()
        
        // Then
        XCTAssertEqual(subCategory.name, "샘플 하위카테고리")
        XCTAssertEqual(subCategory.transactionType, .variableExpense)
        XCTAssertTrue(subCategory.isActive)
        XCTAssertEqual(subCategory.orderIndex, 0)
        XCTAssertEqual(subCategory.categoryName, "샘플 카테고리")
        XCTAssertEqual(subCategory.categoryIconName, "folder")
    }
    
    func test_createCategory_withCustomParameters_returnsCorrectCategory() {
        // Given
        let id = UUID()
        let name = "테스트카테고리"
        let iconName = "test.icon"
        let transactionType = TransactionType.income
        let isActive = false
        let orderIndex = 5
        
        // When
        let category = CategoryFactory.createCategory(
            id: id,
            name: name,
            iconName: iconName,
            transactionType: transactionType,
            isActive: isActive,
            orderIndex: orderIndex
        )
        
        // Then
        XCTAssertEqual(category.id, id)
        XCTAssertEqual(category.name, name)
        XCTAssertEqual(category.iconName, iconName)
        XCTAssertEqual(category.transactionType, transactionType)
        XCTAssertEqual(category.isActive, isActive)
        XCTAssertEqual(category.orderIndex, orderIndex)
        XCTAssertTrue(category.subCategories.isEmpty)
    }
    
    func test_createSubCategory_withCustomParameters_returnsCorrectSubCategory() {
        // Given
        let parentCategory = CategoryFactory.createCategory(
            name: "부모카테고리",
            iconName: "parent.icon",
            transactionType: .fixedExpense,
            orderIndex: 0
        )
        
        let id = UUID()
        let name = "테스트하위카테고리"
        let transactionType = TransactionType.fixedExpense
        let isActive = false
        let orderIndex = 3
        
        // When
        let subCategory = CategoryFactory.createSubCategory(
            id: id,
            name: name,
            transactionType: transactionType,
            parentCategory: parentCategory,
            isActive: isActive,
            orderIndex: orderIndex
        )
        
        // Then
        XCTAssertEqual(subCategory.id, id)
        XCTAssertEqual(subCategory.name, name)
        XCTAssertEqual(subCategory.transactionType, transactionType)
        XCTAssertEqual(subCategory.isActive, isActive)
        XCTAssertEqual(subCategory.orderIndex, orderIndex)
        XCTAssertEqual(subCategory.categoryId, parentCategory.id)
        XCTAssertEqual(subCategory.categoryName, parentCategory.name)
        XCTAssertEqual(subCategory.categoryIconName, parentCategory.iconName)
    }
    
    // MARK: - Test Scenarios
    
    func test_empty_returnsEmptyData() {
        // When
        let data = CategoryFactory.empty
        
        // Then
        XCTAssertTrue(data.categories.isEmpty)
        XCTAssertTrue(data.subCategories.isEmpty)
    }
    
    func test_minimal_returnsMinimalData() {
        // When
        let data = CategoryFactory.minimal
        
        // Then
        XCTAssertEqual(data.categories.count, 2)
        XCTAssertEqual(data.subCategories.count, 2)
        
        // Verify categories
        let categories = data.categories
        XCTAssertTrue(categories.contains { $0.name == "식비" && $0.transactionType == .variableExpense })
        XCTAssertTrue(categories.contains { $0.name == "월급" && $0.transactionType == .income })
        
        // Verify subcategories
        let subCategories = data.subCategories
        XCTAssertTrue(subCategories.contains { $0.name == "외식비" && $0.transactionType == .variableExpense })
        XCTAssertTrue(subCategories.contains { $0.name == "월급여" && $0.transactionType == .income })
        
        // Verify relationships
        let foodCategory = categories.first { $0.name == "식비" }!
        let salaryCategory = categories.first { $0.name == "월급" }!
        
        XCTAssertTrue(subCategories.contains { $0.categoryId == foodCategory.id && $0.name == "외식비" })
        XCTAssertTrue(subCategories.contains { $0.categoryId == salaryCategory.id && $0.name == "월급여" })
    }
    
    func test_normal_returnsNormalData() {
        // When
        let data = CategoryFactory.normal
        
        // Then
        XCTAssertGreaterThan(data.categories.count, 5)
        XCTAssertGreaterThan(data.subCategories.count, 10)
        
        // Verify transaction type distribution
        let incomeCategories = data.categories.filter { $0.transactionType == .income }
        let fixedExpenseCategories = data.categories.filter { $0.transactionType == .fixedExpense }
        let variableExpenseCategories = data.categories.filter { $0.transactionType == .variableExpense }
        
        XCTAssertGreaterThan(incomeCategories.count, 0)
        XCTAssertGreaterThan(fixedExpenseCategories.count, 0)
        XCTAssertGreaterThan(variableExpenseCategories.count, 0)
        
        // Verify all categories are active
        XCTAssertTrue(data.categories.allSatisfy { $0.isActive })
        XCTAssertTrue(data.subCategories.allSatisfy { $0.isActive })
    }
    
    func test_realistic_returnsRealisticData() {
        // When
        let data = CategoryFactory.realistic()
        
        // Then
        XCTAssertGreaterThan(data.categories.count, 10)
        XCTAssertGreaterThan(data.subCategories.count, 30)
        
        // Verify Korean category names are present
        let categoryNames = data.categories.map { $0.name }
        XCTAssertTrue(categoryNames.contains("급여"))
        XCTAssertTrue(categoryNames.contains("주거비"))
        XCTAssertTrue(categoryNames.contains("식비"))
        XCTAssertTrue(categoryNames.contains("교통비"))
        XCTAssertTrue(categoryNames.contains("쇼핑"))
        
        // Verify subcategory distribution
        let subcategoryNames = data.subCategories.map { $0.name }
        XCTAssertTrue(subcategoryNames.contains("월급"))
        XCTAssertTrue(subcategoryNames.contains("월세"))
        XCTAssertTrue(subcategoryNames.contains("외식"))
        XCTAssertTrue(subcategoryNames.contains("대중교통"))
    }
    
    func test_edge_returnsEdgeCaseData() {
        // When
        let data = CategoryFactory.edge
        
        // Then
        XCTAssertEqual(data.categories.count, 4)
        XCTAssertEqual(data.subCategories.count, 3)
        
        // Verify edge cases
        let categories = data.categories
        let subCategories = data.subCategories
        
        // Very long name
        XCTAssertTrue(categories.contains { $0.name.count > 20 })
        
        // Single character name
        XCTAssertTrue(categories.contains { $0.name == "A" })
        
        // Inactive category
        XCTAssertTrue(categories.contains { !$0.isActive })
        
        // Maximum order index
        XCTAssertTrue(categories.contains { $0.orderIndex == Int.max })
        
        // Very long subcategory name
        XCTAssertTrue(subCategories.contains { $0.name.count > 20 })
        
        // Single character subcategory name
        XCTAssertTrue(subCategories.contains { $0.name == "B" })
        
        // Inactive subcategory
        XCTAssertTrue(subCategories.contains { !$0.isActive })
    }
    
    // MARK: - Category-SubCategory Relationship Tests
    
    func test_categorySubCategoryRelationships_areValid() {
        // When
        let data = CategoryFactory.realistic()
        
        // Then
        for subCategory in data.subCategories {
            // Every subcategory should have a valid parent category
            let parentCategory = data.categories.first { $0.id == subCategory.categoryId }
            XCTAssertNotNil(parentCategory, "SubCategory '\(subCategory.name)' should have a valid parent category")
            
            // Transaction types should match
            if let parent = parentCategory {
                XCTAssertEqual(subCategory.transactionType, parent.transactionType,
                             "SubCategory '\(subCategory.name)' transaction type should match parent category '\(parent.name)'")
                
                // Category metadata should match
                XCTAssertEqual(subCategory.categoryName, parent.name)
                XCTAssertEqual(subCategory.categoryIconName, parent.iconName)
            }
        }
    }
    
    func test_categoryOrderIndexes_areSequential() {
        // When
        let data = CategoryFactory.normal
        
        // Then
        // Group by transaction type and verify order
        let incomeCategories = data.categories.filter { $0.transactionType == .income }.sorted { $0.orderIndex < $1.orderIndex }
        let fixedCategories = data.categories.filter { $0.transactionType == .fixedExpense }.sorted { $0.orderIndex < $1.orderIndex }
        let variableCategories = data.categories.filter { $0.transactionType == .variableExpense }.sorted { $0.orderIndex < $1.orderIndex }
        
        // Verify each type has proper sequential ordering starting from 0
        verifySequentialOrder(incomeCategories)
        verifySequentialOrder(fixedCategories)
        verifySequentialOrder(variableCategories)
    }
    
    private func verifySequentialOrder(_ categories: [CategoryDTO]) {
        if !categories.isEmpty {
            XCTAssertEqual(categories[0].orderIndex, 0, "First category should have order index 0")
            
            for i in 1..<categories.count {
                XCTAssertEqual(categories[i].orderIndex, categories[i-1].orderIndex + 1,
                             "Categories should have sequential order indexes")
            }
        }
    }
    
    // MARK: - TransactionType Distribution Tests
    
    func test_realistic_hasProperTransactionTypeDistribution() {
        // When
        let data = CategoryFactory.realistic()
        
        // Then
        let incomeCount = data.categories.filter { $0.transactionType == .income }.count
        let fixedExpenseCount = data.categories.filter { $0.transactionType == .fixedExpense }.count
        let variableExpenseCount = data.categories.filter { $0.transactionType == .variableExpense }.count
        
        // Variable expenses should be most numerous (typical Korean household)
        XCTAssertGreaterThan(variableExpenseCount, incomeCount)
        XCTAssertGreaterThan(variableExpenseCount, fixedExpenseCount)
        
        // Should have reasonable distribution
        XCTAssertGreaterThan(incomeCount, 2, "Should have multiple income categories")
        XCTAssertGreaterThan(fixedExpenseCount, 3, "Should have multiple fixed expense categories")
        XCTAssertGreaterThan(variableExpenseCount, 5, "Should have multiple variable expense categories")
    }
    
    func test_subcategoryDistribution_matchesParentCategories() {
        // When
        let data = CategoryFactory.realistic()
        
        // Then
        for category in data.categories {
            let relatedSubCategories = data.subCategories.filter { $0.categoryId == category.id }
            
            // Each category should have at least one subcategory
            XCTAssertGreaterThan(relatedSubCategories.count, 0,
                               "Category '\(category.name)' should have at least one subcategory")
            
            // All related subcategories should have correct transaction type
            for subCategory in relatedSubCategories {
                XCTAssertEqual(subCategory.transactionType, category.transactionType,
                             "SubCategory '\(subCategory.name)' should have same transaction type as parent '\(category.name)'")
            }
        }
    }
    
    // MARK: - Random Generation Tests
    
    func test_createRandomCategories_returnsRequestedCount() {
        // Given
        let count = 15
        
        // When
        let categories = CategoryFactory.createRandomCategories(count: count)
        
        // Then
        XCTAssertEqual(categories.count, count)
        
        // Verify all have sequential order indexes
        for (index, category) in categories.enumerated() {
            XCTAssertEqual(category.orderIndex, index)
        }
        
        // Verify all transaction types are represented
        let transactionTypes = Set(categories.map { $0.transactionType })
        XCTAssertTrue(transactionTypes.contains(.income))
        XCTAssertTrue(transactionTypes.contains(.fixedExpense))
        XCTAssertTrue(transactionTypes.contains(.variableExpense))
    }
    
    func test_randomSet_returnsRequestedCounts() {
        // Given
        let categoryCount = 8
        let subCategoryCount = 20
        
        // When
        let data = CategoryFactory.randomSet(categoryCount: categoryCount, subCategoryCount: subCategoryCount)
        
        // Then
        XCTAssertEqual(data.categories.count, categoryCount)
        // SubCategory count might be slightly different due to random distribution
        XCTAssertGreaterThanOrEqual(data.subCategories.count, categoryCount)
        XCTAssertLessThanOrEqual(data.subCategories.count, subCategoryCount)
        
        // Verify relationships
        for subCategory in data.subCategories {
            XCTAssertTrue(data.categories.contains { $0.id == subCategory.categoryId },
                         "Every subcategory should have a valid parent")
        }
    }
    
    // MARK: - Convenience Extension Tests
    
    func test_convenienceExtensions_returnCorrectData() {
        // When
        let realisticCategories = CategoryFactory.realisticCategories()
        let realisticSubCategories = CategoryFactory.realisticSubCategories()
        let normalCategories = CategoryFactory.normalCategories()
        let normalSubCategories = CategoryFactory.normalSubCategories()
        let minimalCategories = CategoryFactory.minimalCategories()
        let minimalSubCategories = CategoryFactory.minimalSubCategories()
        
        // Then
        let fullRealistic = CategoryFactory.realistic()
        let fullNormal = CategoryFactory.normal
        let fullMinimal = CategoryFactory.minimal
        
        XCTAssertEqual(realisticCategories.count, fullRealistic.categories.count)
        XCTAssertEqual(realisticSubCategories.count, fullRealistic.subCategories.count)
        XCTAssertEqual(normalCategories.count, fullNormal.categories.count)
        XCTAssertEqual(normalSubCategories.count, fullNormal.subCategories.count)
        XCTAssertEqual(minimalCategories.count, fullMinimal.categories.count)
        XCTAssertEqual(minimalSubCategories.count, fullMinimal.subCategories.count)
    }
    
    // MARK: - Data Integrity Tests
    
    func test_allScenarios_haveValidCategoryNames() {
        // Given
        let scenarios: [(categories: [CategoryDTO], subCategories: [SubCategoryDTO])] = [
            CategoryFactory.minimal,
            CategoryFactory.normal,
            CategoryFactory.realistic(),
            CategoryFactory.edge
        ]
        
        // When/Then
        for scenario in scenarios {
            for category in scenario.categories {
                XCTAssertFalse(category.name.isEmpty, "Category name should not be empty")
                XCTAssertFalse(category.iconName.isEmpty, "Category icon name should not be empty")
            }
            
            for subCategory in scenario.subCategories {
                XCTAssertFalse(subCategory.name.isEmpty, "SubCategory name should not be empty")
                XCTAssertFalse(subCategory.categoryName.isEmpty, "SubCategory parent name should not be empty")
                XCTAssertFalse(subCategory.categoryIconName.isEmpty, "SubCategory parent icon should not be empty")
            }
        }
    }
    
    func test_allScenarios_haveUniqueIds() {
        // Given
        let data = CategoryFactory.realistic()
        
        // When
        let categoryIds = data.categories.map { $0.id }
        let subCategoryIds = data.subCategories.map { $0.id }
        let allIds = categoryIds + subCategoryIds
        
        // Then
        let uniqueIds = Set(allIds)
        XCTAssertEqual(allIds.count, uniqueIds.count, "All IDs should be unique")
    }
}
