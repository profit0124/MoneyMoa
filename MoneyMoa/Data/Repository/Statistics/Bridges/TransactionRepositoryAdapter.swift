//
//  TransactionRepositoryAdapter.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/29/25.
//

import Foundation

private struct PaymentMethodAccumulator {
    let name: String
    var amount: Decimal
    var count: Int

    init(name: String, amount: Decimal = 0, count: Int = 0) {
        self.name = name
        self.amount = amount
        self.count = count
    }

    mutating func add(amount: Decimal) {
        self.amount += amount
        self.count += 1
    }
}

public protocol TransactionQuerying {
    func fetchExpenses(range: DateRange) async throws -> [TransactionRow]
    func fetchIncomeAndExpenseMonthly(range: DateRange) async throws -> [IncomeExpenseMonthlyRow]
    func fetchCategoryExpenseByMonth(range: DateRange) async throws -> [CategoryMonthlyRow]
    func fetchPaymentMethodStats(range: DateRange) async throws -> [PaymentMethodStatsRow]
    func fetchTransactionTypeRatio(range: DateRange) async throws -> (income: Double, expense: Double) // ← 이건 3튜플이라 유지해도 대개 OK
    func fetchMerchantRanking(range: DateRange) async throws -> [MerchantRankingRow]
}

/// 기존 TransactionRepository → TransactionQuerying 어댑터
/// - KST 기준의 집계 규칙과 [start, end) 경계 변환을 이 계층에서 강제
public final class TransactionRepositoryAdapter: TransactionQuerying {
    private let repo: TransactionRepository

    public init(repo: TransactionRepository) {
        self.repo = repo
    }

    public func fetchExpenses(range: DateRange) async throws -> [TransactionRow] {
        // 일별 합계가 필요: 트랜잭션을 가져와 KST 자정 기준으로 그룹화
        let (s, e) = range.inclusiveRange()
        let txs = try await repo.fetchTransactions(from: s, to: e)
        var daily: [Date: Decimal] = [:]
        for t in txs where t.transactionType == .fixedExpense || t.transactionType == .variableExpense {
            let dayKey = KST.calendar.startOfDay(for: t.date)
            daily[dayKey, default: 0] += t.amount
        }
        return daily.keys.sorted().map { TransactionRow(date: $0, amount: daily[$0]!) }
    }

    public func fetchIncomeAndExpenseMonthly(range: DateRange) async throws -> [IncomeExpenseMonthlyRow] {
        let yms = range.months()
        var out: [IncomeExpenseMonthlyRow] = []
        for ym in yms {
            let startDate = ym.startOfMonth
            let endDate = ym.endOfMonth
            let pairs = try await repo.getTotalAmountByType(from: startDate, to: endDate)
            let income  = pairs.first(where: { $0.0 == .income })?.1 ?? 0
            let fixed   = pairs.first(where: { $0.0 == .fixedExpense })?.1 ?? 0
            let variable = pairs.first(where: { $0.0 == .variableExpense })?.1 ?? 0
            out.append(.init(monthStart: ym.startDate(), income: income, expense: fixed + variable))
        }
        return out
    }

    public func fetchCategoryExpenseByMonth(range: DateRange) async throws -> [CategoryMonthlyRow] {
        // SubCategory 합계를 Category 단위로 승격
        let yms = range.months()
        var out: [CategoryMonthlyRow] = []
        for ym in yms {
            let startDate = ym.startOfMonth
            let endDate = ym.endOfMonth
            let bySub = try await repo.getTotalAmountBySubCategory(from: startDate, to: endDate)
            var byCat: [String: (name: String, sum: Decimal)] = [:]
            for (sub, amt) in bySub {
                // NOTE: 프로젝트 DTO에 맞춰 parent category 접근자를 확인하세요.
                let catId = sub.categoryId.uuidString
                let catName = sub.categoryName
                var cur = byCat[catId] ?? (catName, 0)
                cur.sum += amt
                byCat[catId] = cur
            }
            let m = ym.startDate()
            out += byCat.map { (id, v) in CategoryMonthlyRow(categoryId: id, categoryName: v.name, monthStart: m, expense: v.sum) }
        }
        return out
    }
    
    public func fetchPaymentMethodStats(range: DateRange) async throws -> [PaymentMethodStatsRow] {
        let (s, e) = range.inclusiveRange()
        let txs = try await repo.fetchTransactions(from: s, to: e)
        var map: [UUID: PaymentMethodAccumulator] = [:]
        for t in txs where t.transactionType == .fixedExpense || t.transactionType == .variableExpense {
            let id = t.paymentMethod.id
            if map[id] == nil {
                map[id] = PaymentMethodAccumulator(name: t.paymentMethod.name)
            }
            map[id]?.add(amount: t.amount)
        }
        return map.map { (id, accumulator) in 
            PaymentMethodStatsRow(methodId: id.uuidString, methodName: accumulator.name, amount: accumulator.amount, count: accumulator.count)
        }
    }

    public func fetchTransactionTypeRatio(range: DateRange) async throws -> (income: Double, expense: Double) {
        let (s, e) = range.inclusiveRange()
        let pairs = try await repo.getTotalAmountByType(from: s, to: e)
        let income  = pairs.first(where: { $0.0 == .income })?.1 ?? 0
        let fixed   = pairs.first(where: { $0.0 == .fixedExpense })?.1 ?? 0
        let variable = pairs.first(where: { $0.0 == .variableExpense })?.1 ?? 0
        let expense = fixed + variable
        let total = income + expense
        guard total != 0 else { return (0, 0) }
        return ((income/total).asDouble, (expense/total).asDouble)
    }

    public func fetchMerchantRanking(range: DateRange) async throws -> [MerchantRankingRow] {
        let (s, e) = range.inclusiveRange()
        let txs = try await repo.fetchTransactions(from: s, to: e)
        var map: [String: (count: Int, total: Decimal)] = [:]
        for t in txs where t.transactionType == .fixedExpense || t.transactionType == .variableExpense {
            let key = (t.place?.isEmpty == false) ? t.place! : "기타"
            var cur = map[key] ?? (0, 0)
            cur.count += 1
            cur.total += t.amount
            map[key] = cur
        }
        return map
            .map { (k, v) in MerchantRankingRow(merchant: k, count: v.count, total: v.total) }
            .sorted { a, b in
                if a.total == b.total { return a.count > b.count }
                return a.total > b.total
            }
    }
}
