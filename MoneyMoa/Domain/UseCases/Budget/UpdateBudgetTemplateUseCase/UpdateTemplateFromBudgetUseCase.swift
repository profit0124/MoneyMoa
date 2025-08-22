//
//  UpdateBudgetTemplateUseCase.swift
//  MoneyMoa
//
//  Created by Claude on 8/22/25.
//

import Foundation

public protocol UpdateTemplateFromBudgetUseCase {
    /// 기존 예산 템플릿을 업데이트합니다
    /// - Parameter template: 업데이트할 예산 템플릿 정보
    /// - Returns: 업데이트된 예산 템플릿 DTO
    func execute(_ budget: BudgetDTO) async throws
}
