//
//  MockCreateBudgetTemplateUseCase.swift
//  MoneyMoa
//
//  Created by Claude on 8/22/25.
//

import Foundation

public struct MockCreateBudgetTemplateUseCase: CreateBudgetTemplateUseCase {
    
    public init() {}
    
    public func execute(_ template: BudgetTemplateDTO) async throws -> BudgetTemplateDTO {
        // Mock implementation - 입력받은 템플릿을 그대로 반환
        return template
    }
}
