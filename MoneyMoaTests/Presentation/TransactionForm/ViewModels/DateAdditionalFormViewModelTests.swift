//
//  DateAdditionalFormViewModelTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 8/19/25.
//

import XCTest
@testable import MoneyMoa

// MARK: - DateAdditionalFormViewModelTests

@MainActor
final class DateAdditionalFormViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var viewModel: DateAdditionalFormViewModel!
    private var mockContainer: MockDIContainer!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        
        mockContainer = MockDIContainer()
        viewModel = mockContainer.makeDateAdditionalFormViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        mockContainer = nil
        super.tearDown()
    }
    
    // MARK: - Test Methods - Initialization
    
    func test_initialization_setsCorrectInitialValues() {
        // Then
        XCTAssertEqual(viewModel.memo, "")
        XCTAssertFalse(viewModel.isFavorite)
        XCTAssertNotNil(viewModel.id)
        
        // selectedDate는 현재 날짜와 거의 같아야 함 (몇 초 차이 허용)
        let currentDate = Date()
        let timeDifference = abs(viewModel.selectedDate.timeIntervalSince(currentDate))
        XCTAssertLessThan(timeDifference, 5.0, "Selected date should be close to current date")
    }
    
    // MARK: - Test Methods - Property Updates
    
    func test_selectedDate_canBeUpdated() {
        // Given
        let testDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        
        // When
        viewModel.selectedDate = testDate
        
        // Then
        XCTAssertEqual(viewModel.selectedDate, testDate)
    }
    
    func test_memo_canBeUpdated() {
        // Given
        let testMemo = "점심식사 - 맥도날드"
        
        // When
        viewModel.memo = testMemo
        
        // Then
        XCTAssertEqual(viewModel.memo, testMemo)
    }
    
    func test_isFavorite_canBeToggled() {
        // Given
        let initialFavoriteState = viewModel.isFavorite
        
        // When
        viewModel.isFavorite = !initialFavoriteState
        
        // Then
        XCTAssertNotEqual(viewModel.isFavorite, initialFavoriteState)
        XCTAssertEqual(viewModel.isFavorite, !initialFavoriteState)
        
        // When - 다시 토글
        viewModel.isFavorite = initialFavoriteState
        
        // Then - 원래 상태로 돌아와야 함
        XCTAssertEqual(viewModel.isFavorite, initialFavoriteState)
    }
    
    func test_isFavorite_canBeSetToTrue() {
        // Given
        viewModel.isFavorite = false
        
        // When
        viewModel.isFavorite = true
        
        // Then
        XCTAssertTrue(viewModel.isFavorite)
    }
    
    func test_isFavorite_canBeSetToFalse() {
        // Given
        viewModel.isFavorite = true
        
        // When
        viewModel.isFavorite = false
        
        // Then
        XCTAssertFalse(viewModel.isFavorite)
    }
    
    // MARK: - Test Methods - Summary Generation
    
    func test_summary_withAllData_returnsCompleteInfo() {
        // Given
        viewModel.selectedDate = Date()
        viewModel.memo = "테스트 메모"
        viewModel.isFavorite = true
        
        // When
        let summary = viewModel.summary
        
        // Then
        XCTAssertTrue(summary.contains("📅"))
        XCTAssertTrue(summary.contains("📝"))
        XCTAssertTrue(summary.contains("⭐"))
        XCTAssertTrue(summary.contains("테스트 메모"))
    }
    
    func test_summary_withNoData_returnsDateOnly() {
        // Given - 기본 상태 (날짜만 있음)
        viewModel.memo = ""
        viewModel.isFavorite = false
        
        // When
        let summary = viewModel.summary
        
        // Then
        XCTAssertTrue(summary.contains("📅"))
        XCTAssertFalse(summary.contains("📝"))
        XCTAssertFalse(summary.contains("⭐"))
    }
    
    // MARK: - Test Methods - Date Handling
    
    func test_selectedDate_canBeSetToFutureDate() {
        // Given
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        
        // When
        viewModel.selectedDate = futureDate
        
        // Then
        XCTAssertEqual(viewModel.selectedDate, futureDate)
    }
    
    func test_selectedDate_canBeSetToPastDate() {
        // Given
        let pastDate = Calendar.current.date(byAdding: .month, value: -2, to: Date())!
        
        // When
        viewModel.selectedDate = pastDate
        
        // Then
        XCTAssertEqual(viewModel.selectedDate, pastDate)
    }
    
    func test_selectedDate_maintainsPrecision() {
        // Given
        let specificDate = DateComponents(
            calendar: Calendar.current,
            year: 2024,
            month: 8,
            day: 15,
            hour: 14,
            minute: 30,
            second: 45
        ).date!
        
        // When
        viewModel.selectedDate = specificDate
        
        // Then
        XCTAssertEqual(viewModel.selectedDate, specificDate)
    }
    
    // MARK: - Test Methods - Memo Handling
    
    func test_memo_canHandleEmptyString() {
        // Given
        let emptyMemo = ""
        
        // When
        viewModel.memo = emptyMemo
        
        // Then
        XCTAssertEqual(viewModel.memo, emptyMemo)
        XCTAssertTrue(viewModel.memo.isEmpty)
    }
    
    func test_memo_canHandleLongText() {
        // Given
        let longMemo = String(repeating: "이것은 긴 메모입니다. ", count: 20)
        
        // When
        viewModel.memo = longMemo
        
        // Then
        XCTAssertEqual(viewModel.memo, longMemo)
    }
    
    func test_memo_canHandleSpecialCharacters() {
        // Given
        let specialMemo = "특수문자 테스트: !@#$%^&*()_+{}[]|;':\"<>?,./"
        
        // When
        viewModel.memo = specialMemo
        
        // Then
        XCTAssertEqual(viewModel.memo, specialMemo)
    }
    
    func test_memo_canHandleUnicode() {
        // Given
        let unicodeMemo = "유니코드 테스트: 🍕🎉💰📱"
        
        // When
        viewModel.memo = unicodeMemo
        
        // Then
        XCTAssertEqual(viewModel.memo, unicodeMemo)
    }
    
    // MARK: - Test Methods - Observable Pattern
    
    func test_selectedDateUpdate_triggersPropertyChange() {
        // Given
        let initialDate = viewModel.selectedDate
        let newDate = Calendar.current.date(byAdding: .day, value: 1, to: initialDate)!
        
        // When
        viewModel.selectedDate = newDate
        
        // Then
        XCTAssertNotEqual(viewModel.selectedDate, initialDate)
        XCTAssertEqual(viewModel.selectedDate, newDate)
    }
    
    func test_memoUpdate_triggersPropertyChange() {
        // Given
        let initialMemo = viewModel.memo
        let newMemo = "새로운 메모"
        
        // When
        viewModel.memo = newMemo
        
        // Then
        XCTAssertNotEqual(viewModel.memo, initialMemo)
        XCTAssertEqual(viewModel.memo, newMemo)
    }
    
    func test_favoriteToggle_triggersPropertyChange() {
        // Given
        let initialFavorite = viewModel.isFavorite
        
        // When
        viewModel.isFavorite = !initialFavorite
        
        // Then
        XCTAssertNotEqual(viewModel.isFavorite, initialFavorite)
        XCTAssertEqual(viewModel.isFavorite, !initialFavorite)
    }
    
    // MARK: - Test Methods - State Consistency
    
    func test_multipleUpdates_maintainConsistentState() {
        // Given & When - 여러 값을 동시에 업데이트
        let testDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let testMemo = "통합 테스트 메모"
        let testFavorite = true
        
        viewModel.selectedDate = testDate
        viewModel.memo = testMemo
        viewModel.isFavorite = testFavorite
        
        // Then - 모든 값이 올바르게 설정되어야 함
        XCTAssertEqual(viewModel.selectedDate, testDate)
        XCTAssertEqual(viewModel.memo, testMemo)
        XCTAssertEqual(viewModel.isFavorite, testFavorite)
    }
}
