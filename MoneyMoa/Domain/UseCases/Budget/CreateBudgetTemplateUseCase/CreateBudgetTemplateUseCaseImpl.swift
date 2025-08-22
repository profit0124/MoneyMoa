//
//  CreateBudgetTemplateUseCaseImpl.swift
//  MoneyMoa
//
//  Created by Claude on 8/22/25.
//

import Foundation

public struct CreateBudgetTemplateUseCaseImpl: CreateBudgetTemplateUseCase {
    
    private let budgetRepository: BudgetRepository
    
    public init(budgetRepository: BudgetRepository) {
        self.budgetRepository = budgetRepository
    }
    
    public func execute(_ template: BudgetTemplateDTO) async throws -> BudgetTemplateDTO {
        return try await budgetRepository.createBudgetTemplate(template)
    }
}
