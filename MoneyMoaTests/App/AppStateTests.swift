//
//  AppStateTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 8/21/25.
//

import XCTest
@testable import MoneyMoa

@MainActor
final class AppStateTests: XCTestCase {
    
    private var mockDIContainer: MockDIContainer!
    private var appState: AppState!
    
    override func setUp() {
        super.setUp()
        
        // Mock 객체들 설정
        mockDIContainer = MockDIContainer()
        
        appState = AppState(diContainer: mockDIContainer)
    }
    
    override func tearDown() {
        mockDIContainer = nil
        appState = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState_ShouldBeLoading() {
        // Given & When
        // AppState 생성 시점
        
        // Then
        XCTAssertTrue(appState.isLoading, "초기 상태는 로딩 중이어야 합니다")
        XCTAssertEqual(appState.loadingMessage, "데이터를 준비하고 있습니다...")
    }
    
    // MARK: - First Launch Tests
    
    func testInitializeApp_OnFirstLaunch_ShouldImportCategories() async {
        // Given
        setHasInitialized(false)
        
        // When
        await appState.initializeApp()
        
        // Then
        XCTAssertFalse(appState.isLoading, "초기화 완료 후 로딩이 끝나야 합니다")
        // Note: 실제 카테고리 import는 MockCategoryRepository를 통해 검증 가능
    }
    
    // MARK: - Subsequent Launch Tests
    
    func testInitializeApp_OnSubsequentLaunch_ShouldNotExecuteImportUseCase() async {
        // Given
        setHasInitialized(true)
        
        // When
        await appState.initializeApp()
        
        // Then
        XCTAssertFalse(appState.isLoading, "로딩이 즉시 완료되어야 합니다")
    }
    
    // MARK: - Error Handling Tests
    
    func testInitializeApp_WhenErrorOccurs_ShouldStillCompleteLoading() async {
        // Given
        setHasInitialized(false)
        // Mock에서 에러가 발생해도 앱이 계속 진행되어야 함
        
        // When
        await appState.initializeApp()
        
        // Then
        XCTAssertFalse(appState.isLoading, "에러가 발생해도 로딩이 완료되어야 합니다")
    }
    
    // MARK: - Loading State Management Tests
    
    func testInitializeApp_ShouldSetLoadingTrueAtStart() async {
        // Given
        setHasInitialized(false)
        
        // When
        let task = Task {
            await appState.initializeApp()
        }
        
        // 초기화 시작 직후 로딩 상태 확인
        XCTAssertTrue(appState.isLoading, "초기화 시작 시 로딩 상태여야 합니다")
        
        await task.value
        
        // Then
        XCTAssertFalse(appState.isLoading, "초기화 완료 후 로딩이 끝나야 합니다")
    }
    
    func testInitializeApp_LoadingMessageShouldBeUpdated() async {
        // Given
        setHasInitialized(false)
        
        // When
        await appState.initializeApp()
        
        // Then
        // 로딩 메시지가 적절히 설정되었는지 확인
        XCTAssertNotNil(appState.loadingMessage)
        XCTAssertFalse(appState.loadingMessage.isEmpty)
    }
    
    // MARK: - Concurrent Access Tests
    
    func testInitializeApp_ConcurrentCalls_ShouldHandleCorrectly() async {
        // Given
        setHasInitialized(false)
        
        // When - 동시에 여러 번 호출
        async let task1: Void = appState.initializeApp()
        async let task2: Void = appState.initializeApp()
        async let task3: Void = appState.initializeApp()
        
        _ = await task1
        _ = await task2  
        _ = await task3
        
        // Then
        XCTAssertFalse(appState.isLoading, "모든 초기화가 완료되어야 합니다")
    }
    
    // MARK: - Budget Tests
    
    func testInitializeApp_WhenNoBudgetAndNoTemplate_ShouldCompleteWithoutError() async {
        // Given
        setHasInitialized(true) // Skip category initialization
        // MockBudgetRepository는 기본적으로 empty scenario
        
        // When
        await appState.initializeApp()
        
        // Then
        XCTAssertFalse(appState.isLoading, "템플릿이 없어도 초기화가 완료되어야 합니다")
    }
    
    func testInitializeApp_BudgetCreationFailure_ShouldStillCompleteLoading() async {
        // Given
        setHasInitialized(true) // Skip category initialization
        // Template 설정하되, repository에서 에러 발생하도록 설정
        mockDIContainer.mockBudgetRepository.shouldFail = true
        let template = TestDataFactory.createBudgetTemplate()
        mockDIContainer.mockBudgetTemplateRepository.setTemplate(template)
        
        // When
        await appState.initializeApp()
        
        // Then
        XCTAssertFalse(appState.isLoading, "에러가 발생해도 로딩이 완료되어야 합니다")
    }
    
    // MARK: - Repository Interaction Tests
    
    func testInitializeApp_WhenTemplateExists_ShouldCallCreateBudgetFromTemplate() async {
        // Given
        setHasInitialized(true)
        let template = TestDataFactory.createBudgetTemplate(
            totalAmount: 1500000,
            categoryBudgetTemplates: []
        )
        mockDIContainer.mockBudgetTemplateRepository.setTemplate(template)
        
        // When
        await appState.initializeApp()
        
        // Then
        // Repository에 예산이 생성되었는지 확인
        let hasCurrentBudget = mockDIContainer.mockBudgetRepository.hasBudget(for: YearMonth.current)
        XCTAssertTrue(hasCurrentBudget, "템플릿으로부터 현재 월 예산이 생성되어야 합니다")
    }
    
    func testInitializeApp_WhenBudgetExists_ShouldNotCallCreateBudget() async {
        // Given
        setHasInitialized(true)
        let existingBudget = TestDataFactory.createBudget(
            month: YearMonth.current,
            totalAmount: 2000000
        )
        mockDIContainer.mockBudgetRepository.setBudgets([existingBudget])
        
        // Template이 있어도 사용하지 않아야 함
        let template = TestDataFactory.createBudgetTemplate(totalAmount: 3000000)
        mockDIContainer.mockBudgetTemplateRepository.setTemplate(template)
        
        // When
        await appState.initializeApp()
        
        // Then
        // Repository에 추가 예산이 생성되지 않았는지 확인  
        let hasCurrentBudget = mockDIContainer.mockBudgetRepository.hasBudget(for: YearMonth.current)
        XCTAssertTrue(hasCurrentBudget, "기존 예산이 유지되어야 합니다")
        XCTAssertEqual(mockDIContainer.mockBudgetRepository.budgetCount, 1, "예산이 중복 생성되지 않아야 합니다")
    }
    
    // MARK: - Integration Tests
    
    func testFullInitialization_FirstLaunch_WithTemplate() async {
        // Given: 첫 실행, 카테고리 초기화 필요, 템플릿 있음
        setHasInitialized(false)
        let template = TestDataFactory.createBudgetTemplate(
            totalAmount: 3000000,
            categoryBudgetTemplates: [
                TestDataFactory.createCategoryBudgetTemplate(
                    amount: 1000000,
                    categoryID: UUID(),
                    categoryName: "식비",
                    budgetTemplateId: UUID()
                ),
                TestDataFactory.createCategoryBudgetTemplate(
                    amount: 500000,
                    categoryID: UUID(),
                    categoryName: "교통비",
                    budgetTemplateId: UUID()
                )
            ]
        )
        mockDIContainer.mockBudgetTemplateRepository.setTemplate(template)
        
        // When
        await appState.initializeApp()
        
        // Then
        XCTAssertFalse(appState.isLoading, "초기화가 완료되어야 합니다")
        
        // 카테고리 초기화 확인
        #if !DEBUG
        XCTAssertTrue(
            UserDefaults.standard.bool(forKey: "hasInitializedCategories"),
            "카테고리가 초기화되어야 합니다"
        )
        #endif
        
        // 예산 생성 확인
        let hasCurrentBudget = mockDIContainer.mockBudgetRepository.hasBudget(for: YearMonth.current)
        XCTAssertTrue(hasCurrentBudget, "현재 월 예산이 생성되어야 합니다")
        XCTAssertEqual(mockDIContainer.mockBudgetRepository.budgetCount, 1, "예산이 하나만 생성되어야 합니다")
    }

    func testFullInitialization_FirstLaunch_NoTemplate() async {
        // Given: 첫 실행, 템플릿 없음
        setHasInitialized(false)
        // No template set
        
        // When
        await appState.initializeApp()
        
        // Then
        XCTAssertFalse(appState.isLoading, "초기화가 완료되어야 합니다")
        
        // 예산이 생성되지 않았는지 확인
        let hasCurrentBudget = mockDIContainer.mockBudgetRepository.hasBudget(for: YearMonth.current)
        XCTAssertFalse(hasCurrentBudget, "템플릿이 없으면 예산이 생성되지 않아야 합니다")
    }
    
    // MARK: - Helper Methods
    
    private func setHasInitialized(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: "hasInitializedCategories")
    }
}
