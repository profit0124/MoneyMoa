//
//  CreateBudgetUseCaseImpl.swift
//  MoneyMoa
//
//  Created by Claude on 8/22/25.
//

import Foundation

public struct CreateBudgetUseCaseImpl: CreateBudgetUseCase {
    
    private let budgetRepository: BudgetWriter

    public init(budgetRepository: BudgetWriter) {
        self.budgetRepository = budgetRepository
    }
    
    public func execute(_ budget: BudgetDTO) async throws -> BudgetDTO {
        return try await budgetRepository.createBudget(budget)
    }
}
