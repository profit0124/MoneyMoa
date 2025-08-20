//
//  FormatterExtensionsTests.swift
//  MoneyMoaTests
//
//  Created by profit on 8/20/25.
//

import XCTest
@testable import MoneyMoa

final class FormatterExtensionsTests: XCTestCase {
    
    // MARK: - Decimal Extensions Tests
    
    func testDecimalCurrencyFormatted_WithPositiveValue_ReturnsFormattedString() {
        // Given
        let amount: Decimal = 15000
        
        // When
        let formatted = amount.currencyFormatted
        
        // Then
        XCTAssertEqual(formatted, "₩15,000")
    }
    
    func testDecimalCurrencyFormatted_WithZero_ReturnsZeroString() {
        // Given
        let amount: Decimal = 0
        
        // When
        let formatted = amount.currencyFormatted
        
        // Then
        XCTAssertEqual(formatted, "₩0")
    }
    
    func testDecimalCurrencyFormatted_WithLargeValue_ReturnsFormattedString() {
        // Given
        let amount: Decimal = 1234567
        
        // When
        let formatted = amount.currencyFormatted
        
        // Then
        XCTAssertEqual(formatted, "₩1,234,567")
    }
    
    func testDecimalCurrencyFormatted_ConsistentWithFormatterManager() {
        // Given
        let amount: Decimal = 50000
        
        // When
        let extensionResult = amount.currencyFormatted
        let managerResult = FormatterManager.shared.formatCurrency(amount)
        
        // Then
        XCTAssertEqual(extensionResult, managerResult)
    }
    
    // MARK: - Date Extensions Tests
    
    func testDateOnlyFormatted_ReturnsCorrectFormat() {
        // Given
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: 2025, month: 8, day: 20))!
        
        // When
        let formatted = date.dateOnlyFormatted
        
        // Then
        XCTAssertTrue(formatted.contains("2025년"))
        XCTAssertTrue(formatted.contains("8월"))
        XCTAssertTrue(formatted.contains("20일"))
    }
    
    func testTimeOnlyFormatted_ReturnsCorrectFormat() {
        // Given
        let calendar = FormatterManager.shared.koreaCalendar
        let date = calendar.date(from: DateComponents(year: 2025, month: 8, day: 20, hour: 14, minute: 30))!
        
        // When
        let formatted = date.timeOnlyFormatted
        
        // Then
        XCTAssertEqual(formatted, "14:30")
    }
    
    func testTransactionFormatted_ReturnsCorrectFormat() {
        // Given
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: 2025, month: 8, day: 20))!
        
        // When
        let formatted = date.transactionFormatted
        
        // Then
        XCTAssertTrue(formatted.contains("2025.08.20"))
    }
    
    func testDateExtensions_ConsistentWithFormatterManager() {
        // Given
        let date = Date()
        
        // When & Then
        XCTAssertEqual(
            date.dateOnlyFormatted,
            FormatterManager.shared.formatDate(date, format: .dateOnly)
        )
        
        XCTAssertEqual(
            date.timeOnlyFormatted,
            FormatterManager.shared.formatDate(date, format: .timeOnly)
        )
        
        XCTAssertEqual(
            date.transactionFormatted,
            FormatterManager.shared.formatDate(date, format: .transaction)
        )
    }
    
    // MARK: - Integration Tests
    
    func testExtensions_WorkWithMockData() {
        // Given
        let transaction = TransactionDTO.mockLunch
        
        // When
        let formattedAmount = transaction.amount.currencyFormatted
        let formattedDate = transaction.date.dateOnlyFormatted
        let formattedTime = transaction.date.timeOnlyFormatted
        
        // Then
        XCTAssertFalse(formattedAmount.isEmpty)
        XCTAssertFalse(formattedDate.isEmpty)
        XCTAssertFalse(formattedTime.isEmpty)
        XCTAssertTrue(formattedAmount.starts(with: "₩"))
    }
}
