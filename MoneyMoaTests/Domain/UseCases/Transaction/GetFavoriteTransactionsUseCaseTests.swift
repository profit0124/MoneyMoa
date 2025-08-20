//
//  GetFavoriteTransactionsUseCaseTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 8/19/25.
//

import XCTest
@testable import MoneyMoa

// MARK: - MockGetFavoriteTransactionsUseCaseTests

final class MockGetFavoriteTransactionsUseCaseTests: XCTestCase {
    
    // MARK: - Properties
    
    private var mockUseCase: MockGetFavoriteTransactionsUseCase!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockUseCase = MockGetFavoriteTransactionsUseCase()
    }
    
    override func tearDown() {
        mockUseCase = nil
        super.tearDown()
    }
    
    // MARK: - Test Methods - Successful Execution
    
    func test_execute_withDefaultConfiguration_returnsFavoriteTransactions() async throws {
        // When
        let favoriteTransactions = try await mockUseCase.execute()
        
        // Then
        XCTAssertEqual(favoriteTransactions.count, 2)
        
        // First transaction
        let firstTransaction = favoriteTransactions[0]
        XCTAssertEqual(firstTransaction.amount, 15000)
        XCTAssertEqual(firstTransaction.place, "맥도날드")
        XCTAssertEqual(firstTransaction.memo, "점심식사")
        XCTAssertEqual(firstTransaction.transactionType, .variableExpense)
        XCTAssertTrue(firstTransaction.isFavorite)
        XCTAssertEqual(firstTransaction.subCategory, .mockFoodExpense)
        XCTAssertEqual(firstTransaction.paymentMethod, .mockCreditCard)
        
        // Second transaction
        let secondTransaction = favoriteTransactions[1]
        XCTAssertEqual(secondTransaction.amount, 50000)
        XCTAssertEqual(secondTransaction.place, "부모님")
        XCTAssertEqual(secondTransaction.memo, "용돈")
        XCTAssertEqual(secondTransaction.transactionType, .income)
        XCTAssertTrue(secondTransaction.isFavorite)
        XCTAssertEqual(secondTransaction.subCategory, .mockIncomeAllowance)
        XCTAssertEqual(secondTransaction.paymentMethod, .mockCash)
    }
    
    func test_execute_returnsOnlyFavoriteTransactions() async throws {
        // When
        let favoriteTransactions = try await mockUseCase.execute()
        
        // Then - 모든 반환된 거래가 즐겨찾기로 설정되어야 함
        XCTAssertTrue(favoriteTransactions.allSatisfy { $0.isFavorite })
    }
    
    func test_execute_returnsVariousTransactionTypes() async throws {
        // When
        let favoriteTransactions = try await mockUseCase.execute()
        
        // Then - 다양한 거래 타입이 포함되어야 함
        let transactionTypes = Set(favoriteTransactions.map { $0.transactionType })
        XCTAssertTrue(transactionTypes.contains(.variableExpense))
        XCTAssertTrue(transactionTypes.contains(.income))
    }
    
    func test_execute_returnsDifferentPaymentMethods() async throws {
        // When
        let favoriteTransactions = try await mockUseCase.execute()
        
        // Then - 다양한 결제 수단이 포함되어야 함
        let paymentMethods = favoriteTransactions.map { $0.paymentMethod }
        XCTAssertTrue(paymentMethods.contains(.mockCreditCard))
        XCTAssertTrue(paymentMethods.contains(.mockCash))
    }
    
    // MARK: - Test Methods - Error Cases
    
    func test_execute_withFailureConfiguration_throwsError() async {
        // Given
        mockUseCase.shouldFail = true
        
        // When & Then
        do {
            _ = try await mockUseCase.execute()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - Test Methods - Configuration
    
    func test_shouldFail_defaultsToFalse() {
        // Then
        XCTAssertFalse(mockUseCase.shouldFail)
    }
    
    func test_shouldFail_canBeSetToTrue() {
        // When
        mockUseCase.shouldFail = true
        
        // Then
        XCTAssertTrue(mockUseCase.shouldFail)
    }
    
    // MARK: - Test Methods - Data Consistency
    
    func test_execute_multipleCallsReturnConsistentData() async throws {
        // When
        let firstCall = try await mockUseCase.execute()
        let secondCall = try await mockUseCase.execute()
        
        // Then - 여러 번 호출해도 동일한 데이터 반환
        XCTAssertEqual(firstCall.count, secondCall.count)
        XCTAssertEqual(firstCall[0].amount, secondCall[0].amount)
        XCTAssertEqual(firstCall[1].amount, secondCall[1].amount)
    }
    
    func test_execute_afterFailureConfiguration_stillThrowsError() async {
        // Given
        mockUseCase.shouldFail = true
        
        // When & Then - 첫 번째 호출
        do {
            _ = try await mockUseCase.execute()
            XCTFail("Expected error to be thrown")
        } catch {
            // 예상된 에러
        }
        
        // When & Then - 두 번째 호출도 여전히 에러 발생
        do {
            _ = try await mockUseCase.execute()
            XCTFail("Expected error to be thrown")
        } catch {
            // 예상된 에러
        }
    }
    
    func test_execute_afterResettingFailureFlag_succeeds() async throws {
        // Given
        mockUseCase.shouldFail = true
        
        // 실패 상태에서 에러 확인
        do {
            _ = try await mockUseCase.execute()
            XCTFail("Expected error to be thrown")
        } catch {
            // 예상된 에러
        }
        
        // When - 실패 플래그 리셋
        mockUseCase.shouldFail = false
        
        // Then - 성공적으로 실행
        let favoriteTransactions = try await mockUseCase.execute()
        XCTAssertEqual(favoriteTransactions.count, 2)
    }
}
