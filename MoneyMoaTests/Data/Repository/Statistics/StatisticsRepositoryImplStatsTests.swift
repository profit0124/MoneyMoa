//
//  StatisticsRepositoryImplStatsTests.swift
//  MoneyMoaTests
//
//  Created by Sooik Kim on 9/10/25.
//

import Testing
import Foundation
@testable import MoneyMoa

@Suite("StatisticsRepositoryImpl Stats Tests")
struct StatisticsRepositoryImplStatsTests {
    
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
        let cal = Calendar.current
        let endDate = Date()
        let startDate = cal.date(byAdding: .month, value: -months, to: endDate)!
        return DateRange(start: startDate, end: endDate, calendar: cal)
    }
    
    private func createFixedRange() -> DateRange {
        let cal = Calendar.current
        let start = cal.date(from: DateComponents(year: 2025, month: 6, day: 1))!
        let end = cal.date(from: DateComponents(year: 2025, month: 9, day: 1))!
        return DateRange(start: start, end: end, calendar: cal)
    }
    
    // MARK: - fetchPaymentMethodStats Tests
    
    private func insertPaymentMethodTestData(
        txRepo: MockTransactionRepository,
        date: Date
    ) async throws {
        let paymentData = [
            (PaymentMethodDTO.mockCreditCard, 600000),
            (PaymentMethodDTO.mockCash, 400000)
        ]
        
        for (paymentMethod, amount) in paymentData {
            try await txRepo.insertTransaction(
                TransactionFactory.create(
                    amount: Decimal(amount),
                    date: date,
                    transactionType: .variableExpense,
                    subCategory: .mockFoodExpense,
                    paymentMethod: paymentMethod
                )
            )
        }
    }
    
    private func verifyPaymentMethodStats(_ results: [PaymentMethodRatioDTO]) {
        #expect(results.count == 2)
        
        let creditCard = results.first { $0.methodName == "신용카드" }!
        let cash = results.first { $0.methodName == "현금" }!
        
        #expect(abs(creditCard.ratio - 0.6) < 0.01) // 60%
        #expect(creditCard.amount == 600000)
        #expect(creditCard.count == 1)
        
        #expect(abs(cash.ratio - 0.4) < 0.01) // 40%
        #expect(cash.amount == 400000)
        #expect(cash.count == 1)
        
        #expect(creditCard.color != .clear)
        #expect(cash.color != .clear)
        #expect(creditCard.color != cash.color)
    }
    
    @Test("fetchPaymentMethodStats: 비율 계산 및 색상 할당")
    func testFetchPaymentMethodStats_RatioAndColor() async throws {
        // Given
        let repos = createRepository(txScenario: .empty)
        
        let date = FixedDateHelper.fixedDate
        
        try await insertPaymentMethodTestData(txRepo: repos.txRepo, date: date)
        
        let range = FixedDateHelper.fixedMonthRange
        
        // When
        let results = try await repos.statsRepo.fetchPaymentMethodStats(range: range)
        
        // Then
        verifyPaymentMethodStats(results)
    }
    
    @Test("fetchPaymentMethodStats: 총액이 0일 때 비율 처리")
    func testFetchPaymentMethodStats_ZeroTotal() async throws {
        // Given
        let repos = createRepository(txScenario: .empty)
        
        let range = createTestRange()
        
        // When - 거래가 없는 경우
        let results = try await repos.statsRepo.fetchPaymentMethodStats(range: range)
        
        // Then
        #expect(results.isEmpty) // 거래가 없으므로 빈 배열
    }
    
    // MARK: - fetchTransactionTypeRatio Tests
    
    @Test("fetchTransactionTypeRatio: 단순 변환")
    func testFetchTransactionTypeRatio_SimpleConversion() async throws {
        // Given
        let repos = createRepository(txScenario: .empty)
        
        let date = FixedDateHelper.fixedDate
        
        // 수입 70만원, 지출 30만원
        try await repos.txRepo.insertTransaction(
            TransactionFactory.create(
                amount: 700000,
                date: date,
                transactionType: .income,
                subCategory: .mockSalary,
                paymentMethod: .mockTransfer
            )
        )
        try await repos.txRepo.insertTransaction(
            TransactionFactory.create(
                amount: 300000,
                date: date,
                transactionType: .variableExpense,
                subCategory: .mockFoodExpense,
                paymentMethod: .mockCash
            )
        )
        
        let range = FixedDateHelper.fixedMonthRange
        
        // When
        let result = try await repos.statsRepo.fetchTransactionTypeRatio(range: range)
        
        // Then
        #expect(abs(result.income - 0.7) < 0.01) // 70%
        #expect(abs(result.expense - 0.3) < 0.01) // 30%
    }
    
    // MARK: - fetchMerchantRanking Tests
    
    private func insertMerchantTestData(
        txRepo: MockTransactionRepository,
        date: Date
    ) async throws {
        let merchantData = [
            ("상점A", 500000),
            ("상점B", 300000),
            ("상점C", 200000)
        ]
        
        for (merchant, amount) in merchantData {
            try await txRepo.insertTransaction(
                TransactionFactory.create(
                    amount: Decimal(amount),
                    date: date,
                    place: merchant,
                    transactionType: .variableExpense,
                    subCategory: .mockFoodExpense,
                    paymentMethod: PaymentMethodDTO.mockCash
                )
            )
        }
    }
    
    private func verifyMerchantRanking(_ result: MerchantRankingDTO) {
        #expect(result.entries.count == 3)
        
        let expectedRankings = [
            (1, "상점A", Decimal(500000)),
            (2, "상점B", Decimal(300000)),
            (3, "상점C", Decimal(200000))
        ]
        
        for (index, expected) in expectedRankings.enumerated() {
            #expect(result.entries[index].rank == expected.0)
            #expect(result.entries[index].merchant == expected.1)
            #expect(result.entries[index].total == expected.2)
        }
    }
    
    @Test("fetchMerchantRanking: 순위 할당")
    func testFetchMerchantRanking_RankAssignment() async throws {
        // Given
        let repos = createRepository(txScenario: .empty)
        
        let date = FixedDateHelper.fixedDate
        
        try await insertMerchantTestData(txRepo: repos.txRepo, date: date)
        
        let range = FixedDateHelper.fixedMonthRange
        
        // When
        let result = try await repos.statsRepo.fetchMerchantRanking(range: range)
        
        // Then
        verifyMerchantRanking(result)
    }
    
    // MARK: - fetchBudgetsByCategory Tests
    
    @Test("fetchBudgetsByCategory: 단순 전달")
    func testFetchBudgetsByCategory_SimplePassthrough() async throws {
        // Given
        let repos = createRepository(budgetScenario: .empty) // 먼저 비어있게 시작
        
        let range = createFixedRange() // 6월~8월
        
        // 범위에 포함된 월들에 대해 예산 생성
        let months = range.months()
        var budgets: [BudgetDTO] = []
        for month in months {
            budgets.append(BudgetFactory.normal(for: month))
        }
        repos.budgetRepo.setBudgets(budgets)
        
        // When
        let result = try await repos.statsRepo.fetchBudgetsByCategory(range: range)
        
        // Then
        #expect(!result.isEmpty) // BudgetAdapter를 통해 데이터가 전달됨
        
        // normal 시나리오는 여러 카테고리를 포함
        for (categoryId, monthlyBudgets) in result {
            #expect(!categoryId.isEmpty)
            #expect(!monthlyBudgets.isEmpty)
            
            for (yearMonth, amount) in monthlyBudgets {
                #expect(amount > 0)
                #expect(range.months().contains(yearMonth), "범위 내의 월이어야 함")
            }
        }
    }
    
    // MARK: - fetchBudgetVsExpenseByMonth Tests
    
    @Test("fetchBudgetVsExpenseByMonth: 단순 변환")
    func testFetchBudgetVsExpenseByMonth_SimpleConversion() async throws {
        // Given
        let repos = createRepository(
            txScenario: .empty, // 빈 상태에서 시작
            budgetScenario: .empty
        )
        
        let cal = Calendar.current
        let currentMonth = FixedDateHelper.fixedYearMonth
        let range = DateRange(
            start: currentMonth.startOfMonth,
            end: currentMonth.endOfMonth,
            calendar: cal
        )
        
        // 테스트 월에 맞는 예산 생성
        let budget = BudgetFactory.normal(for: currentMonth)
        repos.budgetRepo.setBudgets([budget])
        
        // 테스트 월에 맞는 거래 생성
        let testDate = FixedDateHelper.fixedDate
        try await repos.txRepo.insertTransaction(
            TransactionFactory.create(
                amount: 300000,
                date: testDate,
                transactionType: .variableExpense,
                subCategory: .mockFoodExpense,
                paymentMethod: .mockCash
            )
        )
        
        // When
        let results = try await repos.statsRepo.fetchBudgetVsExpenseByMonth(range: range)
        
        // Then
        #expect(results.count == 1)
        
        let result = results[0]
        #expect(result.monthStart == currentMonth.startOfMonth)
        #expect(result.budget > 0) // 예산이 있음
        #expect(result.expense == 300000) // 지출이 예상값과 일치
    }
    
    // MARK: - Integration Tests
    
    @Test("전체 통합: realistic 시나리오로 모든 메서드 테스트")
    func testIntegration_RealisticScenario() async throws {
        // Given
        let repos = createRepository(
            txScenario: .realistic,
            budgetScenario: .empty // 먼저 비어있게 시작
        )
        
        let range = createFixedRange()
        
        // 범위에 포함된 월들에 대해 realistic 예산 생성
        let months = range.months()
        var budgets: [BudgetDTO] = []
        for month in months {
            budgets.append(BudgetFactory.normal(for: month))
        }
        repos.budgetRepo.setBudgets(budgets)
        
        // When - 모든 메서드 호출
        let monthlyTotals = try await repos.statsRepo.fetchMonthlyTotals(range: range)
        let dailyExpenses = try await repos.statsRepo.fetchDailyExpenses(range: range)
        let categoryExpenses = try await repos.statsRepo.fetchCategoryExpenseByMonth(range: range)
        let paymentStats = try await repos.statsRepo.fetchPaymentMethodStats(range: range)
        let typeRatio = try await repos.statsRepo.fetchTransactionTypeRatio(range: range)
        let merchantRanking = try await repos.statsRepo.fetchMerchantRanking(range: range)
        let budgetsByCategory = try await repos.statsRepo.fetchBudgetsByCategory(range: range)
        let budgetVsExpense = try await repos.statsRepo.fetchBudgetVsExpenseByMonth(range: range)
        
        // Then - 데이터 일관성 검증
        #expect(!monthlyTotals.isEmpty)
        #expect(!dailyExpenses.isEmpty)
        #expect(!categoryExpenses.isEmpty)
        #expect(!paymentStats.isEmpty)
        #expect(typeRatio.income >= 0 && typeRatio.income <= 1)
        #expect(typeRatio.expense >= 0 && typeRatio.expense <= 1)
        #expect(!merchantRanking.entries.isEmpty)
        #expect(!budgetsByCategory.isEmpty)
        #expect(!budgetVsExpense.isEmpty)
        
        // 데이터 정합성 검증
        let totalRatio = typeRatio.income + typeRatio.expense
        if totalRatio > 0 {
            #expect(abs(totalRatio - 1.0) < 0.01) // 수입과 지출 비율 합이 1
        }
        
        let paymentRatioSum = paymentStats.reduce(0.0) { $0 + $1.ratio }
        if paymentRatioSum > 0 {
            #expect(abs(paymentRatioSum - 1.0) < 0.01) // 결제수단 비율 합이 1
        }
    }
    
    // MARK: - Error Handling Tests
    
    @Test("에러 처리: TransactionRepository 실패")
    func testErrorHandling_TransactionRepositoryFailure() async throws {
        // Given
        let repos = createRepository()
        repos.txRepo.shouldFail = true
        repos.txRepo.errorToThrow = MockError.simulatedFailure
        
        let range = createTestRange()
        
        // When & Then - 각 메서드가 에러를 전파하는지 확인
        await #expect(throws: MockError.simulatedFailure) {
            _ = try await repos.statsRepo.fetchMonthlyTotals(range: range)
        }
        
        await #expect(throws: MockError.simulatedFailure) {
            _ = try await repos.statsRepo.fetchDailyExpenses(range: range)
        }
        
        await #expect(throws: MockError.simulatedFailure) {
            _ = try await repos.statsRepo.fetchCategoryExpenseByMonth(range: range)
        }
    }
    
    @Test("에러 처리: BudgetRepository 실패")
    func testErrorHandling_BudgetRepositoryFailure() async throws {
        // Given
        let repos = createRepository()
        repos.budgetRepo.shouldFail = true
        repos.budgetRepo.errorToThrow = MockError.simulatedFailure
        
        let range = createTestRange()
        
        // When & Then
        await #expect(throws: MockError.simulatedFailure) {
            _ = try await repos.statsRepo.fetchBudgetsByCategory(range: range)
        }
        
        await #expect(throws: MockError.simulatedFailure) {
            _ = try await repos.statsRepo.fetchBudgetVsExpenseByMonth(range: range)
        }
    }
}
