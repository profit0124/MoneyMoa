//
//  StatisticsRepositoryImpl.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/29/25.
//

import Foundation
import SwiftUI

public final class StatisticsRepositoryImpl: StatisticsRepository {
    private let tx: TransactionQuerying
    private let budget: BudgetQuerying

    public init(tx: TransactionQuerying, budget: BudgetQuerying) {
        self.tx = tx
        self.budget = budget
    }

    public func fetchMonthlyTotals(range: DateRange) async throws -> [MonthlyPointDTO] {
        let rows = try await tx.fetchIncomeAndExpenseMonthly(range: range)
        return calculateMonthlyAnalytics(rows)
    }
    
    private func calculateMonthlyAnalytics(_ rows: [IncomeExpenseMonthlyRow]) -> [MonthlyPointDTO] {
        var result: [MonthlyPointDTO] = []
        
        for (index, row) in rows.enumerated() {
            let netIncome = row.income - row.expense
            let savingsRate = row.income > 0 ? Double(truncating: (netIncome / row.income) as NSDecimalNumber) * 100 : 0
            
            // 전월 대비 저축률 변화율 계산 (포인트 차이)
            let previousMonthChange: Double
            if index > 0, let previousSavingsRate = result.last?.savingsRate {
                previousMonthChange = savingsRate - previousSavingsRate
            } else {
                previousMonthChange = 0.0
            }
            
            result.append(MonthlyPointDTO(
                monthStart: row.monthStart,
                income: row.income,
                expense: row.expense,
                savingsRate: savingsRate,
                previousMonthChange: previousMonthChange
            ))
        }
        
        return result
    }

    public func fetchDailyExpenses(range: DateRange) async throws -> [DailyPointDTO] {
        let rows = try await tx.fetchExpenses(range: range)
        return calculateDailyAnalytics(rows)
    }
    
    private func calculateDailyAnalytics(_ rows: [TransactionRow]) -> [DailyPointDTO] {
        let calendar = Calendar.current
        
        return rows.map { row in
            DailyPointDTO(
                date: row.date,
                amount: row.amount,
                movingAverage: 0,  // MovingAverageService에서 계산됨
                isWeekend: calendar.isDateInWeekend(row.date)
            )
        }
    }

    public func fetchCategoryExpenseByMonth(range: DateRange) async throws -> [CategoryMonthlyPointDTO] {
        let rows = try await tx.fetchCategoryExpenseByMonth(range: range)
        return assignCategoryColors(rows)
    }
    
    private func assignCategoryColors(_ rows: [CategoryMonthlyRow]) -> [CategoryMonthlyPointDTO] {
        let uniqueCategories = Array(Set(rows.map { $0.categoryName }))
        
        return rows.map { row in
            let colorIndex = uniqueCategories.firstIndex(of: row.categoryName) ?? 0
            let color = StatisticsColorScheme.categoryColor(at: colorIndex)
            
            return CategoryMonthlyPointDTO(
                categoryId: row.categoryId,
                categoryName: row.categoryName,
                monthStart: row.monthStart,
                expense: row.expense,
                color: color
            )
        }
    }

    public func fetchPaymentMethodStats(range: DateRange) async throws -> [PaymentMethodRatioDTO] {
        let rows = try await tx.fetchPaymentMethodStats(range: range)
        let total = rows.reduce(Decimal(0)) { $0 + $1.amount }
        
        return rows.enumerated().map { index, row in
            let ratio = (total == 0) ? 0 : (row.amount / total).asDouble
            let color = StatisticsColorScheme.paymentMethodColor(at: index)
            
            return PaymentMethodRatioDTO(
                methodId: row.methodId,
                methodName: row.methodName,
                ratio: ratio,
                amount: row.amount,
                count: row.count,
                color: color
            )
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
