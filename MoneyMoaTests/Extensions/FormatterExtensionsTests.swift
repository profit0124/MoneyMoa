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
        // 통화 기호와 포맷팅된 숫자가 포함되어 있는지 확인 (지역별로 다름)
        XCTAssertTrue(formatted.contains("15,000") || formatted.contains("15.000"))
        XCTAssertFalse(formatted.isEmpty)
    }
    
    func testDecimalCurrencyFormatted_WithZero_ReturnsZeroString() {
        // Given
        let amount: Decimal = 0
        
        // When
        let formatted = amount.currencyFormatted
        
        // Then
        XCTAssertTrue(formatted.contains("0"))
        XCTAssertFalse(formatted.isEmpty)
    }
    
    func testDecimalCurrencyFormatted_WithLargeValue_ReturnsFormattedString() {
        // Given
        let amount: Decimal = 1234567
        
        // When
        let formatted = amount.currencyFormatted
        
        // Then
        XCTAssertTrue(formatted.contains("1,234,567") || formatted.contains("1.234.567"))
        XCTAssertFalse(formatted.isEmpty)
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
        // 날짜 정보가 포함되어 있는지 확인 (형식은 로케일별로 다름)
        XCTAssertTrue(formatted.contains("2025"))
        XCTAssertTrue(formatted.contains("8") || formatted.contains("Aug"))
        XCTAssertTrue(formatted.contains("20"))
        XCTAssertFalse(formatted.isEmpty)
    }
    
    func testTimeOnlyFormatted_ReturnsCorrectFormat() {
        // Given
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: 2025, month: 8, day: 20, hour: 14, minute: 30))!
        
        // When
        let formatted = date.timeOnlyFormatted
        
        // Then
        // 시간 정보가 포함되어 있는지 확인 (형식은 로케일별로 다름)
        XCTAssertTrue(formatted.contains("14:30") || formatted.contains("2:30"))
        XCTAssertFalse(formatted.isEmpty)
    }
    
    func testTransactionFormatted_ReturnsCorrectFormat() {
        // Given
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: 2025, month: 8, day: 20))!
        
        // When
        let formatted = date.transactionFormatted
        
        // Then
        // 거래 날짜 형식이 올바른지 확인 (형식은 로케일별로 다름)
        XCTAssertTrue(formatted.contains("2025") || formatted.contains("25"))
        XCTAssertTrue(formatted.contains("8") || formatted.contains("08") || formatted.contains("Aug"))
        XCTAssertTrue(formatted.contains("20"))
        XCTAssertFalse(formatted.isEmpty)
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
        // 통화 기호 확인 (지역별로 다름)
        XCTAssertFalse(formattedAmount.isEmpty)
    }
}
