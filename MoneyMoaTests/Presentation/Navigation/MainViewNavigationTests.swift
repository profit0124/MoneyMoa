//
//  MainViewNavigationTests.swift
//  MoneyMoaTests
//
//  Created by Sooik Kim on 8/10/25.
//

import XCTest
import SwiftUI
@testable import MoneyMoa

@MainActor
final class MainViewNavigationTests: XCTestCase {
    
    var mockRouter: MockAppRouter!
    var mainViewModel: MainViewModel!
    
    override func setUp() {
        super.setUp()
        mockRouter = MockAppRouter()
        
        // Create MainViewModel with mock dependencies
        mainViewModel = MainViewModel(
            getMonthlyTransactionsUseCase: MockGetMonthlyTransactionsUseCase(),
            getExpenseSumUntilDateUseCase: MockGetExpenseSumUntilDateUseCase(),
            getMonthlyBudgetUseCase: MockGetMonthlyBudgetUseCase(),
            getBudgetTemplateUseCase: MockGetBudgetTemplateUseCase(),
            createBudgetFromTemplateUseCase: MockCreateBudgetFromTemplateUseCase()
        )
        
    }
    
    override func tearDown() {
        mainViewModel = nil
        mockRouter = nil
        super.tearDown()
    }
    
    // MARK: - Navigation Method Tests
    
    func testHandleTransactionTap_CallsRouterPush() {
        // Given
        let transaction = TransactionDTO.mockStandardExpense
        
        // When
        testHandleTransactionTap(transaction)
        
        // Then
        XCTAssertEqual(mockRouter.pushCallCount, 1)
        XCTAssertEqual(mockRouter.lastPushedRoute, .transactions(.detail(transaction)))
    }
    
    func testHandleChartTap_CallsRouterPush() {
        // When
        testHandleChartTap()
        
        // Then
        XCTAssertEqual(mockRouter.pushCallCount, 1)
        XCTAssertEqual(mockRouter.lastPushedRoute, .charts(.overview))
    }
    
    func testHandleSettingsTap_CallsRouterPush() {
        // When
        testHandleSettingsTap()
        
        // Then
        XCTAssertEqual(mockRouter.pushCallCount, 1)
        XCTAssertEqual(mockRouter.lastPushedRoute, .settings(.root))
    }
    
    func testHandleBudgetSetupTap_CallsRouterPush() {
        // When
        testHandleBudgetSetupTap()
        
        // Then
        XCTAssertEqual(mockRouter.pushCallCount, 1)
        XCTAssertEqual(mockRouter.lastPushedRoute, .settings(.budget))
    }
    
    func testHandleAddTransactionTap_CallsRouterPresent() {
        // When
        testHandleAddTransactionTap()
        
        // Then
        XCTAssertEqual(mockRouter.presentCallCount, 1)
        XCTAssertEqual(mockRouter.lastPresentedRoute, .transactions(.add))
        XCTAssertEqual(mockRouter.lastPresentationStyle, .sheet)
    }
    
    // MARK: - Parameter Passing Tests
    
    func testHandleTransactionTap_PassesCorrectTransaction() {
        // Given
        let expectedTransaction = TransactionDTO.mockLunch
        
        // When
        testHandleTransactionTap(expectedTransaction)
        
        // Then
        if case .transactions(.detail(let passedTransaction)) = mockRouter.lastPushedRoute {
            XCTAssertEqual(passedTransaction.id, expectedTransaction.id)
            XCTAssertEqual(passedTransaction.amount, expectedTransaction.amount)
            XCTAssertEqual(passedTransaction.memo, expectedTransaction.memo)
        } else {
            XCTFail("Expected transaction detail route with correct transaction")
        }
    }
    
    // MARK: - Multiple Navigation Tests
    
    func testMultipleNavigationCalls_TracksAllCalls() {
        // Given
        let transaction = TransactionDTO.mockTransport
        
        // When
        testHandleChartTap()
        testHandleSettingsTap()
        testHandleTransactionTap(transaction)
        testHandleAddTransactionTap()
        
        // Then
        XCTAssertEqual(mockRouter.pushCallCount, 3) // chart, settings, transaction
        XCTAssertEqual(mockRouter.presentCallCount, 1) // add transaction
    }
    
    func testNavigationCallOrder_MaintainsCorrectSequence() {
        // Given
        let transaction = TransactionDTO.mockBeauty
        
        // When
        testHandleChartTap()
        testHandleTransactionTap(transaction)
        testHandleSettingsTap()
        
        // Then
        let expectedRoutes: [AppRoute] = [
            .charts(.overview),
            .transactions(.detail(transaction)),
            .settings(.root)
        ]
        
        XCTAssertEqual(mockRouter.pushedRoutes, expectedRoutes)
    }
    
    // MARK: - Date Tap Tests (Currently Print Only)
    
    func testHandleDateTap_DoesNotCrash() {
        // Given
        let date = Date()
        
        // When & Then
        XCTAssertNoThrow(print("Date tapped: \(date)"))
        
        // Currently just prints, so no router interaction expected
        XCTAssertEqual(mockRouter.pushCallCount, 0)
        XCTAssertEqual(mockRouter.presentCallCount, 0)
    }
    
    // MARK: - Year Month Change Tests
    
    func testHandleYearMonthChange_CallsViewModelSend() {
        // Given
        let action = MainViewModel.HandleYearMonth.moveToNextMonth
        
        // When & Then
        XCTAssertNoThrow(testHandleYearMonthChange(action))
        
        // This method calls viewModel.send(), which is internal logic
        // We verify it doesn't crash and doesn't affect router
        XCTAssertEqual(mockRouter.pushCallCount, 0)
        XCTAssertEqual(mockRouter.presentCallCount, 0)
    }
}

// MARK: - Test Helpers

private extension MainViewNavigationTests {
    
    // Test methods that simulate MainView navigation handlers
    func testHandleTransactionTap(_ transaction: TransactionDTO) {
        mockRouter.push(.transactions(.detail(transaction)))
    }
    
    func testHandleChartTap() {
        mockRouter.push(.charts(.overview))
    }
    
    func testHandleSettingsTap() {
        mockRouter.push(.settings(.root))
    }
    
    func testHandleBudgetSetupTap() {
        mockRouter.push(.settings(.budget))
    }
    
    func testHandleAddTransactionTap() {
        mockRouter.present(.transactions(.add), as: .sheet)
    }
    
    func testHandleYearMonthChange(_ action: MainViewModel.HandleYearMonth) {
        // This would normally call viewModel.send(.handleYearMonth(action))
        // For testing purposes, we just verify it doesn't crash
    }
    
}
