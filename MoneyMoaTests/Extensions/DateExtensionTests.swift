//
//  DateExtensionTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 8/3/25.
//

import XCTest
@testable import MoneyMoa

final class DateExtensionTests: XCTestCase {
    
    var formatterManager: FormatterManager!
    var calendar: Calendar!
    
    override func setUpWithError() throws {
        formatterManager = FormatterManager.shared
        calendar = formatterManager.koreaCalendar
    }
    
    override func tearDownWithError() throws {
        formatterManager = nil
        calendar = nil
    }
    
    // MARK: - Transaction List Section Header Tests
    
    func testTransactionListSectionHeader_Today() {
        // Given: 현재 시간
        let today = Date()
        
        // When: 오늘 날짜의 섹션 헤더 생성
        let header = today.transactionListSectionHeader
        
        // Then: "오늘" 반환
        XCTAssertEqual(header, "오늘")
    }
    
    func testTransactionListSectionHeader_Yesterday() {
        // Given: 어제 날짜
        let today = Date()
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else {
            XCTFail("Failed to create yesterday date")
            return
        }
        
        // When: 어제 날짜의 섹션 헤더 생성
        let header = yesterday.transactionListSectionHeader
        
        // Then: "어제" 반환
        XCTAssertEqual(header, "어제")
    }
    
    func testTransactionListSectionHeader_TwoDaysAgo() {
        // Given: 2일전 날짜
        let today = Date()
        guard let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today) else {
            XCTFail("Failed to create two days ago date")
            return
        }
        
        // When: 2일전 날짜의 섹션 헤더 생성
        let header = twoDaysAgo.transactionListSectionHeader
        
        // Then: "2일전" 반환
        XCTAssertEqual(header, "2일전")
    }
    
    func testTransactionListSectionHeader_ThreeDaysAgo() {
        // Given: 3일전 날짜
        let today = Date()
        guard let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today) else {
            XCTFail("Failed to create three days ago date")
            return
        }
        
        // When: 3일전 날짜의 섹션 헤더 생성
        let header = threeDaysAgo.transactionListSectionHeader
        
        // Then: "3일전" 반환
        XCTAssertEqual(header, "3일전")
    }
    
    func testTransactionListSectionHeader_OneWeekAgo() {
        // Given: 일주일 전 날짜
        let today = Date()
        guard let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: today) else {
            XCTFail("Failed to create one week ago date")
            return
        }
        
        // When: 일주일 전 날짜의 섹션 헤더 생성
        let header = oneWeekAgo.transactionListSectionHeader
        
        // Then: 포맷된 날짜 문자열 반환 (yyyy.MM.dd (E) 형식)
        let formatter = formatterManager.transactionDateFormatter
        let expectedHeader = formatter.string(from: oneWeekAgo)
        XCTAssertEqual(header, expectedHeader)
        
        // 포맷 검증
        XCTAssertTrue(header.contains("."))
        XCTAssertTrue(header.contains("("))
        XCTAssertTrue(header.contains(")"))
    }
    
    func testTransactionListSectionHeader_OneMonthAgo() {
        // Given: 한 달 전 날짜
        let today = Date()
        guard let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: today) else {
            XCTFail("Failed to create one month ago date")
            return
        }
        
        // When: 한 달 전 날짜의 섹션 헤더 생성
        let header = oneMonthAgo.transactionListSectionHeader
        
        // Then: 포맷된 날짜 문자열 반환
        let formatter = formatterManager.transactionDateFormatter
        let expectedHeader = formatter.string(from: oneMonthAgo)
        XCTAssertEqual(header, expectedHeader)
    }
    
    func testTransactionListSectionHeader_SpecificDate() {
        // Given: 특정 날짜 (2025년 7월 15일)
        let components = DateComponents(year: 2025, month: 7, day: 15)
        guard let specificDate = calendar.date(from: components) else {
            XCTFail("Failed to create specific date")
            return
        }
        
        // When: 특정 날짜의 섹션 헤더 생성
        let header = specificDate.transactionListSectionHeader
        
        // Then: 포맷된 날짜 문자열 반환
        let formatter = formatterManager.transactionDateFormatter
        let expectedHeader = formatter.string(from: specificDate)
        XCTAssertEqual(header, expectedHeader)
        
        // 2025년 7월 15일 형식 검증
        XCTAssertTrue(header.contains("2025"))
        XCTAssertTrue(header.contains("07"))
        XCTAssertTrue(header.contains("15"))
    }
    
    func testTransactionListSectionHeader_FutureDate() {
        // Given: 미래 날짜 (내일)
        let today = Date()
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) else {
            XCTFail("Failed to create tomorrow date")
            return
        }
        
        // When: 미래 날짜의 섹션 헤더 생성
        let header = tomorrow.transactionListSectionHeader
        
        // Then: 포맷된 날짜 문자열 반환 (미래 날짜는 상대적 표시 없음)
        let formatter = formatterManager.transactionDateFormatter
        let expectedHeader = formatter.string(from: tomorrow)
        XCTAssertEqual(header, expectedHeader)
    }
    
    func testTransactionListSectionHeader_SameDayDifferentTime() {
        // Given: 같은 날의 다른 시간들
        let today = Date()
        
        let components = calendar.dateComponents([.year, .month, .day], from: today)
        var morningComponents = components
        morningComponents.hour = 8
        morningComponents.minute = 30
        
        var eveningComponents = components
        eveningComponents.hour = 20
        eveningComponents.minute = 45
        
        guard let morningTime = calendar.date(from: morningComponents),
              let eveningTime = calendar.date(from: eveningComponents) else {
            XCTFail("Failed to create different times")
            return
        }
        
        // When: 같은 날의 다른 시간들로 섹션 헤더 생성
        let morningHeader = morningTime.transactionListSectionHeader
        let eveningHeader = eveningTime.transactionListSectionHeader
        
        // Then: 모두 "오늘" 반환
        XCTAssertEqual(morningHeader, "오늘")
        XCTAssertEqual(eveningHeader, "오늘")
    }
    
    func testTransactionListSectionHeader_EdgeCaseFourDaysAgo() {
        // Given: 4일전 날짜 (3일 초과)
        let today = Date()
        guard let fourDaysAgo = calendar.date(byAdding: .day, value: -4, to: today) else {
            XCTFail("Failed to create four days ago date")
            return
        }
        
        // When: 4일전 날짜의 섹션 헤더 생성
        let header = fourDaysAgo.transactionListSectionHeader
        
        // Then: 포맷된 날짜 문자열 반환 ("N일전" 형식이 아님)
        let formatter = formatterManager.transactionDateFormatter
        let expectedHeader = formatter.string(from: fourDaysAgo)
        XCTAssertEqual(header, expectedHeader)
        XCTAssertFalse(header.contains("일전"))
    }
    
    func testTransactionListSectionHeader_KoreanLocaleFormatting() {
        // Given: 한국어 로케일 검증을 위한 특정 날짜
        let components = DateComponents(year: 2025, month: 8, day: 3) // 일요일
        guard let testDate = calendar.date(from: components) else {
            XCTFail("Failed to create test date")
            return
        }
        
        // 오늘과 차이가 일주일 이상인지 확인
        let today = Date()
        let daysDifference = calendar.dateComponents([.day], from: testDate, to: today).day ?? 0
        
        // Given이 일주일 이상 차이나는 경우에만 테스트
        if daysDifference > 3 {
            // When: 한국어 로케일로 포맷된 헤더 생성
            let header = testDate.transactionListSectionHeader
            
            // Then: 한국어 요일 표시 확인
            XCTAssertTrue(header.contains("2025"))
            XCTAssertTrue(header.contains("08"))
            XCTAssertTrue(header.contains("03"))
            XCTAssertTrue(header.contains("("))
            XCTAssertTrue(header.contains(")"))
        }
    }
}
