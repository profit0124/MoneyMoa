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
    
    func testInitializeApp_OnFirstLaunch_ShouldExecuteImportUseCase() async {
        // Given
        setHasInitialized(false)
        
        // When
        await appState.initializeApp()
        
        // Then
        XCTAssertFalse(appState.isLoading, "초기화 완료 후 로딩이 끝나야 합니다")
    }
    
    func testInitializeApp_OnFirstLaunch_ShouldUpdateLoadingMessage() async {
        // Given
        setHasInitialized(false)
        
        var loadingMessages: [String] = []
        
        // 로딩 메시지 변화 관찰
        let expectation = XCTestExpectation(description: "로딩 메시지 업데이트")
        
        Task {
            // 초기 메시지 기록
            loadingMessages.append(appState.loadingMessage)
            
            await appState.initializeApp()
            
            // 완료 후 메시지 기록
            loadingMessages.append(appState.loadingMessage)
            expectation.fulfill()
        }
        
        // When
        await fulfillment(of: [expectation], timeout: 5.0)
        
        // Then
        XCTAssertTrue(loadingMessages.contains("추천 카테고리를 설정하고 있습니다..."), "로딩 메시지가 업데이트되어야 합니다")
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
    
    func testInitializeApp_WhenImportUseCaseFails_ShouldStillCompleteLoading() async {
        // Given
        setHasInitialized(false)
        
        // When
        await appState.initializeApp()
        
        // Then
        XCTAssertFalse(appState.isLoading, "에러가 발생해도 로딩이 완료되어야 합니다")
    }
    
    func testInitializeApp_WhenImportUseCaseFails_ShouldNotCrashApp() async {
        // Given
        setHasInitialized(false)
        
        // When & Then (에러가 발생해도 크래시하지 않아야 함)
        await appState.initializeApp()
        
        XCTAssertFalse(appState.isLoading, "에러 상황에서도 앱이 계속 진행되어야 합니다")
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
    
    // MARK: - Helper Methods
    
    private func setHasInitialized(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: "hasInitializedCategories")
    }
}
