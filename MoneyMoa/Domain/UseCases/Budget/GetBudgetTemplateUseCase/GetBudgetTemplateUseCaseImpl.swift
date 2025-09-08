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
    
    private let repo: BudgetTemplateReader

    // MARK: - Initialization
    
    public init(repo: BudgetTemplateReader) {
        self.repo = repo
    }
    
    // MARK: - UseCase Methods
    
    public func execute() async throws -> BudgetTemplateDTO? {
        return try await repo.fetchBudgetTemplateWithCategories()
    }
}
