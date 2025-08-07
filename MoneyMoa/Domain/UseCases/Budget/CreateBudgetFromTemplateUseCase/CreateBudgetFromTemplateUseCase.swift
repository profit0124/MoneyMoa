//
//  CreateBudgetFromTemplateUseCase.swift
//  MoneyMoa
//
//  Created by Claude on 8/4/25.
//

import Foundation

// MARK: - CreateBudgetFromTemplateUseCase

/// 템플릿을 기반으로 특정 월에 예산을 생성하는 UseCase
public protocol CreateBudgetFromTemplateUseCase {
    
    /// 템플릿을 기반으로 특정 월에 예산을 생성합니다
    /// 
    /// - Parameters:
    ///   - template: 기준이 될 예산 템플릿
    ///   - yearMonth: 예산을 생성할 연월
    /// 
    /// - Returns: 생성된 예산 정보
    /// 
    /// - Note: 
    ///   - 템플릿의 총액과 카테고리별 예산을 복사하여 해당 월 예산 생성
    ///   - 이미 해당 월 예산이 있으면 덮어쓰기 됨
    /// 
    /// - Example:
    ///   ```swift
    ///   let template = BudgetTemplateDTO(totalAmount: 2_000_000, ...)
    ///   let budget = await useCase.execute(
    ///       template: template,
    ///       yearMonth: YearMonth(year: 2024, month: 8)
    ///   )
    ///   ```
    func execute(template: BudgetTemplateDTO, yearMonth: YearMonth) async throws -> BudgetDTO
}
