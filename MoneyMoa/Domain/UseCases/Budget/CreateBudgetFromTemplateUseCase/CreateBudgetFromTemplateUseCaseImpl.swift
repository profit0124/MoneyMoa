//
//  CreateBudgetFromTemplateUseCaseImpl.swift
//  MoneyMoa
//
//  Created by Claude on 8/4/25.
//

import Foundation

// MARK: - CreateBudgetFromTemplateUseCaseImpl

public class CreateBudgetFromTemplateUseCaseImpl: CreateBudgetFromTemplateUseCase {
    
    // MARK: - Properties
    
    private let budgetRepository: BudgetRepository
    
    // MARK: - Initialization
    
    public init(budgetRepository: BudgetRepository) {
        self.budgetRepository = budgetRepository
    }
    
    // MARK: - UseCase Methods
    
    public func execute(template: BudgetTemplateDTO, yearMonth: YearMonth) async throws -> BudgetDTO {
        
        // 템플릿의 카테고리별 예산을 해당 월 예산의 카테고리별 예산으로 변환
        let categoryBudgets = template.categoryBudgetTemplates.map { templateBudget in
            CategoryBudgetDTO(
                amount: templateBudget.amount,
                categoryID: templateBudget.categoryID,
                categoryName: templateBudget.categoryName,
                budgetId: UUID() // 새로운 Budget ID (임시, 저장 시 실제 ID로 대체됨)
            )
        }
        
        // 새 예산 생성
        let newBudget = BudgetDTO(
            month: yearMonth,
            totalAmount: template.totalAmount,
            categoryBudgets: categoryBudgets
        )
        
        // Repository를 통해 예산 저장
        try await budgetRepository.updateBudget(for: yearMonth, budget: newBudget)
        
        // 저장된 예산 다시 조회하여 반환 (실제 DB ID 포함)
        guard let savedBudget = try await budgetRepository.fetchBudgetWithCategories(for: yearMonth) else {
            throw RepositoryError.budgetNotFound
        }
        
        return savedBudget
    }
}