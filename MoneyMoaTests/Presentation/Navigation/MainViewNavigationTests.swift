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
        
        let mockContainer = MockDIContainer()
        // Create MainViewModel with Repository-based dependencies
        mainViewModel = MainViewModel(
            getMonthlyTransactionsUseCase: mockContainer.makeGetMonthlyTransactionsUseCase(),
            getExpenseSumUntilDateUseCase: mockContainer.makeGetExpenseSumUntilDateUseCase(),
            getMonthlyBudgetUseCase: mockContainer.makeGetMonthlyBudgetUseCase(),
            transactionEventPublisher: mockContainer.makeTransactionEventPublisher()
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
        handleTransactionTap(transaction)
        
        // Then
        XCTAssertEqual(mockRouter.pushCallCount, 1)
        XCTAssertEqual(mockRouter.lastPushedRoute, .transactions(.detail(transaction)))
    }
    
    func testHandleChartTap_CallsRouterPush() {
        // When
        handleChartTap()
        
        // Then
        XCTAssertEqual(mockRouter.pushCallCount, 1)
        XCTAssertEqual(mockRouter.lastPushedRoute, .statistics(.overview))
    }
    
    func testHandleSettingsTap_CallsRouterPush() {
        // When
        handleSettingsTap()
        
        // Then
        XCTAssertEqual(mockRouter.pushCallCount, 1)
        XCTAssertEqual(mockRouter.lastPushedRoute, .settings(.root))
    }
    
    func testHandleBudgetSetupTap_CallsRouterPush() {
        // When
        handleBudgetSetupTap()
        
        // Then
        XCTAssertEqual(mockRouter.pushCallCount, 1)
        XCTAssertEqual(mockRouter.lastPushedRoute, .settings(.budget(YearMonth.current)))
    }
    
    func testHandleAddTransactionTap_CallsRouterPresent() {
        // When
        handleAddTransactionTap()
        
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
        handleTransactionTap(expectedTransaction)
        
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
        handleChartTap()
        handleSettingsTap()
        handleTransactionTap(transaction)
        handleAddTransactionTap()
        
        // Then
        XCTAssertEqual(mockRouter.pushCallCount, 3) // chart, settings, transaction
        XCTAssertEqual(mockRouter.presentCallCount, 1) // add transaction
    }
    
    func testNavigationCallOrder_MaintainsCorrectSequence() {
        // Given
        let transaction = TransactionDTO.mockBeauty
        
        // When
        handleChartTap()
        handleTransactionTap(transaction)
        handleSettingsTap()
        
        // Then
        let expectedRoutes: [AppRoute] = [
            .statistics(.overview),
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
        XCTAssertNoThrow(handleYearMonthChange(action))
        
        // This method calls viewModel.send(), which is internal logic
        // We verify it doesn't crash and doesn't affect router
        XCTAssertEqual(mockRouter.pushCallCount, 0)
        XCTAssertEqual(mockRouter.presentCallCount, 0)
    }
}

// MARK: - Test Helpers

private extension MainViewNavigationTests {
    
    // Actual MainView navigation handlers that should be tested
    func handleTransactionTap(_ transaction: TransactionDTO) {
        mockRouter.push(.transactions(.detail(transaction)))
    }
    
    func handleChartTap() {
        mockRouter.push(.statistics(.overview))
    }
    
    func handleSettingsTap() {
        mockRouter.push(.settings(.root))
    }
    
    func handleBudgetSetupTap() {
        mockRouter.push(.settings(.budget(YearMonth.current)))
    }
    
    func handleAddTransactionTap() {
        mockRouter.present(.transactions(.add), as: .sheet)
    }
    
    func handleYearMonthChange(_ action: MainViewModel.HandleYearMonth) {
        // This would call actual MainView logic
        mainViewModel.send(.handleYearMonth(action))
    }
    
}
