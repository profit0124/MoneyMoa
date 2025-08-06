//
//  SummaryDisplayDataTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 8/6/25.
//

import XCTest
@testable import MoneyMoa

// MARK: - SummaryDisplayDataTests

final class SummaryDisplayDataTests: XCTestCase {
    
    // MARK: - Test Methods - Computed Properties - Budget
    
    func test_hasBudget_withBudget_returnsTrue() {
        // Given
        let summaryData = TestDataFactory.createSummaryDisplayDataWithBudget()
        
        // When & Then
        XCTAssertTrue(summaryData.hasBudget)
    }
    
    func test_hasBudget_withoutBudget_returnsFalse() {
        // Given
        let summaryData = TestDataFactory.createSummaryDisplayDataWithoutBudget()
        
        // When & Then
        XCTAssertFalse(summaryData.hasBudget)
    }
    
    func test_isBudgetExceeded_withExceededBudget_returnsTrue() {
        // Given
        let summaryData = TestDataFactory.createSummaryDisplayDataWithBudget(
            currentMonthExpense: 1_200_000, // 예산 초과
            budgetAmount: 1_000_000
        )
        
        // When & Then
        XCTAssertTrue(summaryData.isBudgetExceeded)
    }
    
    func test_isBudgetExceeded_withinBudget_returnsFalse() {
        // Given
        let summaryData = TestDataFactory.createSummaryDisplayDataWithBudget(
            currentMonthExpense: 800_000, // 예산 내
            budgetAmount: 2_000_000
        )
        
        // When & Then
        XCTAssertFalse(summaryData.isBudgetExceeded)
    }
    
    func test_isBudgetExceeded_withoutBudget_returnsFalse() {
        // Given
        let summaryData = TestDataFactory.createSummaryDisplayDataWithoutBudget()
        
        // When & Then
        XCTAssertFalse(summaryData.isBudgetExceeded)
    }
    
    // MARK: - Test Methods - Computed Properties - Expense Comparison
    
    func test_isExpenseIncreased_withIncreasedExpense_returnsTrue() {
        // Given
        let summaryData = TestDataFactory.createSummaryDisplayData(
            currentMonthExpense: 800_000,
            previousMonthExpense: 600_000,
            monthlyComparison: 200_000, // 증가
            comparisonPercentage: 0.33
        )
        
        // When & Then
        XCTAssertTrue(summaryData.isExpenseIncreased)
        XCTAssertFalse(summaryData.isExpenseDecreased)
        XCTAssertFalse(summaryData.isExpenseUnchanged)
    }
    
    func test_isExpenseDecreased_withDecreasedExpense_returnsTrue() {
        // Given
        let summaryData = TestDataFactory.createSummaryDisplayData(
            currentMonthExpense: 400_000,
            previousMonthExpense: 600_000,
            monthlyComparison: -200_000, // 감소
            comparisonPercentage: -0.33
        )
        
        // When & Then
        XCTAssertFalse(summaryData.isExpenseIncreased)
        XCTAssertTrue(summaryData.isExpenseDecreased)
        XCTAssertFalse(summaryData.isExpenseUnchanged)
    }
    
    func test_isExpenseUnchanged_withSameExpense_returnsTrue() {
        // Given
        let summaryData = TestDataFactory.createSummaryDisplayData(
            currentMonthExpense: 600_000,
            previousMonthExpense: 600_000,
            monthlyComparison: 0, // 동일
            comparisonPercentage: 0.0
        )
        
        // When & Then
        XCTAssertFalse(summaryData.isExpenseIncreased)
        XCTAssertFalse(summaryData.isExpenseDecreased)
        XCTAssertTrue(summaryData.isExpenseUnchanged)
    }
    
    func test_expenseComparison_withNoComparison_returnsAllFalse() {
        // Given
        let summaryData = TestDataFactory.createSummaryDisplayData(
            currentMonthExpense: 600_000,
            previousMonthExpense: 0,
            monthlyComparison: nil, // 비교 데이터 없음
            comparisonPercentage: nil,
            hasPreviousMonthData: false
        )
        
        // When & Then
        XCTAssertFalse(summaryData.isExpenseIncreased)
        XCTAssertFalse(summaryData.isExpenseDecreased)
        XCTAssertFalse(summaryData.isExpenseUnchanged)
    }
    
    // MARK: - Test Methods - Computed Properties - Display Logic
    
    func test_canShowComparison_withValidPreviousData_returnsTrue() {
        // Given
        let summaryData = TestDataFactory.createSummaryDisplayData(
            currentMonthExpense: 800_000,
            previousMonthExpense: 600_000, // > 0
            hasPreviousMonthData: true // true
        )
        
        // When & Then
        XCTAssertTrue(summaryData.canShowComparison)
    }
    
    func test_canShowComparison_withZeroPreviousExpense_returnsFalse() {
        // Given
        let summaryData = TestDataFactory.createSummaryDisplayData(
            currentMonthExpense: 800_000,
            previousMonthExpense: 0, // = 0
            monthlyComparison: nil,
            comparisonPercentage: nil,
            hasPreviousMonthData: true
        )
        
        // When & Then
        XCTAssertFalse(summaryData.canShowComparison)
    }
    
    func test_canShowComparison_withNoPreviousData_returnsFalse() {
        // Given
        let summaryData = TestDataFactory.createSummaryDisplayData(
            currentMonthExpense: 800_000,
            previousMonthExpense: 600_000,
            monthlyComparison: nil,
            comparisonPercentage: nil,
            hasPreviousMonthData: false // false
        )
        
        // When & Then
        XCTAssertFalse(summaryData.canShowComparison)
    }
}