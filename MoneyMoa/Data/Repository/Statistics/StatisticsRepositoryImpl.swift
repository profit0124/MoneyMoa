//
//  StatisticsRepositoryImpl.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/29/25.
//

import Foundation

public final class StatisticsRepositoryImpl: StatisticsRepository {
    private let tx: TransactionQuerying
    private let budget: BudgetQuerying

    public init(tx: TransactionQuerying, budget: BudgetQuerying) {
        self.tx = tx
        self.budget = budget
    }

    public func fetchMonthlyTotals(range: DateRange) async throws -> [MonthlyPointDTO] {
        let rows = try await tx.fetchIncomeAndExpenseMonthly(range: range)
        return rows.map { .init(monthStart: $0.monthStart, income: $0.income, expense: $0.expense) }
    }

    public func fetchDailyExpenses(range: DateRange) async throws -> [DailyPointDTO] {
        let rows = try await tx.fetchExpenses(range: range)
        return rows.map { .init(date: $0.date, amount: $0.amount) }
    }

    public func fetchCategoryExpenseByMonth(range: DateRange) async throws -> [CategoryMonthlyPointDTO] {
        let rows = try await tx.fetchCategoryExpenseByMonth(range: range)
        return rows.map { .init(categoryId: $0.categoryId, categoryName: $0.categoryName, monthStart: $0.monthStart, expense: $0.expense) }
    }

    public func fetchPaymentMethodStats(range: DateRange) async throws -> [PaymentMethodRatioDTO] {
        let rows = try await tx.fetchPaymentMethodStats(range: range)
        let total = rows.reduce(Decimal(0)) { $0 + $1.amount }
        return rows.map { row in
            let ratio = (total == 0) ? 0 : (row.amount / total).asDouble
            return .init(methodId: row.methodId, methodName: row.methodName, ratio: ratio, amount: row.amount, count: row.count)
        }
    }

    public func fetchTransactionTypeRatio(range: DateRange) async throws -> TransactionTypeRatioDTO {
        let r = try await tx.fetchTransactionTypeRatio(range: range)
        return .init(income: r.income, expense: r.expense)
    }

    public func fetchMerchantRanking(range: DateRange) async throws -> MerchantRankingDTO {
        let rows = try await tx.fetchMerchantRanking(range: range)
        let entries = rows.enumerated().map { idx, r in
            MerchantRankingDTO.Entry(rank: idx + 1, merchant: r.merchant, count: r.count, total: r.total)
        }
        return .init(entries: entries)
    }

    public func fetchBudgetsByCategory(range: DateRange) async throws -> [String: [YearMonth: Decimal]] {
        try await budget.fetchBudgets(range: range)
    }

    public func fetchBudgetVsExpenseByMonth(range: DateRange) async throws -> [BudgetVsExpenseDTO] {
        let rows = try await budget.fetchBudgetVsExpenseByMonth(range: range)
        return rows.map { .init(monthStart: $0.monthStart, budget: $0.budget, expense: $0.expense) }
    }
}
