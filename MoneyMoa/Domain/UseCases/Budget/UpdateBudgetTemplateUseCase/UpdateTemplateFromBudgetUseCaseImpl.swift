//
//  UpdateBudgetTemplateUseCaseImpl.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/22/25.
//

import Foundation

public struct UpdateTemplateFromBudgetUseCaseImpl: UpdateTemplateFromBudgetUseCase {
    
    private let budgetRepository: BudgetRepository
    
    public init(budgetRepository: BudgetRepository) {
        self.budgetRepository = budgetRepository
    }
    
    public func execute(_ budget: BudgetDTO) async throws {
        try await budgetRepository.updateBudgetTemplate(budget.toBudgetTemplateDTO())
    }
}
