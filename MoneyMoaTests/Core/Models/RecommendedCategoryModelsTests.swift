//
//  RecommendedCategoryModelsTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 8/21/25.
//

import XCTest
@testable import MoneyMoa

final class RecommendedCategoryModelsTests: XCTestCase {
    
    // MARK: - JSON Decoding Tests
    
    func testRecommendedCategoryData_ShouldDecodeFromJSON() throws {
        // Given
        let jsonString = """
        [
          {
            "transactionType": "income",
            "categories": [
              {
                "name": "근로소득",
                "iconName": "briefcase.fill",
                "subCategories": [
                  { "name": "급여" },
                  { "name": "보너스" }
                ]
              }
            ]
          }
        ]
        """
        let jsonData = jsonString.data(using: .utf8)!
        
        // When
        let decodedData = try JSONDecoder().decode([RecommendedCategoryData].self, from: jsonData)
        
        // Then
        XCTAssertEqual(decodedData.count, 1)
        
        let firstItem = decodedData[0]
        XCTAssertEqual(firstItem.transactionType, "income")
        XCTAssertEqual(firstItem.categories.count, 1)
        
        let firstCategory = firstItem.categories[0]
        XCTAssertEqual(firstCategory.name, "근로소득")
        XCTAssertEqual(firstCategory.iconName, "briefcase.fill")
        XCTAssertEqual(firstCategory.subCategories.count, 2)
        XCTAssertEqual(firstCategory.subCategories[0].name, "급여")
        XCTAssertEqual(firstCategory.subCategories[1].name, "보너스")
    }
    
    func testRecommendedCategory_ShouldDecodeWithEmptySubCategories() throws {
        // Given
        let jsonString = """
        {
          "name": "테스트 카테고리",
          "iconName": "test.icon",
          "subCategories": []
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        
        // When
        let decodedCategory = try JSONDecoder().decode(RecommendedCategory.self, from: jsonData)
        
        // Then
        XCTAssertEqual(decodedCategory.name, "테스트 카테고리")
        XCTAssertEqual(decodedCategory.iconName, "test.icon")
        XCTAssertEqual(decodedCategory.subCategories.count, 0)
    }
    
    func testRecommendedSubCategory_ShouldDecodeCorrectly() throws {
        // Given
        let jsonString = """
        {
          "name": "테스트 서브카테고리"
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        
        // When
        let decodedSubCategory = try JSONDecoder().decode(RecommendedSubCategory.self, from: jsonData)
        
        // Then
        XCTAssertEqual(decodedSubCategory.name, "테스트 서브카테고리")
    }
    
    // MARK: - TransactionType Conversion Tests
    
    func testTransactionTypeEnum_WithValidIncomeType_ShouldReturnIncome() {
        // Given
        let categoryData = RecommendedCategoryData(
            transactionType: "income",
            categories: []
        )
        
        // When
        let transactionType = categoryData.transactionTypeEnum
        
        // Then
        XCTAssertEqual(transactionType, .income)
    }
    
    func testTransactionTypeEnum_WithValidFixedExpenseType_ShouldReturnFixedExpense() {
        // Given
        let categoryData = RecommendedCategoryData(
            transactionType: "fixedExpense",
            categories: []
        )
        
        // When
        let transactionType = categoryData.transactionTypeEnum
        
        // Then
        XCTAssertEqual(transactionType, .fixedExpense)
    }
    
    func testTransactionTypeEnum_WithValidVariableExpenseType_ShouldReturnVariableExpense() {
        // Given
        let categoryData = RecommendedCategoryData(
            transactionType: "variableExpense",
            categories: []
        )
        
        // When
        let transactionType = categoryData.transactionTypeEnum
        
        // Then
        XCTAssertEqual(transactionType, .variableExpense)
    }
    
    func testTransactionTypeEnum_WithInvalidType_ShouldReturnVariableExpense() {
        // Given
        let categoryData = RecommendedCategoryData(
            transactionType: "invalidType",
            categories: []
        )
        
        // When
        let transactionType = categoryData.transactionTypeEnum
        
        // Then
        XCTAssertEqual(transactionType, .variableExpense, "잘못된 타입은 기본값 variableExpense를 반환해야 합니다")
    }
    
    func testTransactionTypeEnum_WithEmptyString_ShouldReturnVariableExpense() {
        // Given
        let categoryData = RecommendedCategoryData(
            transactionType: "",
            categories: []
        )
        
        // When
        let transactionType = categoryData.transactionTypeEnum
        
        // Then
        XCTAssertEqual(transactionType, .variableExpense, "빈 문자열은 기본값 variableExpense를 반환해야 합니다")
    }
    
    // MARK: - Complex JSON Decoding Tests
    
    func testComplexJSON_ShouldDecodeAllTransactionTypes() throws {
        // Given
        let jsonData = createComplexTestJSONData()
        
        // When
        let decodedData = try JSONDecoder().decode([RecommendedCategoryData].self, from: jsonData)
        
        // Then
        XCTAssertEqual(decodedData.count, 3)
        verifyIncomeData(in: decodedData)
        verifyFixedExpenseData(in: decodedData)
        verifyVariableExpenseData(in: decodedData)
    }
    
    private func createComplexTestJSONData() -> Data {
        let jsonString = """
        [
          {
            "transactionType": "income",
            "categories": [
              {
                "name": "근로소득",
                "iconName": "briefcase.fill",
                "subCategories": [
                  { "name": "급여" }
                ]
              }
            ]
          },
          {
            "transactionType": "fixedExpense",
            "categories": [
              {
                "name": "주거비",
                "iconName": "house.fill",
                "subCategories": [
                  { "name": "월세" },
                  { "name": "관리비" }
                ]
              }
            ]
          },
          {
            "transactionType": "variableExpense",
            "categories": [
              {
                "name": "식비",
                "iconName": "fork.knife",
                "subCategories": [
                  { "name": "외식" },
                  { "name": "식료품" },
                  { "name": "커피" }
                ]
              }
            ]
          }
        ]
        """
        return jsonString.data(using: .utf8)!
    }
    
    private func verifyIncomeData(in decodedData: [RecommendedCategoryData]) {
        let incomeData = decodedData.first { $0.transactionType == "income" }!
        XCTAssertEqual(incomeData.transactionTypeEnum, .income)
        XCTAssertEqual(incomeData.categories.count, 1)
        XCTAssertEqual(incomeData.categories[0].subCategories.count, 1)
    }
    
    private func verifyFixedExpenseData(in decodedData: [RecommendedCategoryData]) {
        let fixedExpenseData = decodedData.first { $0.transactionType == "fixedExpense" }!
        XCTAssertEqual(fixedExpenseData.transactionTypeEnum, .fixedExpense)
        XCTAssertEqual(fixedExpenseData.categories.count, 1)
        XCTAssertEqual(fixedExpenseData.categories[0].subCategories.count, 2)
    }
    
    private func verifyVariableExpenseData(in decodedData: [RecommendedCategoryData]) {
        let variableExpenseData = decodedData.first { $0.transactionType == "variableExpense" }!
        XCTAssertEqual(variableExpenseData.transactionTypeEnum, .variableExpense)
        XCTAssertEqual(variableExpenseData.categories.count, 1)
        XCTAssertEqual(variableExpenseData.categories[0].subCategories.count, 3)
    }
    
    // MARK: - Error Handling Tests
    
    func testDecoding_WithMissingRequiredFields_ShouldThrowError() {
        // Given - transactionType 필드가 없는 JSON
        let jsonString = """
        [
          {
            "categories": []
          }
        ]
        """
        let jsonData = jsonString.data(using: .utf8)!
        
        // When & Then
        XCTAssertThrowsError(try JSONDecoder().decode([RecommendedCategoryData].self, from: jsonData)) { error in
            XCTAssertTrue(error is DecodingError, "DecodingError가 발생해야 합니다")
        }
    }
    
    func testDecoding_WithInvalidJSON_ShouldThrowError() {
        // Given
        let invalidJsonString = """
        {
          "invalid": json
        }
        """
        let jsonData = invalidJsonString.data(using: .utf8)!
        
        // When & Then
        XCTAssertThrowsError(try JSONDecoder().decode([RecommendedCategoryData].self, from: jsonData)) { error in
            XCTAssertTrue(error is DecodingError, "DecodingError가 발생해야 합니다")
        }
    }
}

// Test Helper
