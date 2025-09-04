//
//  TransactionFactoryTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 9/3/25.
//

import XCTest
@testable import MoneyMoa

// MARK: - TransactionFactoryTests

final class TransactionFactoryTests: XCTestCase {
    
    // MARK: - Basic Builder Tests
    
    func test_basicBuilders() {
        // Test sample()
        let sample = TransactionFactory.sample()
        XCTAssertEqual(sample.amount, 50000)
        XCTAssertEqual(sample.place, "Sample Place")
        XCTAssertEqual(sample.transactionType, .variableExpense)
        
        // Test create with custom parameters
        let custom = TransactionFactory.create(
            amount: 75000,
            place: "테스트장소",
            transactionType: .income,
            isFavorite: true,
            subCategory: SubCategoryDTO.mockSalary,
            paymentMethod: PaymentMethodDTO.mockTransfer
        )
        XCTAssertEqual(custom.amount, 75000)
        XCTAssertEqual(custom.place, "테스트장소")
        XCTAssertTrue(custom.isFavorite)
        
        // Test create with defaults
        let defaulted = TransactionFactory.create(
            amount: 30000,
            transactionType: .variableExpense,
            subCategory: SubCategoryDTO.mockFoodExpense,
            paymentMethod: PaymentMethodDTO.mockCash
        )
        XCTAssertEqual(defaulted.amount, 30000)
        XCTAssertNil(defaulted.place)
        XCTAssertFalse(defaulted.isFavorite)
    }
    
    // MARK: - Random Generation Tests
    
    func test_randomGeneration() {
        // Test basic random creation
        let transaction = TransactionFactory.createRandom()
        assertValidTransaction(transaction)
        
        // Test with specific date
        let specificDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let dated = TransactionFactory.createRandom(date: specificDate)
        XCTAssertEqual(dated.date, specificDate)
        
        // Test diversity in 20 transactions
        let transactions = (0..<20).map { _ in TransactionFactory.createRandom() }
        let uniqueAmounts = Set(transactions.map { $0.amount })
        XCTAssertGreaterThan(uniqueAmounts.count, 5, "Should generate varied amounts")
        
        // Test favorite distribution in 100 transactions
        let manyTransactions = (0..<100).map { _ in TransactionFactory.createRandom() }
        let favoriteRatio = Double(manyTransactions.filter { $0.isFavorite }.count) / 100.0
        XCTAssertLessThan(favoriteRatio, 0.2)
        XCTAssertGreaterThan(favoriteRatio, 0.0)
    }
    
    // MARK: - Bulk Generation Tests
    
    func test_bulkGeneration() {
        // Test basic count
        let set25 = TransactionFactory.randomSet(count: 25)
        XCTAssertEqual(set25.count, 25)
        set25.forEach { assertValidTransaction($0) }
        
        // Test with context
        let yearMonth = YearMonth(from: Calendar.current.date(from: DateComponents(year: 2024, month: 3))!)
        let contextSet = TransactionFactory.randomSet(count: 10, context: yearMonth)
        XCTAssertEqual(contextSet.count, 10)
        contextSet.forEach {
            let components = Calendar.current.dateComponents([.year, .month], from: $0.date)
            XCTAssertEqual(components.year, 2024)
            XCTAssertEqual(components.month, 3)
        }
        
        // Test diversity
        let diverse = TransactionFactory.randomSet(count: 50)
        assertDataDiversity(transactions: diverse)
    }
    
    // MARK: - Realistic Data Generation Tests
    
    func test_realisticData() {
        let transactions = TransactionFactory.realistic()
        
        // Basic checks
        XCTAssertGreaterThan(transactions.count, 50)
        
        // Check month span
        let months = Set(transactions.map { Calendar.current.component(.month, from: $0.date) })
        XCTAssertGreaterThanOrEqual(months.count, 3)
        
        // Check sorting
        for i in 1..<transactions.count {
            XCTAssertGreaterThanOrEqual(transactions[i-1].date, transactions[i].date)
        }
        
        // Check transaction types
        let byType = Dictionary(grouping: transactions) { $0.transactionType }
        let variable = byType[.variableExpense]?.count ?? 0
        let fixed = byType[.fixedExpense]?.count ?? 0
        let income = byType[.income]?.count ?? 0
        
        XCTAssertGreaterThan(fixed, 5)
        XCTAssertGreaterThan(income, 3)
        XCTAssertGreaterThan(variable, fixed)
        XCTAssertGreaterThan(variable, income)
        XCTAssertGreaterThan(Double(variable) / Double(transactions.count), 0.6)
        
        // Check for expected fixed expenses
        let fixedMemos = transactions
            .filter { $0.transactionType == .fixedExpense }
            .compactMap { $0.memo }
        XCTAssertTrue(fixedMemos.contains { $0.contains("월세") || $0.contains("요금") })
    }
    
    // MARK: - Test Scenarios
    
    func test_predefinedScenarios() {
        // Empty
        XCTAssertTrue(TransactionFactory.empty.isEmpty)
        
        // Minimal
        let minimal = TransactionFactory.minimal
        XCTAssertEqual(minimal.count, 5)
        minimal.forEach { assertValidTransaction($0) }
        
        // Normal
        let normal = TransactionFactory.normal
        XCTAssertEqual(normal.count, 50)
        XCTAssertGreaterThan(Set(normal.map { $0.amount }).count, 20)
        
        // Edge cases
        let edge = TransactionFactory.edge
        XCTAssertEqual(edge.count, 4)
        let amounts = edge.map { $0.amount }
        XCTAssertTrue(amounts.contains(1))
        XCTAssertTrue(amounts.contains(10_000_000))
        XCTAssertTrue(edge.contains { $0.date > Date() })
        XCTAssertTrue(edge.contains { 
            $0.date < Calendar.current.date(byAdding: .year, value: -1, to: Date())!
        })
    }
    
    // MARK: - Date and Amount Tests
    
    func test_dateAndAmountDistribution() {
        let transactions = TransactionFactory.randomSet(count: 100)
        
        // Date distribution
        let calendar = Calendar.current
        let days = Set(transactions.map { calendar.component(.day, from: $0.date) })
        XCTAssertGreaterThan(days.count, 10)
        
        let hours = transactions.map { calendar.component(.hour, from: $0.date) }
        hours.forEach { XCTAssert($0 >= 9 && $0 <= 21) }
        
        // Amount ranges by type
        let realistic = TransactionFactory.realistic()
        let byType = Dictionary(grouping: realistic) { $0.transactionType }
        
        byType[.variableExpense]?.forEach {
            XCTAssert($0.amount > 0 && $0.amount < 500_000)
        }
        byType[.fixedExpense]?.forEach {
            XCTAssert($0.amount > 10_000 && $0.amount < 1_000_000)
        }
        byType[.income]?.forEach {
            XCTAssert($0.amount > 50_000 && $0.amount < 10_000_000)
        }
    }
    
    // MARK: - Content and Distribution Tests
    
    func test_contentAndDistribution() {
        let transactions = (0..<100).map { _ in TransactionFactory.createRandom() }
        
        // Korean content check
        let places = transactions.compactMap { $0.place }
        let memos = transactions.compactMap { $0.memo }
        let koreanPlaces = ["스타벅스", "맥도날드", "이마트", "CGV", "올리브영"]
        let koreanCount = koreanPlaces.filter { place in 
            places.contains { $0.contains(place) }
        }.count
        XCTAssertGreaterThan(koreanCount, 2)
        
        let memoCategories = ["식사", "커피", "쇼핑", "교통", "영화"]
        let categoryCount = memoCategories.filter { cat in
            memos.contains { $0.contains(cat) }
        }.count
        XCTAssertGreaterThan(categoryCount, 2)
        
        // Payment method distribution
        let methods = Dictionary(grouping: transactions) { $0.paymentMethod.name }
        XCTAssertGreaterThan(methods["신용카드"]?.count ?? 0, 0)
        XCTAssertGreaterThan((methods["현금"]?.count ?? 0) + (methods["체크카드"]?.count ?? 0), 0)
    }
    
    // MARK: - Data Integrity Tests
    
    func test_dataIntegrity() {
        let scenarios: [() -> [TransactionDTO]] = [
            { TransactionFactory.minimal },
            { TransactionFactory.normal },
            { TransactionFactory.realistic() },
            { TransactionFactory.edge },
            { TransactionFactory.empty }
        ]
        
        for scenario in scenarios {
            let transactions = scenario()
            transactions.forEach { assertValidTransaction($0) }
            
            // Type consistency
            transactions.forEach {
                XCTAssertEqual($0.transactionType, $0.subCategory.transactionType)
            }
            
            // ID uniqueness
            let ids = transactions.map { $0.id }
            XCTAssertEqual(ids.count, Set(ids).count)
        }
    }
    
    // MARK: - Helper Methods
    
    private func assertValidTransaction(_ transaction: TransactionDTO) {
        XCTAssertGreaterThan(transaction.amount, 0)
        XCTAssertNotNil(transaction.date)
        XCTAssertNotNil(transaction.subCategory)
        XCTAssertNotNil(transaction.paymentMethod)
    }
    
    private func assertDataDiversity(transactions: [TransactionDTO]) {
        let places = Set(transactions.compactMap { $0.place })
        let memos = Set(transactions.compactMap { $0.memo })
        let subcategories = Set(transactions.map { $0.subCategory.id })
        let methods = Set(transactions.map { $0.paymentMethod.id })
        
        XCTAssertGreaterThan(places.count, 5)
        XCTAssertGreaterThan(memos.count, 5)
        XCTAssertGreaterThan(subcategories.count, 3)
        XCTAssertGreaterThan(methods.count, 2)
    }
}
