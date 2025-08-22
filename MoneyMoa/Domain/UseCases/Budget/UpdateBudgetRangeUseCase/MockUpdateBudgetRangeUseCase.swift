//
//  MockUpdateBudgetRangeUseCase.swift
//  MoneyMoa
//
//  Created by Claude on 8/22/25.
//

import Foundation

public struct MockUpdateBudgetRangeUseCase: UpdateBudgetRangeUseCase {
    
    public init() {}
    
    public func execute(from startMonth: YearMonth, budget: BudgetDTO) async throws {
        // Mock implementation: 범위 예산 업데이트를 시뮬레이션
        
        // 약간의 지연을 시뮬레이션
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5초
        
        let currentMonth = YearMonth.current
        let monthCount = monthsBetween(from: startMonth, to: currentMonth) + 1
        
        print("Mock: Updated budgets from \(startMonth) to \(currentMonth) (\(monthCount) months)")
        print("Mock: Total amount: \(budget.totalAmount), Categories: \(budget.categoryBudgets.count)")
    }
    
    private func monthsBetween(from start: YearMonth, to end: YearMonth) -> Int {
        var count = 0
        var current = start
        while current <= end {
            count += 1
            current = current.nextMonth()
        }
        return count - 1 // 시작월 제외
    }
}
