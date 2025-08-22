//
//  MockCreateBudgetUseCase.swift
//  MoneyMoa
//
//  Created by Claude on 8/22/25.
//

import Foundation

public struct MockCreateBudgetUseCase: CreateBudgetUseCase {
    
    public init() {}
    
    public func execute(_ budget: BudgetDTO) async throws -> BudgetDTO {
        // Mock implementation: 예산 생성을 시뮬레이션
        
        // 약간의 지연을 시뮬레이션
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5초
        
        // 입력받은 budget에 생성된 ID를 부여하여 반환
        let createdBudget = BudgetDTO(
            id: UUID(),
            month: budget.month,
            totalAmount: budget.totalAmount,
            categoryBudgets: budget.categoryBudgets
        )
        
        print("Mock: Budget created for month: \(budget.month), totalAmount: \(budget.totalAmount)")
        
        return createdBudget
    }
}
