//
//  BudgetRepositoryAdapter.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/29/25.
//

import Foundation

public protocol BudgetQuerying {
    func fetchBudgets(range: DateRange) async throws -> [String: [YearMonth: Decimal]] // categoryId -> (YM -> budget)
    func fetchBudgetVsExpenseByMonth(range: DateRange) async throws -> [BudgetVsExpenseMonthlyRow]
}
/// 기존 BudgetRepository(+TransactionRepository) → BudgetQuerying 어댑터
/// - 예산 완전성 정책에 필요한 월별 예산 맵과 콤보(예산/지출) 시리즈를 제공합니다.
public final class BudgetRepositoryAdapter: BudgetQuerying {
    private let budgetRepo: BudgetRepository
    private let txRepo: TransactionRepository
    public init(budgetRepo: BudgetRepository, txRepo: TransactionRepository) {
        self.budgetRepo = budgetRepo
        self.txRepo = txRepo
    }
    
    public func fetchBudgets(range: DateRange) async throws -> [String: [YearMonth: Decimal]] {
        let yms = range.months()
        var map: [String: [YearMonth: Decimal]] = [:]
        for ym in yms {
            // 카테고리별 예산 포함 조회 API 사용 (없다면 fetchBudget → categoryBudgets 로 교체)
            guard let b = try await budgetRepo.fetchBudgetWithCategories(for: ym) else { continue }
            for cb in b.categoryBudgets { // NOTE: 실제 DTO 필드명에 맞게 수정
                var inner = map[cb.categoryID.uuidString] ?? [:]
                inner[ym] = cb.amount
                map[cb.categoryID.uuidString] = inner
            }
        }
        return map
    }
    
    public func fetchBudgetVsExpenseByMonth(range: DateRange) async throws -> [BudgetVsExpenseMonthlyRow] {
        let yms = range.months()
        var out: [BudgetVsExpenseMonthlyRow] = []
        for ym in yms {
            let monthStart = ym.startDate()
            let startDate = ym.startOfMonth
            let endDate = ym.endOfMonth
            let budget = try await budgetRepo.fetchBudget(for: ym)?.totalAmount ?? 0
            let totals = try await txRepo.getTotalAmountByType(from: startDate, to: endDate)
            let fixed   = totals.first(where: { $0.0 == .fixedExpense })?.1 ?? 0
            let variable = totals.first(where: { $0.0 == .variableExpense })?.1 ?? 0
            let expense = fixed + variable
            out.append(.init(monthStart: monthStart, budget: budget, expense: expense))
        }

        return out
    }
}
