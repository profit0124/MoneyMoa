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
        let summaryData = SummaryDisplayData(
            currentMonthExpense: 800_000,
            previousMonthExpense: 600_000,
            monthlyComparison: 200_000,
            comparisonPercentage: 0.33,
            hasPreviousMonthData: true,
            budget: .mockStandard,
            remainingBudget: 1_200_000,
            budgetUsagePercentage: 0.4
        )
        
        // When & Then
        XCTAssertTrue(summaryData.hasBudget)
    }
    
    func test_hasBudget_withoutBudget_returnsFalse() {
        // Given
        let summaryData = SummaryDisplayData(
            currentMonthExpense: 500_000,
            previousMonthExpense: 400_000,
            monthlyComparison: 100_000,
            comparisonPercentage: 0.25,
            hasPreviousMonthData: true,
            budget: nil,
            remainingBudget: nil,
            budgetUsagePercentage: nil
        )
        
        // When & Then
        XCTAssertFalse(summaryData.hasBudget)
    }
    
    func test_isBudgetExceeded_withExceededBudget_returnsTrue() {
        // Given
        let summaryData = SummaryDisplayData(
            currentMonthExpense: 1_200_000,
            previousMonthExpense: 800_000,
            monthlyComparison: 400_000,
            comparisonPercentage: 0.5,
            hasPreviousMonthData: true,
            budget: .mockStandard, // 1,000,000
            remainingBudget: -200_000,
            budgetUsagePercentage: 1.2
        )
        
        // When & Then
        XCTAssertTrue(summaryData.isBudgetExceeded)
    }
    
    func test_isBudgetExceeded_withinBudget_returnsFalse() {
        // Given
        let summaryData = SummaryDisplayData(
            currentMonthExpense: 800_000,
            previousMonthExpense: 600_000,
            monthlyComparison: 200_000,
            comparisonPercentage: 0.33,
            hasPreviousMonthData: true,
            budget: .mockStandard, // 2,000,000
            remainingBudget: 1_200_000,
            budgetUsagePercentage: 0.4
        )
        
        // When & Then
        XCTAssertFalse(summaryData.isBudgetExceeded)
    }
    
    func test_isBudgetExceeded_withoutBudget_returnsFalse() {
        // Given
        let summaryData = SummaryDisplayData(
            currentMonthExpense: 500_000,
            previousMonthExpense: 400_000,
            monthlyComparison: 100_000,
            comparisonPercentage: 0.25,
            hasPreviousMonthData: true,
            budget: nil,
            remainingBudget: nil,
            budgetUsagePercentage: nil
        )
        
        // When & Then
        XCTAssertFalse(summaryData.isBudgetExceeded)
    }
    
    // MARK: - Test Methods - Computed Properties - Expense Comparison
    
    func test_isExpenseIncreased_withIncreasedExpense_returnsTrue() {
        // Given
        let summaryData = SummaryDisplayData(
            currentMonthExpense: 800_000,
            previousMonthExpense: 600_000,
            monthlyComparison: 200_000,
            comparisonPercentage: 0.33,
            hasPreviousMonthData: true
        )
        
        // When & Then
        XCTAssertTrue(summaryData.isExpenseIncreased)
        XCTAssertFalse(summaryData.isExpenseDecreased)
        XCTAssertFalse(summaryData.isExpenseUnchanged)
    }
    
    func test_isExpenseDecreased_withDecreasedExpense_returnsTrue() {
        // Given
        let summaryData = SummaryDisplayData(
            currentMonthExpense: 400_000,
            previousMonthExpense: 600_000,
            monthlyComparison: -200_000,
            comparisonPercentage: -0.33,
            hasPreviousMonthData: true
        )
        
        // When & Then
        XCTAssertFalse(summaryData.isExpenseIncreased)
        XCTAssertTrue(summaryData.isExpenseDecreased)
        XCTAssertFalse(summaryData.isExpenseUnchanged)
    }
    
    func test_isExpenseUnchanged_withSameExpense_returnsTrue() {
        // Given
        let summaryData = SummaryDisplayData(
            currentMonthExpense: 600_000,
            previousMonthExpense: 600_000,
            monthlyComparison: 0,
            comparisonPercentage: 0.0,
            hasPreviousMonthData: true
        )
        
        // When & Then
        XCTAssertFalse(summaryData.isExpenseIncreased)
        XCTAssertFalse(summaryData.isExpenseDecreased)
        XCTAssertTrue(summaryData.isExpenseUnchanged)
    }
    
    func test_expenseComparison_withNoComparison_returnsAllFalse() {
        // Given
        let summaryData = SummaryDisplayData(
            currentMonthExpense: 600_000,
            previousMonthExpense: 0,
            monthlyComparison: nil,
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
        let summaryData = SummaryDisplayData(
            currentMonthExpense: 800_000,
            previousMonthExpense: 600_000,
            monthlyComparison: 200_000,
            comparisonPercentage: 0.33,
            hasPreviousMonthData: true
        )
        
        // When & Then
        XCTAssertTrue(summaryData.canShowComparison)
    }
    
    func test_canShowComparison_withZeroPreviousExpense_returnsFalse() {
        // Given
        let summaryData = SummaryDisplayData(
            currentMonthExpense: 800_000,
            previousMonthExpense: 0,
            monthlyComparison: nil,
            comparisonPercentage: nil,
            hasPreviousMonthData: true
        )
        
        // When & Then
        XCTAssertFalse(summaryData.canShowComparison)
    }
    
    func test_canShowComparison_withNoPreviousData_returnsFalse() {
        // Given
        let summaryData = SummaryDisplayData(
            currentMonthExpense: 800_000,
            previousMonthExpense: 600_000,
            monthlyComparison: nil,
            comparisonPercentage: nil,
            hasPreviousMonthData: false
        )
        
        // When & Then
        XCTAssertFalse(summaryData.canShowComparison)
    }
}
