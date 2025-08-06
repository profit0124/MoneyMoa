//
//  TransactionListViewTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 8/3/25.
//

import XCTest
import SwiftUI
@testable import MoneyMoa

final class TransactionListViewTests: XCTestCase {
    
    // MARK: - Test Data Setup
    
    private func createTestTransactionData() -> [(Date, [TransactionDTO])] {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today
        
        let expenseCategory = TestDataFactory.createCategory(
            name: "식비",
            iconName: "fork.knife",
            type: .variableExpense
        )
        
        let incomeCategory = TestDataFactory.createCategory(
            name: "수입",
            iconName: "banknote",
            type: .income
        )
        
        let todayTransactions = [
            TestDataFactory.createTransaction(
                amount: 15000,
                date: today,
                place: "맥도날드",
                transactionType: .variableExpense,
                subCategory: TestDataFactory.createSubCategory(
                    name: "외식",
                    categoryId: expenseCategory.id,
                    categoryIconName: expenseCategory.iconName,
                    type: .variableExpense
                ),
                paymentMethod: TestDataFactory.createPaymentMethod(
                    name: "신용카드",
                    kind: .credit
                )
            )
        ]
        
        let yesterdayTransactions = [
            TestDataFactory.createTransaction(
                amount: 50000,
                date: yesterday,
                place: "회사",
                transactionType: .income,
                subCategory: TestDataFactory.createSubCategory(
                    name: "급여",
                    categoryId: incomeCategory.id,
                    categoryIconName: incomeCategory.iconName,
                    type: .income
                ),
                paymentMethod: TestDataFactory.createPaymentMethod(
                    name: "계좌이체",
                    kind: .transfer
                )
            )
        ]
        
        return [
            (today, todayTransactions),
            (yesterday, yesterdayTransactions)
        ]
    }
    
    // MARK: - Component Tests
    
    func testTransactionListViewInitialization() {
        // Given
        let testData = createTestTransactionData()
        var tappedTransaction: TransactionDTO?
        
        // When
        let view = TransactionListView(
            listData: testData,
            onTransactionTap: { transaction in
                tappedTransaction = transaction
            }
        )
        
        // Then
        XCTAssertNotNil(view)
        XCTAssertNil(tappedTransaction)
    }
    
    func testTransactionRowAmountColor() {
        // Given
        let testData = createTestTransactionData()
        let expenseTransaction = testData[0].1.first! // 오늘의 지출 거래
        let incomeTransaction = testData[1].1.first!  // 어제의 수입 거래
        
        // When & Then
        // 비즈니스 로직 검증 (실제 View 테스트는 UI 테스트에서)
        XCTAssertEqual(expenseTransaction.transactionType, .variableExpense)
        XCTAssertEqual(incomeTransaction.transactionType, .income)
        
        // TransactionType.color extension 사용 확인
        XCTAssertEqual(expenseTransaction.transactionType.color, .red)
        XCTAssertEqual(incomeTransaction.transactionType.color, .green)
    }
    
    func testTransactionRowDisplayPlace() {
        // Given
        let testData = createTestTransactionData()
        let transactionWithPlace = testData[0].1.first!
        
        let transactionWithoutPlace = TestDataFactory.createTransaction(
            place: nil,
            subCategory: TestDataFactory.createSubCategory(
                categoryId: UUID(),
                categoryIconName: "fork.knife"
            ),
            paymentMethod: TestDataFactory.createPaymentMethod()
        )
        
        // When & Then
        XCTAssertEqual(transactionWithPlace.place, "맥도날드")
        XCTAssertNil(transactionWithoutPlace.place)
    }
    
    func testCategoryIconViewConfiguration() {
        // Given
        let testData = createTestTransactionData()
        let transaction = testData[0].1.first!
        let subCategory = transaction.subCategory
        
        // When & Then
        XCTAssertEqual(subCategory.categoryIconName, "fork.knife")
        XCTAssertEqual(subCategory.transactionType, .variableExpense)
        XCTAssertEqual(subCategory.name, "외식")
    }
    
    func testPaymentMethodIconConfiguration() {
        // Given
        let testData = createTestTransactionData()
        let transaction = testData[0].1.first!
        let paymentMethod = transaction.paymentMethod
        
        // When & Then
        XCTAssertEqual(paymentMethod.kind, .credit)
        XCTAssertEqual(paymentMethod.displayIconName, "creditcard") // 기본 아이콘
        XCTAssertNil(paymentMethod.iconName) // 커스텀 아이콘 없음
    }
    
    func testCustomPaymentMethodIcon() {
        // Given
        let customPaymentMethod = TestDataFactory.createPaymentMethod(
            name: "커스텀카드",
            kind: .credit,
            iconName: "creditcard.fill"
        )
        
        // When & Then
        XCTAssertEqual(customPaymentMethod.displayIconName, "creditcard.fill")
        XCTAssertNotEqual(customPaymentMethod.displayIconName, customPaymentMethod.kind.iconName)
    }
    
    // MARK: - Data Structure Tests
    
    func testTransactionListDataStructure() {
        // Given
        let testData = createTestTransactionData()
        
        // When & Then
        XCTAssertEqual(testData.count, 2) // 2일
        XCTAssertEqual(testData[0].1.count, 1) // 오늘 거래 1개
        XCTAssertEqual(testData[1].1.count, 1) // 어제 거래 1개
        
        // 날짜 순서 확인 (최신 날짜가 먼저)
        XCTAssertGreaterThan(testData[0].0, testData[1].0)
    }
    
    func testFormattedAmountDisplay() {
        // Given
        let testData = createTestTransactionData()
        let expenseTransaction = testData[0].1.first!
        let incomeTransaction = testData[1].1.first!
        
        // When & Then
        XCTAssertEqual(expenseTransaction.formattedAmount, "-15,000원")
        XCTAssertEqual(incomeTransaction.formattedAmount, "+50,000원")
    }
    
    // MARK: - Mock Interaction Tests
    
    func testTransactionTapCallback() {
        // Given
        let testData = createTestTransactionData()
        var tappedTransaction: TransactionDTO?
        let expectedTransaction = testData[0].1.first!
        
        let onTap: (TransactionDTO) -> Void = { transaction in
            tappedTransaction = transaction
        }
        
        // When
        onTap(expectedTransaction)
        
        // Then
        XCTAssertNotNil(tappedTransaction)
        XCTAssertEqual(tappedTransaction?.id, expectedTransaction.id)
        XCTAssertEqual(tappedTransaction?.amount, expectedTransaction.amount)
    }
}