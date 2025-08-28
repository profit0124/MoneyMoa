//
//  BudgetCompletenessService.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/28/25.
//

import Foundation

// MARK: - BudgetCompletenessService (모든 선택 월에 예산 존재하는 카테고리만)
public protocol BudgetCompletenessService { func completeCategories(budgets: [String: [YearMonth: Decimal]], months: [YearMonth]) -> Set<String> }

public struct BudgetCompletenessServiceImpl: BudgetCompletenessService {
    public init() {}
    public func completeCategories(budgets: [String: [YearMonth: Decimal]], months: [YearMonth]) -> Set<String> {
        guard !months.isEmpty else { return [] }
        let required = Set(months)
        var ok: Set<String> = []
        for (cat, map) in budgets where required.isSubset(of: Set(map.keys)) {
            ok.insert(cat)
        }
        return ok
    }
}
