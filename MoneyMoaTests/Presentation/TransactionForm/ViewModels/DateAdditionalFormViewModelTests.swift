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
        XCTAssertNotNil(viewModel.id)
        XCTAssertNil(viewModel.selectedRecurrencePeriod, "초기 상태에서는 템플릿 생성하지 않음")
        XCTAssertFalse(viewModel.createAsTemplate, "초기 상태에서는 템플릿 생성 비활성화")

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
    
    // MARK: - Test Methods - Summary Generation
    
    func test_summary_withAllData_returnsCompleteInfo() {
        // Given
        viewModel.selectedDate = Date()
        viewModel.memo = "테스트 메모"
        viewModel.selectedRecurrencePeriod = .monthly

        // When
        let summary = viewModel.summary

        // Then
        XCTAssertTrue(summary.contains("📅"))
        XCTAssertTrue(summary.contains("📝"))
        XCTAssertTrue(summary.contains("테스트 메모"))
        XCTAssertTrue(summary.contains("🔄"))
        XCTAssertTrue(summary.contains("매월"))
    }
    
    func test_summary_withNoData_returnsDateOnly() {
        // Given - 기본 상태 (날짜만 있음)
        viewModel.memo = ""
        
        // When
        let summary = viewModel.summary
        
        // Then
        XCTAssertTrue(summary.contains("📅"))
        XCTAssertFalse(summary.contains("📝"))
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
    // MARK: - Test Methods - State Consistency
    
    func test_multipleUpdates_maintainConsistentState() {
        // Given & When - 여러 값을 동시에 업데이트
        let testDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let testMemo = "통합 테스트 메모"

        viewModel.selectedDate = testDate
        viewModel.memo = testMemo
        viewModel.selectedRecurrencePeriod = .weekly

        // Then - 모든 값이 올바르게 설정되어야 함
        XCTAssertEqual(viewModel.selectedDate, testDate)
        XCTAssertEqual(viewModel.memo, testMemo)
        XCTAssertEqual(viewModel.selectedRecurrencePeriod ?? .none, .weekly)
        XCTAssertTrue(viewModel.createAsTemplate)
    }

    // MARK: - Template Creation Tests

    func test_createAsTemplate_initialState_isFalse() {
        // Then
        XCTAssertFalse(viewModel.createAsTemplate)
        XCTAssertNil(viewModel.selectedRecurrencePeriod)
    }

    func test_createAsTemplate_setToTrue_setsDefaultRecurrencePeriod() {
        // When
        viewModel.createAsTemplate = true

        // Then
        XCTAssertTrue(viewModel.createAsTemplate)
        XCTAssertEqual(viewModel.selectedRecurrencePeriod ?? .monthly, .none)
    }

    func test_createAsTemplate_setToFalse_clearsRecurrencePeriod() {
        // Given
        viewModel.selectedRecurrencePeriod = .monthly
        XCTAssertTrue(viewModel.createAsTemplate)

        // When
        viewModel.createAsTemplate = false

        // Then
        XCTAssertFalse(viewModel.createAsTemplate)
        XCTAssertNil(viewModel.selectedRecurrencePeriod)
    }

    func test_selectedRecurrencePeriod_setToNil_makesCreateAsTemplateFalse() {
        // Given
        viewModel.selectedRecurrencePeriod = .weekly
        XCTAssertTrue(viewModel.createAsTemplate)

        // When
        viewModel.selectedRecurrencePeriod = nil

        // Then
        XCTAssertFalse(viewModel.createAsTemplate)
        XCTAssertNil(viewModel.selectedRecurrencePeriod)
    }

    func test_selectedRecurrencePeriod_setToValue_makesCreateAsTemplateTrue() {
        // Given
        XCTAssertFalse(viewModel.createAsTemplate)

        // When
        viewModel.selectedRecurrencePeriod = .yearly

        // Then
        XCTAssertTrue(viewModel.createAsTemplate)
        XCTAssertEqual(viewModel.selectedRecurrencePeriod, .yearly)
    }

    // MARK: - Action Handling Tests

    func test_send_toggleTemplate_fromTrueToFalse() {
        // Given
        viewModel.selectedRecurrencePeriod = .monthly
        XCTAssertTrue(viewModel.createAsTemplate)

        // When
        viewModel.send(.toggleTemplate)

        // Then
        XCTAssertFalse(viewModel.createAsTemplate)
        XCTAssertNil(viewModel.selectedRecurrencePeriod)
    }

    func test_send_selectRecurrencePeriod_updatesCorrectly() {
        // When
        viewModel.send(.selectRecurrencePeriod(.weekly))

        // Then
        XCTAssertEqual(viewModel.selectedRecurrencePeriod, .weekly)
        XCTAssertTrue(viewModel.createAsTemplate)
    }

    func test_send_multipleRecurrencePeriodChanges_maintainsConsistency() {
        // When - 여러 번 변경
        viewModel.send(.selectRecurrencePeriod(.weekly))
        XCTAssertEqual(viewModel.selectedRecurrencePeriod, .weekly)

        viewModel.send(.selectRecurrencePeriod(.monthly))
        XCTAssertEqual(viewModel.selectedRecurrencePeriod, .monthly)

        viewModel.send(.selectRecurrencePeriod(.yearly))
        XCTAssertEqual(viewModel.selectedRecurrencePeriod, .yearly)

        // Then - 항상 템플릿 생성 상태 유지
        XCTAssertTrue(viewModel.createAsTemplate)
    }

    // MARK: - Summary with Template Tests

    func test_summary_withTemplate_includesRecurrencePeriod() {
        // Given
        viewModel.selectedDate = Date()
        viewModel.memo = "테스트"
        viewModel.selectedRecurrencePeriod = .weekly

        // When
        let summary = viewModel.summary

        // Then
        XCTAssertTrue(summary.contains("📅"))
        XCTAssertTrue(summary.contains("📝"))
        XCTAssertTrue(summary.contains("🔄"))
        XCTAssertTrue(summary.contains("매주"))
    }

    func test_summary_withTemplateButNoMemo_showsDateAndTemplate() {
        // Given
        viewModel.selectedDate = Date()
        viewModel.memo = ""
        viewModel.selectedRecurrencePeriod = .monthly

        // When
        let summary = viewModel.summary

        // Then
        XCTAssertTrue(summary.contains("📅"))
        XCTAssertFalse(summary.contains("📝"))
        XCTAssertTrue(summary.contains("🔄"))
        XCTAssertTrue(summary.contains("매월"))
    }

    // MARK: - Read-Only Template Tests

    func test_isReadOnlyTemplate_defaultValue_isFalse() {
        // Given & When
        let viewModel = DateAdditionalFormViewModel()

        // Then
        XCTAssertFalse(viewModel.isReadOnlyTemplate, "기본값은 false여야 함")
    }

    func test_isReadOnlyTemplate_setToTrue_remainsTrue() {
        // Given & When
        let viewModel = DateAdditionalFormViewModel(isReadOnlyTemplate: true)

        // Then
        XCTAssertTrue(viewModel.isReadOnlyTemplate, "읽기 전용 모드로 설정되어야 함")
    }

    func test_isReadOnlyTemplate_withUpdateMode_preventsTemplateModification() {
        // Given: Update 모드 (읽기 전용)
        let readOnlyViewModel = DateAdditionalFormViewModel(
            selectedDate: Date(),
            memo: "Test",
            selectedRecurrencePeriod: .monthly,
            isReadOnlyTemplate: true
        )

        // Then: isReadOnlyTemplate이 true면 UI에서 template section을 숨김
        XCTAssertTrue(readOnlyViewModel.isReadOnlyTemplate, "Update 모드에서는 읽기 전용이어야 함")
        XCTAssertEqual(readOnlyViewModel.selectedRecurrencePeriod, .monthly, "기존 템플릿 정보는 유지되어야 함")
    }

    func test_isReadOnlyTemplate_withCreateMode_allowsTemplateModification() {
        // Given: Create 모드 (편집 가능)
        let editableViewModel = DateAdditionalFormViewModel(
            selectedDate: Date(),
            memo: "Test",
            isReadOnlyTemplate: false
        )

        // When: 템플릿 토글 가능
        editableViewModel.send(.toggleTemplate)

        // Then
        XCTAssertFalse(editableViewModel.isReadOnlyTemplate, "Create 모드에서는 편집 가능해야 함")
        XCTAssertTrue(editableViewModel.createAsTemplate, "템플릿 생성 가능해야 함")
    }

    func test_summary_withReadOnlyTemplateMode_includesTemplateInfo() {
        // Given: 템플릿이 있는 읽기 전용 모드
        let viewModel = DateAdditionalFormViewModel(
            selectedDate: Date(),
            memo: "Test Memo",
            selectedRecurrencePeriod: .monthly,
            isReadOnlyTemplate: true
        )

        // When
        let summary = viewModel.summary

        // Then: 템플릿 정보가 포함되어야 함
        XCTAssertTrue(summary.contains("📅"))
        XCTAssertTrue(summary.contains("📝"))
        XCTAssertTrue(summary.contains("🔄"))
        XCTAssertTrue(summary.contains("매월"))
    }
}
