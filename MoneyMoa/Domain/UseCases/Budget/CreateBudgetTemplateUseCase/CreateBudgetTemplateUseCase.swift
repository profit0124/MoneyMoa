//
//  CreateBudgetTemplateUseCase.swift
//  MoneyMoa
//
//  Created by Claude on 8/22/25.
//

import Foundation

public protocol CreateBudgetTemplateUseCase {
    /// 새로운 예산 템플릿을 생성합니다
    /// - Parameter template: 생성할 예산 템플릿 정보
    /// - Returns: 생성된 예산 템플릿 DTO
    func execute(_ template: BudgetTemplateDTO) async throws -> BudgetTemplateDTO
}
