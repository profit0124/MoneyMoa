//
//  StatisticsRepositoryImplAnalyticsTests.swift
//  MoneyMoaTests
//
//  Created by Sooik Kim on 9/10/25.
//

import Testing
import Foundation
@testable import MoneyMoa

@Suite("StatisticsRepositoryImpl Analytics Tests")
struct StatisticsRepositoryImplAnalyticsTests {
    
    // MARK: - Test Setup
    
    struct TestRepositories {
        let statsRepo: StatisticsRepositoryImpl
        let txRepo: MockTransactionRepository
        let budgetRepo: MockBudgetRepository
    }
    
    private func createRepository(
        txScenario: MockTransactionRepository.DataScenario = .normal(),
        budgetScenario: MockBudgetRepository.DataScenario = .normal
    ) -> TestRepositories {
        let txRepo = MockTransactionRepository(scenario: txScenario)
        let budgetRepo = MockBudgetRepository(scenario: budgetScenario)
        let txAdapter = TransactionRepositoryAdapter(repo: txRepo)
        let budgetAdapter = BudgetRepositoryAdapter(budgetRepo: budgetRepo, txRepo: txRepo)
        let statsRepo = StatisticsRepositoryImpl(tx: txAdapter, budget: budgetAdapter)
        
        return TestRepositories(statsRepo: statsRepo, txRepo: txRepo, budgetRepo: budgetRepo)
    }
    
    private func createTestRange(months: Int = 3) -> DateRange {
        // 고정된 날짜 사용으로 CI 환경 호환성 보장
        return FixedDateHelper.createRange(months: months)
    }
    
    // MARK: - fetchMonthlyTotals Tests
    
    private func insertMonthlyTestData(
        txRepo: MockTransactionRepository,
        aug2025: Date,
        sep2025: Date
    ) async throws {
        let monthlyData = [
            (aug2025, 1000000, TransactionType.income, PaymentMethodDTO.mockTransfer),
            (aug2025, 600000, TransactionType.variableExpense, PaymentMethodDTO.mockCreditCard),
            (sep2025, 1200000, TransactionType.income, PaymentMethodDTO.mockTransfer),
            (sep2025, 600000, TransactionType.variableExpense, PaymentMethodDTO.mockCreditCard)
        ]
        
        for (date, amount, txType, payment) in monthlyData {
            let subCategory: SubCategoryDTO = txType == TransactionType.income ? SubCategoryDTO.mockSalary : SubCategoryDTO.mockFoodExpense
            try await txRepo.insertTransaction(
                TransactionFactory.create(
                    amount: Decimal(amount),
                    date: date,
                    transactionType: txType,
                    subCategory: subCategory,
                    paymentMethod: payment
                )
            )
        }
    }
    
    private func verifyMonthlyTotals(
        _ results: [MonthlyPointDTO],
        cal: Calendar
    ) {
        #expect(results.count == 2)
        
        let aug = results.first { cal.component(.month, from: $0.monthStart) == 8 }!
        #expect(aug.income == 1000000)
        #expect(aug.expense == 600000)
        #expect(abs(aug.savingsRate - 40.0) < 0.01)
        #expect(aug.previousMonthChange == 0)
        
        let sep = results.first { cal.component(.month, from: $0.monthStart) == 9 }!
        #expect(sep.income == 1200000)
        #expect(sep.expense == 600000)
        #expect(abs(sep.savingsRate - 50.0) < 0.01)
        #expect(abs(sep.previousMonthChange - 10.0) < 0.01)
    }
    
    @Test("fetchMonthlyTotals: 저축률과 전월 대비 변화 계산")
    func testFetchMonthlyTotals_CalculatesSavingsRate() async throws {
        // Given
        let repos = createRepository(txScenario: .empty)
        
        let cal = Calendar.current
        let aug2025 = cal.date(from: DateComponents(year: 2025, month: 8, day: 15))!
        let sep2025 = cal.date(from: DateComponents(year: 2025, month: 9, day: 15))!
        
        try await insertMonthlyTestData(txRepo: repos.txRepo, aug2025: aug2025, sep2025: sep2025)
        
        let range = DateRange(
            start: cal.date(from: DateComponents(year: 2025, month: 8, day: 1))!,
            end: cal.date(from: DateComponents(year: 2025, month: 10, day: 1))!,
            calendar: cal
        )
        
        // When
        let results = try await repos.statsRepo.fetchMonthlyTotals(range: range)
        
        // Then
        verifyMonthlyTotals(results, cal: cal)
    }
    
    @Test("fetchMonthlyTotals: 수입이 0일 때 저축률 0")
    func testFetchMonthlyTotals_ZeroIncome() async throws {
        // Given
        let repos = createRepository(txScenario: .empty)
        
        let date = FixedDateHelper.fixedDate
        
        // 수입 없이 지출만 있는 경우
        try await repos.txRepo.insertTransaction(
            TransactionFactory.create(
                amount: 100000,
                date: date,
                transactionType: .variableExpense,
                subCategory: .mockFoodExpense,
                paymentMethod: .mockCash
            )
        )
        
        let range = FixedDateHelper.fixedMonthRange
        
        // When
        let results = try await repos.statsRepo.fetchMonthlyTotals(range: range)
        
        // Then
        #expect(results.count == 1)
        #expect(results[0].income == 0)
        #expect(results[0].expense == 100000)
        #expect(results[0].savingsRate == 0) // 수입이 0이므로 저축률도 0
    }
    
    // MARK: - fetchDailyExpenses Tests
    
    private func insertWeeklyTestData(
        txRepo: MockTransactionRepository,
        dates: [Date],
        amounts: [Int]
    ) async throws {
        for (index, date) in dates.enumerated() {
            try await txRepo.insertTransaction(
                TransactionFactory.create(
                    amount: Decimal(amounts[index]),
                    date: date,
                    transactionType: .variableExpense,
                    subCategory: .mockFoodExpense,
                    paymentMethod: PaymentMethodDTO.mockCash
                )
            )
        }
    }
    
    private func verifyWeekendFlags(
        _ results: [DailyPointDTO],
        cal: Calendar
    ) {
        #expect(results.count == 4)
        
        let fri = results.first { cal.component(.day, from: $0.date) == 15 }!
        let sat = results.first { cal.component(.day, from: $0.date) == 16 }!
        let sun = results.first { cal.component(.day, from: $0.date) == 17 }!
        let mon = results.first { cal.component(.day, from: $0.date) == 18 }!
        
        #expect(fri.isWeekend == false)
        #expect(sat.isWeekend == true)
        #expect(sun.isWeekend == true)
        #expect(mon.isWeekend == false)
    }
    
    @Test("fetchDailyExpenses: 주말 플래그 설정")
    func testFetchDailyExpenses_WeekendFlag() async throws {
        // Given
        let repos = createRepository(txScenario: .empty)
        
        let cal = Calendar.current
        let baseDate = FixedDateHelper.fixedDate // August 15, 2025
        let dates = [
            baseDate,
            cal.date(byAdding: .day, value: 1, to: baseDate)!,
            cal.date(byAdding: .day, value: 2, to: baseDate)!,
            cal.date(byAdding: .day, value: 3, to: baseDate)!
        ]
        
        try await insertWeeklyTestData(txRepo: repos.txRepo, dates: dates, amounts: [10000, 20000, 30000, 40000])
        
        let range = FixedDateHelper.fixedMonthRange
        
        // When
        let results = try await repos.statsRepo.fetchDailyExpenses(range: range)
        
        // Then
        verifyWeekendFlags(results, cal: cal)
    }
    
    // MARK: - fetchCategoryExpenseByMonth Tests
    
    private func insertCategoryTestData(
        txRepo: MockTransactionRepository,
        date: Date
    ) async throws {
        let categoryData = [
            (10000, SubCategoryDTO.mockFoodExpense),
            (20000, SubCategoryDTO.mockTransportBus),
            (30000, SubCategoryDTO.mockShopping)
        ]
        
        for (amount, subCategory) in categoryData {
            try await txRepo.insertTransaction(
                TransactionFactory.create(
                    amount: Decimal(amount),
                    date: date,
                    transactionType: .variableExpense,
                    subCategory: subCategory,
                    paymentMethod: PaymentMethodDTO.mockCash
                )
            )
        }
    }
    
    private func verifyCategoryColors(_ results: [CategoryMonthlyPointDTO]) {
        #expect(results.count == 3)
        
        let colors = results.map { $0.color }
        let uniqueColors = Set(colors)
        #expect(uniqueColors.count == 3)
        
        for result in results {
            #expect(result.color != .clear)
        }
    }
    
    @Test("fetchCategoryExpenseByMonth: 색상 할당")
    func testFetchCategoryExpenseByMonth_ColorAssignment() async throws {
        // Given
        let repos = createRepository(txScenario: .empty)
        
        let date = FixedDateHelper.fixedDate
        
        try await insertCategoryTestData(txRepo: repos.txRepo, date: date)
        
        let range = FixedDateHelper.fixedMonthRange
        
        // When
        let results = try await repos.statsRepo.fetchCategoryExpenseByMonth(range: range)
        
        // Then
        verifyCategoryColors(results)
    }
}
