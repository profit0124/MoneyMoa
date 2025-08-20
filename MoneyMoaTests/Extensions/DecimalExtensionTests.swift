//
//  DecimalExtensionTests.swift
//  MoneyMoaTests
//
//  Created by profit on 8/20/25.
//

import XCTest
@testable import MoneyMoa

final class DecimalExtensionTests: XCTestCase {
    
    // MARK: - Setup and Teardown
    
    override func setUpWithError() throws {
        // FormatterManager 초기화를 위해 필요한 경우 추가
    }
    
    override func tearDownWithError() throws {
        // 정리 작업이 필요한 경우 추가
    }
    
    // MARK: - FormattedAmountWithWon Tests
    
    func testFormattedAmountWithWon_WithPositiveValue() {
        // Given
        let amount: Decimal = 15000
        
        // When
        let formatted = amount.formattedAmountWithWon
        
        // Then
        XCTAssertEqual(formatted, "15,000원")
    }
    
    func testFormattedAmountWithWon_WithZero() {
        // Given
        let amount: Decimal = 0
        
        // When
        let formatted = amount.formattedAmountWithWon
        
        // Then
        XCTAssertEqual(formatted, "0원")
    }
    
    func testFormattedAmountWithWon_WithLargeValue() {
        // Given
        let amount: Decimal = 1234567
        
        // When
        let formatted = amount.formattedAmountWithWon
        
        // Then
        XCTAssertEqual(formatted, "1,234,567원")
    }
    
    func testFormattedAmountWithWon_WithNegativeValue() {
        // Given
        let amount: Decimal = -50000
        
        // When
        let formatted = amount.formattedAmountWithWon
        
        // Then
        XCTAssertEqual(formatted, "-50,000원")
    }
    
    // MARK: - FormattedAmountWithoutWon Tests
    
    func testFormattedAmountWithoutWon_WithPositiveValue() {
        // Given
        let amount: Decimal = 25000
        
        // When
        let formatted = amount.formattedAmountWithoutWon
        
        // Then
        XCTAssertEqual(formatted, "25,000")
    }
    
    func testFormattedAmountWithoutWon_WithZero() {
        // Given
        let amount: Decimal = 0
        
        // When
        let formatted = amount.formattedAmountWithoutWon
        
        // Then
        XCTAssertEqual(formatted, "0")
    }
    
    func testFormattedAmountWithoutWon_WithLargeValue() {
        // Given
        let amount: Decimal = 9876543
        
        // When
        let formatted = amount.formattedAmountWithoutWon
        
        // Then
        XCTAssertEqual(formatted, "9,876,543")
    }
    
    // MARK: - FormattedIncomeAmount Tests
    
    func testFormattedIncomeAmount_WithPositiveValue() {
        // Given
        let amount: Decimal = 30000
        
        // When
        let formatted = amount.formattedIncomeAmount
        
        // Then
        XCTAssertEqual(formatted, "+30,000원")
    }
    
    func testFormattedIncomeAmount_WithZero() {
        // Given
        let amount: Decimal = 0
        
        // When
        let formatted = amount.formattedIncomeAmount
        
        // Then
        XCTAssertEqual(formatted, "+0원")
    }
    
    func testFormattedIncomeAmount_WithNegativeValue() {
        // Given
        let amount: Decimal = -15000
        
        // When
        let formatted = amount.formattedIncomeAmount
        
        // Then
        XCTAssertEqual(formatted, "+-15,000원")
    }
    
    // MARK: - FormattedExpenseAmount Tests
    
    func testFormattedExpenseAmount_WithPositiveValue() {
        // Given
        let amount: Decimal = 40000
        
        // When
        let formatted = amount.formattedExpenseAmount
        
        // Then
        XCTAssertEqual(formatted, "-40,000원")
    }
    
    func testFormattedExpenseAmount_WithZero() {
        // Given
        let amount: Decimal = 0
        
        // When
        let formatted = amount.formattedExpenseAmount
        
        // Then
        XCTAssertEqual(formatted, "-0원")
    }
    
    func testFormattedExpenseAmount_WithNegativeValue() {
        // Given
        let amount: Decimal = -25000
        
        // When
        let formatted = amount.formattedExpenseAmount
        
        // Then
        XCTAssertEqual(formatted, "--25,000원")
    }
    
    // MARK: - CurrencyFormatted Tests (FormatterManager Integration)
    
    func testCurrencyFormatted_WithPositiveValue() {
        // Given
        let amount: Decimal = 55000
        
        // When
        let formatted = amount.currencyFormatted
        
        // Then
        XCTAssertEqual(formatted, "₩55,000")
    }
    
    func testCurrencyFormatted_WithZero() {
        // Given
        let amount: Decimal = 0
        
        // When
        let formatted = amount.currencyFormatted
        
        // Then
        XCTAssertEqual(formatted, "₩0")
    }
    
    func testCurrencyFormatted_WithLargeValue() {
        // Given
        let amount: Decimal = 1500000
        
        // When
        let formatted = amount.currencyFormatted
        
        // Then
        XCTAssertEqual(formatted, "₩1,500,000")
    }
    
    func testCurrencyFormatted_ConsistentWithFormatterManager() {
        // Given
        let amount: Decimal = 75000
        
        // When
        let extensionResult = amount.currencyFormatted
        let managerResult = FormatterManager.shared.formatCurrency(amount)
        
        // Then
        XCTAssertEqual(extensionResult, managerResult)
    }
    
    // MARK: - Integration Tests with Mock Data
    
    func testDecimalExtensions_WorkWithMockData() {
        // Given
        let transaction = TransactionDTO.mockLunch
        
        // When
        let withWon = transaction.amount.formattedAmountWithWon
        let withoutWon = transaction.amount.formattedAmountWithoutWon
        let income = transaction.amount.formattedIncomeAmount
        let expense = transaction.amount.formattedExpenseAmount
        let currency = transaction.amount.currencyFormatted
        
        // Then
        XCTAssertFalse(withWon.isEmpty)
        XCTAssertFalse(withoutWon.isEmpty)
        XCTAssertFalse(income.isEmpty)
        XCTAssertFalse(expense.isEmpty)
        XCTAssertFalse(currency.isEmpty)
        
        XCTAssertTrue(withWon.hasSuffix("원"))
        XCTAssertFalse(withoutWon.hasSuffix("원"))
        XCTAssertTrue(income.hasPrefix("+"))
        XCTAssertTrue(expense.hasPrefix("-"))
        XCTAssertTrue(currency.hasPrefix("₩"))
    }
    
    // MARK: - CompactAmountText Tests (Comprehensive Coverage)
    
    func testCompactAmountText_Over99Million() {
        // Given: 99,999,999 초과 금액들
        let testCases: [(Decimal, String)] = [
            (Decimal(100_000_000), "1억+"),      // 정확히 1억
            (Decimal(150_000_000), "1억+"),      // 1.5억
            (Decimal(999_999_999), "1억+"),      // 9.9억
            (Decimal(1_234_567_890), "1억+"),    // 12억
            (Decimal(-150_000_000), "1억+")     // 음수도 절댓값으로 처리
        ]
        
        // When & Then
        for (amount, expected) in testCases {
            let result = amount.compactAmountText
            XCTAssertEqual(result, expected, 
                          "Amount: \(amount) should return '\(expected)', but got '\(result)'")
        }
    }
    
    func testCompactAmountText_TenThousandAndAbove() {
        // Given: 1만 이상 ~ 99,999,999 이하 금액들
        let testCases: [(Decimal, String)] = [
            // 정수 만 단위
            (Decimal(10_000), "1만"),           // 정확히 1만
            (Decimal(50_000), "5만"),           // 5만
            (Decimal(100_000), "10만"),         // 10만
            (Decimal(1_230_000), "123만"),      // 100만
            (Decimal(12_340_000), "1234만"),    // 1000만
            
            // 소수점 포함 (내림 처리)
            (Decimal(15_000), "1만"),           // 1.5만 -> 1만 (내림)
            (Decimal(16_000), "1만"),           // 1.6만 -> 1만 (내림)
            (Decimal(19_999), "1만"),           // 1.9999만 -> 1만 (내림)
            (Decimal(125_000), "12만"),         // 12.5만 -> 12만 (내림)
            (Decimal(126_000), "12만"),         // 12.6만 -> 12만 (내림)
            (Decimal(199_999), "19만"),         // 19.9999만 -> 19만 (내림)
            
            // 음수 테스트
            (Decimal(-50_000), "5만"),          // 음수도 절댓값으로 처리
            (Decimal(-125_000), "12만"),
            (Decimal(-99_999_999), "9999만")   // 음수 한계값
        ]
        
        // When & Then
        for (amount, expected) in testCases {
            let result = amount.compactAmountText
            XCTAssertEqual(result, expected, 
                          "Amount: \(amount) should return '\(expected)', but got '\(result)'")
        }
    }
    
    func testCompactAmountText_BoundaryValues() {
        // Given: 경계값들
        let testCases: [(Decimal, String)] = [
            (Decimal(0), "0"),                  // 0원
            (Decimal(1), "1"),                  // 1원
            (Decimal(100), "100"),              // 100원
            (Decimal(1_000), "1,000"),          // 1,000원 (쉼표 포함)
            (Decimal(5_000), "5,000"),          // 5,000원
            (Decimal(9_999), "9,999"),          // 1만 바로 아래

            (Decimal(10_000), "1만"),           // 1만 정확히
            (Decimal(99_999_999), "9999만"),    // 1억 바로 아래 (9999만으로 표시)
            (Decimal(100_000_000), "1억+"),     // 1억 정확히
            
            // 음수 테스트
            (Decimal(-100), "100"),             // 음수도 절댓값으로 처리
            (Decimal(-5_000), "5,000"),
            (Decimal(-9_999), "9,999")
        ]
        
        // When & Then
        for (amount, expected) in testCases {
            let result = amount.compactAmountText
            XCTAssertEqual(result, expected, 
                          "Boundary value \(amount) should return '\(expected)', but got '\(result)'")
        }
    }
}
