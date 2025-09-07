//
//  CreateTemplateFromBudgetUseCaseImpl.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/22/25.
//

import Foundation

public struct CreateTemplateFromBudgetUseCaseImpl: CreateTemplateFromBudgetUseCase {

    private let repo: BudgetTemplateWriter

    public init(repo: BudgetTemplateWriter) {
        self.repo = repo
    }
    
    public func execute(_ budget: BudgetDTO) async throws {
        try await repo.createBudgetTemplate(budget.toBudgetTemplateDTO())
    }
}
