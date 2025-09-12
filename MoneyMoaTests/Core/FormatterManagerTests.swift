//
//  FormatterManagerTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 8/3/25.
//

import XCTest
@testable import MoneyMoa

final class FormatterManagerTests: XCTestCase {
    
    var formatterManager: FormatterManager!
    
    override func setUpWithError() throws {
        super.setUp()
        formatterManager = FormatterManager.shared
    }
    
    override func tearDownWithError() throws {
        formatterManager = nil
        super.tearDown()
    }
    
    // MARK: - Korean Locale Tests
    
    func testAmountFormatterUsesKoreanLocale() {
        // Given
        let formatter = formatterManager.amountFormatter
        
        // When & Then
        XCTAssertEqual(formatter.locale.identifier, "ko_KR")
        XCTAssertEqual(formatter.numberStyle, .decimal)
        XCTAssertEqual(formatter.maximumFractionDigits, 0)
    }
    
    func testTransactionDateFormatterUsesKoreanLocale() {
        // Given
        let formatter = formatterManager.transactionDateFormatter
        
        // When & Then
        XCTAssertEqual(formatter.locale.identifier, "ko_KR")
        XCTAssertEqual(formatter.dateFormat, "yyyy.MM.dd (E)")
    }
    
    // MARK: - Amount Formatting Tests
    
    func testAmountFormatterWithVariousNumbers() {
        // Given
        let formatter = formatterManager.amountFormatter
        
        // When & Then
        XCTAssertEqual(formatter.string(from: 0), "0")
        XCTAssertEqual(formatter.string(from: 1000), "1,000")
        XCTAssertEqual(formatter.string(from: 50000), "50,000")
        XCTAssertEqual(formatter.string(from: 1234567), "1,234,567")
    }
    
    // MARK: - Date Formatting Tests
    
    func testTransactionDateFormatterOutput() {
        // Given
        let formatter = formatterManager.transactionDateFormatter
        let calendar = Calendar.current

        // Create test date: 2025년 8월 3일
        let components = DateComponents(year: 2025, month: 8, day: 3)
        guard let testDate = calendar.date(from: components) else {
            XCTFail("Failed to create test date")
            return
        }
        
        // When
        let formattedDate = formatter.string(from: testDate)
        
        // Then
        XCTAssertTrue(formattedDate.contains("2025"))
        XCTAssertTrue(formattedDate.contains("08"))
        XCTAssertTrue(formattedDate.contains("03"))
    }
    
    // MARK: - Lazy Loading Tests
    
    func testLazyLoadingBehavior() {
        // Given
        let shared = formatterManager!
        
        // When
        let formatter1 = shared.amountFormatter
        let formatter2 = shared.amountFormatter
        
        // Then - 같은 인스턴스는 같은 formatter를 반환해야 함
        XCTAssertIdentical(formatter1, formatter2)
        
        // Different property access should return different objects
        let dateFormatter = shared.transactionDateFormatter
        
        XCTAssertNotNil(dateFormatter)
    }
    
    // MARK: - Shared Instance Tests
    
    func testSharedInstanceConsistency() {
        // Given
        let shared1 = FormatterManager.shared
        let shared2 = FormatterManager.shared
        
        // When & Then
        XCTAssertIdentical(shared1, shared2)
        XCTAssertIdentical(shared1.amountFormatter, shared2.amountFormatter)
    }
}
