//
//  GetBudgetTemplateUseCaseImpl.swift
//  MoneyMoa
//
//  Created by Claude on 8/4/25.
//

import Foundation

// MARK: - GetBudgetTemplateUseCaseImpl

public class GetBudgetTemplateUseCaseImpl: GetBudgetTemplateUseCase {
    
    // MARK: - Properties
    
    private let budgetRepository: BudgetRepository
    
    // MARK: - Initialization
    
    public init(budgetRepository: BudgetRepository) {
        self.budgetRepository = budgetRepository
    }
    
    // MARK: - UseCase Methods
    
    public func execute() async throws -> BudgetTemplateDTO? {
        return try await budgetRepository.fetchBudgetTemplateWithCategories()
    }
}