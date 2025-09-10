//
//  TransactionRepositoryAdapterTests.swift
//  MoneyMoaTests
//
//  Created by Sooik Kim on 9/9/25.
//

import Foundation
import Testing
@testable import MoneyMoa

struct TransactionRepositoryAdapterTests {
    
    // MARK: - Test Setup Helpers
    
    private func setupAdapter(scenario: MockTransactionRepository.DataScenario = .normal()) -> TransactionRepositoryAdapter {
        let mockRepo = MockTransactionRepository(scenario: scenario)
        return TransactionRepositoryAdapter(repo: mockRepo)
    }
    
    private func createTestTransactions() -> [TransactionDTO] {
        let cal = KST.calendar
        let baseDate = cal.date(from: DateComponents(year: 2025, month: 8, day: 1))!
        
        return [
            // Day 1: Multiple expenses
            TransactionFactory.create(
                amount: 10000,
                date: baseDate,
                place: "카페",
                transactionType: .variableExpense,
                subCategory: .mockFoodExpense,
                paymentMethod: .mockCreditCard
            ),
            TransactionFactory.create(
                amount: 5000,
                date: baseDate,
                place: "편의점",
                transactionType: .variableExpense,
                subCategory: .mockFoodExpense,
                paymentMethod: .mockCash
            ),
            // Day 2: Single expense
            TransactionFactory.create(
                amount: 20000,
                date: cal.date(byAdding: .day, value: 1, to: baseDate)!,
                place: "식당",
                transactionType: .variableExpense,
                subCategory: .mockFoodExpense,
                paymentMethod: .mockCreditCard
            ),
            // Day 5: Income
            TransactionFactory.create(
                amount: 3000000,
                date: cal.date(byAdding: .day, value: 4, to: baseDate)!,
                place: "회사",
                transactionType: .income,
                subCategory: .mockSalary,
                paymentMethod: .mockTransfer
            ),
            // Day 10: Fixed expense
            TransactionFactory.create(
                amount: 500000,
                date: cal.date(byAdding: .day, value: 9, to: baseDate)!,
                place: "통신사",
                transactionType: .fixedExpense,
                subCategory: .mockUtilitiesMobile,
                paymentMethod: .mockTransfer
            )
        ]
    }
    
    // MARK: - fetchExpenses Tests
    
    @Test
    func fetchExpenses_aggregatesDailyExpenses() async throws {
        // Given
        let mockRepo = MockTransactionRepository(scenario: .empty)
        let adapter = TransactionRepositoryAdapter(repo: mockRepo)
        let transactions = createTestTransactions()
        
        // Insert test transactions
        for transaction in transactions {
            try await mockRepo.insertTransaction(transaction)
        }
        
        let cal = KST.calendar
        let startDate = cal.date(from: DateComponents(year: 2025, month: 8, day: 1))!
        let endDate = cal.date(from: DateComponents(year: 2025, month: 8, day: 31))!
        let range = DateRange(start: startDate, end: endDate, calendar: cal)
        
        // When
        let dailyExpenses = try await adapter.fetchExpenses(range: range)
        
        // Then
        // Should only include expense types (not income)
        #expect(dailyExpenses.count == 3) // Day 1, 2, and 10
        
        // Day 1 should have aggregated amount
        let day1 = dailyExpenses.first { cal.component(.day, from: $0.date) == 1 }
        #expect(day1?.amount == 15000) // 10000 + 5000
        
        // Day 2 should have single amount
        let day2 = dailyExpenses.first { cal.component(.day, from: $0.date) == 2 }
        #expect(day2?.amount == 20000)
        
        // Day 10 should have fixed expense
        let day10 = dailyExpenses.first { cal.component(.day, from: $0.date) == 10 }
        #expect(day10?.amount == 500000)
        
        // Should be sorted by date
        for i in 0..<(dailyExpenses.count - 1) {
            #expect(dailyExpenses[i].date <= dailyExpenses[i + 1].date)
        }
    }
    
    @Test
    func fetchExpenses_excludesIncome() async throws {
        // Given
        let mockRepo = MockTransactionRepository(scenario: .empty)
        let adapter = TransactionRepositoryAdapter(repo: mockRepo)
        
        let cal = KST.calendar
        let date = cal.date(from: DateComponents(year: 2025, month: 8, day: 15))!
        
        // Insert only income transaction
        try await mockRepo.insertTransaction(
            TransactionFactory.create(
                amount: 1000000,
                date: date,
                transactionType: .income,
                subCategory: .mockSalary,
                paymentMethod: .mockTransfer
            )
        )
        
        let range = DateRange(
            start: cal.date(from: DateComponents(year: 2025, month: 8, day: 1))!,
            end: cal.date(from: DateComponents(year: 2025, month: 8, day: 31))!,
            calendar: cal
        )
        
        // When
        let expenses = try await adapter.fetchExpenses(range: range)
        
        // Then
        #expect(expenses.isEmpty) // Income should be excluded
    }
    
    // MARK: - fetchIncomeAndExpenseMonthly Tests
    
    @Test
    func fetchIncomeAndExpenseMonthly_aggregatesCorrectly() async throws {
        // Given
        let mockRepo = MockTransactionRepository(scenario: .empty)
        let adapter = TransactionRepositoryAdapter(repo: mockRepo)
        
        let cal = KST.calendar
        let aug2025 = cal.date(from: DateComponents(year: 2025, month: 8, day: 15))!
        let sep2025 = cal.date(from: DateComponents(year: 2025, month: 9, day: 15))!
        
        // August transactions
        try await mockRepo.insertTransaction(
            TransactionFactory.create(amount: 100000, date: aug2025, transactionType: .income, subCategory: .mockSalary, paymentMethod: .mockTransfer)
        )
        try await mockRepo.insertTransaction(
            TransactionFactory.create(amount: 30000, date: aug2025, transactionType: .fixedExpense, subCategory: .mockUtilitiesMobile, paymentMethod: .mockCash)
        )
        try await mockRepo.insertTransaction(
            TransactionFactory.create(amount: 20000, date: aug2025, transactionType: .variableExpense, subCategory: .mockFoodExpense, paymentMethod: .mockCreditCard)
        )
        
        // September transactions
        try await mockRepo.insertTransaction(
            TransactionFactory.create(amount: 150000, date: sep2025, transactionType: .income, subCategory: .mockSalary, paymentMethod: .mockTransfer)
        )
        try await mockRepo.insertTransaction(
            TransactionFactory.create(amount: 40000, date: sep2025, transactionType: .variableExpense, subCategory: .mockFoodExpense, paymentMethod: .mockCreditCard)
        )
        
        let range = DateRange(
            start: cal.date(from: DateComponents(year: 2025, month: 8, day: 1))!,
            end: cal.date(from: DateComponents(year: 2025, month: 10, day: 1))!,
            calendar: cal
        )
        
        // When
        let monthlyData = try await adapter.fetchIncomeAndExpenseMonthly(range: range)
        
        // Then
        #expect(monthlyData.count == 2) // August and September
        
        // August
        let august = monthlyData.first { cal.component(.month, from: $0.monthStart) == 8 }
        #expect(august?.income == 100000)
        #expect(august?.expense == 50000) // 30000 + 20000
        
        // September
        let september = monthlyData.first { cal.component(.month, from: $0.monthStart) == 9 }
        #expect(september?.income == 150000)
        #expect(september?.expense == 40000)
    }
    
    // MARK: - fetchCategoryExpenseByMonth Tests
    
    @Test
    func fetchCategoryExpenseByMonth_groupsByCategory() async throws {
        // Given
        let mockRepo = MockTransactionRepository(scenario: .empty)
        let adapter = TransactionRepositoryAdapter(repo: mockRepo)
        
        let cal = KST.calendar
        let aug2025 = cal.date(from: DateComponents(year: 2025, month: 8, day: 15))!
        
        // Same month, different categories
        try await mockRepo.insertTransaction(
            TransactionFactory.create(amount: 10000, date: aug2025, transactionType: .variableExpense, subCategory: .mockFoodExpense, paymentMethod: .mockCash)
        )
        try await mockRepo.insertTransaction(
            TransactionFactory.create(amount: 15000, date: aug2025, transactionType: .variableExpense, subCategory: .mockFoodExpense, paymentMethod: .mockCreditCard)
        )
        try await mockRepo.insertTransaction(
            TransactionFactory.create(amount: 30000, date: aug2025, transactionType: .fixedExpense, subCategory: .mockTransportBus, paymentMethod: .mockTransfer)
        )
        
        let range = DateRange(
            start: cal.date(from: DateComponents(year: 2025, month: 8, day: 1))!,
            end: cal.date(from: DateComponents(year: 2025, month: 9, day: 1))!,
            calendar: cal
        )
        
        // When
        let categoryData = try await adapter.fetchCategoryExpenseByMonth(range: range)
        
        // Then
        // Should have entries for each category (Food parent and 생활비 parent)
        let foodCategory = categoryData.first { $0.categoryName == "식비" }
        let lifeCategory = categoryData.first { $0.categoryName == "생활비" }
        
        #expect(foodCategory?.expense == 25000) // 10000 + 15000
        #expect(lifeCategory?.expense == 30000)
    }
    
    // MARK: - fetchPaymentMethodStats Tests
    
    @Test
    func fetchPaymentMethodStats_countsAndSums() async throws {
        // Given
        let mockRepo = MockTransactionRepository(scenario: .empty)
        let adapter = TransactionRepositoryAdapter(repo: mockRepo)
        
        let cal = KST.calendar
        let date = cal.date(from: DateComponents(year: 2025, month: 8, day: 15))!
        
        // Multiple transactions with same payment method
        try await mockRepo.insertTransaction(
            TransactionFactory.create(amount: 10000, date: date, transactionType: .variableExpense, subCategory: .mockFoodExpense, paymentMethod: .mockCreditCard)
        )
        try await mockRepo.insertTransaction(
            TransactionFactory.create(amount: 20000, date: date, transactionType: .variableExpense, subCategory: .mockFoodExpense, paymentMethod: .mockCreditCard)
        )
        try await mockRepo.insertTransaction(
            TransactionFactory.create(amount: 5000, date: date, transactionType: .variableExpense, subCategory: .mockFoodExpense, paymentMethod: .mockCash)
        )
        // Income should be excluded
        try await mockRepo.insertTransaction(
            TransactionFactory.create(amount: 100000, date: date, transactionType: .income, subCategory: .mockSalary, paymentMethod: .mockTransfer)
        )
        
        let range = DateRange(
            start: cal.date(from: DateComponents(year: 2025, month: 8, day: 1))!,
            end: cal.date(from: DateComponents(year: 2025, month: 8, day: 31))!,
            calendar: cal
        )
        
        // When
        let stats = try await adapter.fetchPaymentMethodStats(range: range)
        
        // Then
        let creditCardStats = stats.first { $0.methodName == "신용카드" }
        let cashStats = stats.first { $0.methodName == "현금" }
        
        #expect(creditCardStats?.amount == 30000) // 10000 + 20000
        #expect(creditCardStats?.count == 2)
        
        #expect(cashStats?.amount == 5000)
        #expect(cashStats?.count == 1)
        
        // Transfer should not appear (only income)
        let transferStats = stats.first { $0.methodName == "계좌이체" }
        #expect(transferStats == nil)
    }
    
    // MARK: - fetchTransactionTypeRatio Tests
    
    @Test
    func fetchTransactionTypeRatio_calculatesCorrectRatios() async throws {
        // Given
        let mockRepo = MockTransactionRepository(scenario: .empty)
        let adapter = TransactionRepositoryAdapter(repo: mockRepo)
        
        let cal = KST.calendar
        let date = cal.date(from: DateComponents(year: 2025, month: 8, day: 15))!
        
        // 300000 income, 200000 expense
        try await mockRepo.insertTransaction(
            TransactionFactory.create(amount: 300000, date: date, transactionType: .income, subCategory: .mockSalary, paymentMethod: .mockTransfer)
        )
        try await mockRepo.insertTransaction(
            TransactionFactory.create(amount: 100000, date: date, transactionType: .fixedExpense, subCategory: .mockUtilitiesMobile, paymentMethod: .mockTransfer)
        )
        try await mockRepo.insertTransaction(
            TransactionFactory.create(amount: 100000, date: date, transactionType: .variableExpense, subCategory: .mockFoodExpense, paymentMethod: .mockCash)
        )
        
        let range = DateRange(
            start: cal.date(from: DateComponents(year: 2025, month: 8, day: 1))!,
            end: cal.date(from: DateComponents(year: 2025, month: 8, day: 31))!,
            calendar: cal
        )
        
        // When
        let ratio = try await adapter.fetchTransactionTypeRatio(range: range)
        
        // Then
        #expect(abs(ratio.income - 0.6) < 0.01) // 300000 / 500000 = 0.6
        #expect(abs(ratio.expense - 0.4) < 0.01) // 200000 / 500000 = 0.4
        #expect(abs((ratio.income + ratio.expense) - 1.0) < 0.01) // Should sum to 1
    }
    
    @Test
    func fetchTransactionTypeRatio_handlesZeroTotal() async throws {
        // Given
        let mockRepo = MockTransactionRepository(scenario: .empty)
        let adapter = TransactionRepositoryAdapter(repo: mockRepo)
        
        let cal = KST.calendar
        let range = DateRange(
            start: cal.date(from: DateComponents(year: 2025, month: 8, day: 1))!,
            end: cal.date(from: DateComponents(year: 2025, month: 8, day: 31))!,
            calendar: cal
        )
        
        // When - no transactions
        let ratio = try await adapter.fetchTransactionTypeRatio(range: range)
        
        // Then
        #expect(ratio.income == 0)
        #expect(ratio.expense == 0)
    }
    
    // MARK: - fetchMerchantRanking Tests
    
    @Test
    func fetchMerchantRanking_ranksCorrectly() async throws {
        // Given
        let mockRepo = MockTransactionRepository(scenario: .empty)
        let adapter = TransactionRepositoryAdapter(repo: mockRepo)
        
        let cal = KST.calendar
        let date = cal.date(from: DateComponents(year: 2025, month: 8, day: 15))!
        
        // Multiple transactions at same merchant
        try await mockRepo.insertTransaction(
            TransactionFactory.create(amount: 10000, date: date, place: "스타벅스", transactionType: .variableExpense, subCategory: .mockFoodExpense, paymentMethod: .mockCreditCard)
        )
        try await mockRepo.insertTransaction(
            TransactionFactory.create(amount: 15000, date: date, place: "스타벅스", transactionType: .variableExpense, subCategory: .mockFoodExpense, paymentMethod: .mockCreditCard)
        )
        try await mockRepo.insertTransaction(
            TransactionFactory.create(amount: 30000, date: date, place: "이마트", transactionType: .variableExpense, subCategory: .mockFoodExpense, paymentMethod: .mockCash)
        )
        try await mockRepo.insertTransaction(
            TransactionFactory.create(amount: 5000, date: date, place: "GS25", transactionType: .variableExpense, subCategory: .mockFoodExpense, paymentMethod: .mockCash)
        )
        // Empty place should be grouped as "기타"
        try await mockRepo.insertTransaction(
            TransactionFactory.create(amount: 3000, date: date, place: "", transactionType: .variableExpense, subCategory: .mockFoodExpense, paymentMethod: .mockCash)
        )
        try await mockRepo.insertTransaction(
            TransactionFactory.create(amount: 2000, date: date, place: nil, transactionType: .variableExpense, subCategory: .mockFoodExpense, paymentMethod: .mockCash)
        )
        
        let range = DateRange(
            start: cal.date(from: DateComponents(year: 2025, month: 8, day: 1))!,
            end: cal.date(from: DateComponents(year: 2025, month: 8, day: 31))!,
            calendar: cal
        )
        
        // When
        let ranking = try await adapter.fetchMerchantRanking(range: range)
        
        // Then
        #expect(ranking.count == 4) // 스타벅스, 이마트, GS25, 기타
        
        // Should be sorted by total amount descending
        #expect(ranking[0].merchant == "이마트") // 30000
        #expect(ranking[0].total == 30000)
        #expect(ranking[0].count == 1)
        
        #expect(ranking[1].merchant == "스타벅스") // 25000 (10000 + 15000)
        #expect(ranking[1].total == 25000)
        #expect(ranking[1].count == 2)
        
        #expect(ranking[2].merchant == "기타") // 5000 (3000 + 2000) - 2건이므로 GS25보다 우선
        #expect(ranking[2].total == 5000)
        #expect(ranking[2].count == 2)
        
        #expect(ranking[3].merchant == "GS25") // 5000 - 1건
        #expect(ranking[3].total == 5000)
        #expect(ranking[3].count == 1)
    }
    
    // MARK: - Date Range Boundary Tests
    
    @Test
    func dateRange_inclusiveExclusive_boundaryHandling() async throws {
        // Given
        let mockRepo = MockTransactionRepository(scenario: .empty)
        let adapter = TransactionRepositoryAdapter(repo: mockRepo)
        
        let cal = KST.calendar
        let startDate = cal.date(from: DateComponents(year: 2025, month: 8, day: 1, hour: 0, minute: 0, second: 0))!
        let endDate = cal.date(from: DateComponents(year: 2025, month: 9, day: 1, hour: 0, minute: 0, second: 0))!
        
        // Transaction exactly at start boundary
        try await mockRepo.insertTransaction(
            TransactionFactory.create(amount: 10000, date: startDate, transactionType: .variableExpense, subCategory: .mockFoodExpense, paymentMethod: .mockCash)
        )
        
        // Transaction one second before end boundary
        let oneSecBeforeEnd = cal.date(byAdding: .second, value: -1, to: endDate)!
        try await mockRepo.insertTransaction(
            TransactionFactory.create(amount: 20000, date: oneSecBeforeEnd, transactionType: .variableExpense, subCategory: .mockFoodExpense, paymentMethod: .mockCash)
        )
        
        // Transaction exactly at end boundary (should be excluded)
        try await mockRepo.insertTransaction(
            TransactionFactory.create(amount: 30000, date: endDate, transactionType: .variableExpense, subCategory: .mockFoodExpense, paymentMethod: .mockCash)
        )
        
        let range = DateRange(start: startDate, end: endDate, calendar: cal)
        
        // When
        let expenses = try await adapter.fetchExpenses(range: range)
        
        // Then
        #expect(expenses.count == 2) // Start included, end excluded
        #expect(expenses.map { $0.amount }.reduce(0, +) == 30000) // 10000 + 20000, not 60000
    }
}
