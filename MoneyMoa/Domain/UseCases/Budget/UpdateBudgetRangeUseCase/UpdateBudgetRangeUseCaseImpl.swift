//
//  UpdateBudgetRangeUseCaseImpl.swift
//  MoneyMoa
//
//  Created by Claude on 8/22/25.
//

import Foundation

public struct UpdateBudgetRangeUseCaseImpl: UpdateBudgetRangeUseCase {
    
    private let budgetRepository: BudgetRepository
    
    public init(budgetRepository: BudgetRepository) {
        self.budgetRepository = budgetRepository
    }
    
    public func execute(from startMonth: YearMonth, budget: BudgetDTO) async throws {
        let currentMonth = YearMonth.current
        var targetMonth = startMonth
        
        // 시작 월부터 현재 월까지 모든 예산 업데이트
        while targetMonth <= currentMonth {
            let budgetForMonth = BudgetDTO(
                id: UUID(), // 각 월마다 새로운 ID 생성
                month: targetMonth,
                totalAmount: budget.totalAmount,
                categoryBudgets: budget.categoryBudgets.map { categoryBudget in
                    CategoryBudgetDTO(
                        id: UUID(),
                        amount: categoryBudget.amount,
                        categoryID: categoryBudget.categoryID,
                        categoryName: categoryBudget.categoryName,
                        budgetId: UUID()
                    )
                }
            )
            
            try await budgetRepository.updateBudget(for: targetMonth, budget: budgetForMonth)
            targetMonth = targetMonth.nextMonth()
        }
    }
}
