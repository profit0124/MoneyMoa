//
//  UpdateBudgetUseCaseImpl.swift
//  MoneyMoa
//
//  Created by Claude on 8/22/25.
//

import Foundation

public struct UpdateBudgetUseCaseImpl: UpdateBudgetUseCase {
    
    private let budgetRepository: BudgetRepository
    
    public init(budgetRepository: BudgetRepository) {
        self.budgetRepository = budgetRepository
    }
    
    public func execute(for month: YearMonth, budget: BudgetDTO) async throws {
        try await budgetRepository.updateBudget(for: month, budget: budget)
    }
}
