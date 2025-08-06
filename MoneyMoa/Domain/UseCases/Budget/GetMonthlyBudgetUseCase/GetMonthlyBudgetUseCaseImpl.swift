//
//  GetMonthlyBudgetUseCaseImpl.swift
//  MoneyMoa
//
//  Created by Claude on 8/4/25.
//

import Foundation

// MARK: - GetMonthlyBudgetUseCaseImpl

public final class GetMonthlyBudgetUseCaseImpl: GetMonthlyBudgetUseCase {
    
    // MARK: - Dependencies
    
    private let budgetRepository: BudgetRepository
    
    // MARK: - Initialization
    
    public init(budgetRepository: BudgetRepository) {
        self.budgetRepository = budgetRepository
    }
    
    // MARK: - Public Methods
    
    public func execute(yearMonth: YearMonth) async throws -> BudgetDTO? {
        return try await budgetRepository.fetchBudget(for: yearMonth)
    }
}