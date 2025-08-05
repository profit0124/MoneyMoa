//
//  MockCreateBudgetFromTemplateUseCase.swift
//  MoneyMoa
//
//  Created by Claude on 8/4/25.
//

import Foundation

// MARK: - MockCreateBudgetFromTemplateUseCase

public final class MockCreateBudgetFromTemplateUseCase: CreateBudgetFromTemplateUseCase {
    
    // MARK: - Mock Configuration
    
    /// Mock 딜레이 시뮬레이션 (나노초)
    public var mockDelay: UInt64 = 100_000_000 // 0.1초
    
    /// Mock 생성 실패 시뮬레이션
    public var shouldFail: Bool = false
    
    /// Mock 에러
    public var mockError: Error = RepositoryError.budgetNotFound
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - UseCase Implementation
    
    public func execute(template: BudgetTemplateDTO, yearMonth: YearMonth) async throws -> BudgetDTO {
        // Mock 딜레이 시뮬레이션
        try await Task.sleep(nanoseconds: mockDelay)
        
        // Mock 실패 시뮬레이션
        if shouldFail {
            throw mockError
        }
        
        // 템플릿을 기반으로 Mock Budget 생성
        let categoryBudgets = template.categoryBudgetTemplates.map { templateBudget in
            CategoryBudgetDTO(
                amount: templateBudget.amount,
                categoryID: templateBudget.categoryID,
                categoryName: templateBudget.categoryName,
                budgetId: UUID() // Mock에서는 새로운 UUID 생성
            )
        }
        
        return BudgetDTO(
            month: yearMonth,
            totalAmount: template.totalAmount,
            categoryBudgets: categoryBudgets
        )
    }
    
    // MARK: - Mock Configuration Methods
    
    /// Mock 딜레이를 설정합니다
    public func setMockDelay(nanoseconds: UInt64) {
        mockDelay = nanoseconds
    }
    
    /// 실패 시나리오를 설정합니다
    public func configureFailureScenario(error: Error = RepositoryError.budgetNotFound) {
        shouldFail = true
        mockError = error
    }
    
    /// 성공 시나리오를 설정합니다
    public func configureSuccessScenario() {
        shouldFail = false
    }
}