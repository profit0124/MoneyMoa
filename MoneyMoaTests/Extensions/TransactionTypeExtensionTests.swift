//
//  TransactionTypeExtensionTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 8/3/25.
//

import XCTest
import SwiftUI
@testable import MoneyMoa

final class TransactionTypeExtensionTests: XCTestCase {
    
    // MARK: - Color Tests
    
    func testTransactionTypeColors() {
        // Given & When & Then
        XCTAssertEqual(TransactionType.income.color, .green)
        XCTAssertEqual(TransactionType.fixedExpense.color, .orange)
        XCTAssertEqual(TransactionType.variableExpense.color, .red)
    }
    
    // MARK: - Amount Formatting Tests
    
    func testFormatAmountForIncome() {
        // Given
        let transactionType = TransactionType.income
        let amount: Decimal = 50000
        
        // When
        let formattedAmount = transactionType.formatAmount(amount)
        
        // Then
        XCTAssertEqual(formattedAmount, "+50,000원")
    }
    
    func testFormatAmountForFixedExpense() {
        // Given
        let transactionType = TransactionType.fixedExpense
        let amount: Decimal = 80000
        
        // When
        let formattedAmount = transactionType.formatAmount(amount)
        
        // Then
        XCTAssertEqual(formattedAmount, "-80,000원")
    }
    
    func testFormatAmountForVariableExpense() {
        // Given
        let transactionType = TransactionType.variableExpense
        let amount: Decimal = 15000
        
        // When
        let formattedAmount = transactionType.formatAmount(amount)
        
        // Then
        XCTAssertEqual(formattedAmount, "-15,000원")
    }
    
    func testFormatAmountWithZero() {
        // Given
        let amount: Decimal = 0
        
        // When & Then
        XCTAssertEqual(TransactionType.income.formatAmount(amount), "+0원")
        XCTAssertEqual(TransactionType.fixedExpense.formatAmount(amount), "-0원")
        XCTAssertEqual(TransactionType.variableExpense.formatAmount(amount), "-0원")
    }
    
    func testFormatAmountWithLargeNumbers() {
        // Given
        let amount: Decimal = 1234567
        
        // When & Then
        XCTAssertEqual(TransactionType.income.formatAmount(amount), "+1,234,567원")
        XCTAssertEqual(TransactionType.fixedExpense.formatAmount(amount), "-1,234,567원")
        XCTAssertEqual(TransactionType.variableExpense.formatAmount(amount), "-1,234,567원")
    }
}
