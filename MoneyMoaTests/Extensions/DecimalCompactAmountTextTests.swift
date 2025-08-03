//
//  DecimalCompactAmountTextTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 8/3/25.
//

import XCTest
@testable import MoneyMoa

// MARK: - DecimalCompactAmountTextTests

final class DecimalCompactAmountTextTests: XCTestCase {
    
    override func setUpWithError() throws {
        // FormatterManager 초기화를 위해 필요한 경우 추가
    }
    
    override func tearDownWithError() throws {
        // 정리 작업이 필요한 경우 추가
    }
    
    // MARK: - 99,999,999 초과 케이스 테스트
    
    func testCompactAmountText_Over99Million() {
        // Given: 99,999,999 초과 금액들
        let testCases: [(Decimal, String)] = [
            (Decimal(100_000_000), "1억+"),      // 정확히 1억
            (Decimal(150_000_000), "1억+"),      // 1.5억
            (Decimal(999_999_999), "1억+"),      // 9.9억
            (Decimal(1_234_567_890), "1억+"),    // 12억
            (Decimal(-150_000_000), "1억+"),     // 음수도 절댓값으로 처리
        ]
        
        // When & Then
        for (amount, expected) in testCases {
            let result = amount.compactAmountText
            XCTAssertEqual(result, expected, 
                          "Amount: \(amount) should return '\(expected)', but got '\(result)'")
        }
    }
    
    // MARK: - 1만 이상 케이스 테스트
    
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
            (Decimal(-99_999_999), "9999만"),   // 음수 한계값
        ]
        
        // When & Then
        for (amount, expected) in testCases {
            let result = amount.compactAmountText
            XCTAssertEqual(result, expected, 
                          "Amount: \(amount) should return '\(expected)', but got '\(result)'")
        }
    }
    
    // MARK: - 경계값 테스트
    
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
            (Decimal(-9_999), "9,999"),
        ]
        
        // When & Then
        for (amount, expected) in testCases {
            let result = amount.compactAmountText
            XCTAssertEqual(result, expected, 
                          "Boundary value \(amount) should return '\(expected)', but got '\(result)'")
        }
    }
}
