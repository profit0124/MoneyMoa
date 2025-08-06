//
//  GetBudgetTemplateUseCase.swift
//  MoneyMoa
//
//  Created by Claude on 8/4/25.
//

import Foundation

// MARK: - GetBudgetTemplateUseCase

/// 예산 템플릿 조회 UseCase
public protocol GetBudgetTemplateUseCase {
    
    /// 현재 설정된 예산 템플릿을 조회합니다
    /// 
    /// - Returns: 예산 템플릿 (설정되지 않았으면 nil)
    /// 
    /// - Note: 
    ///   - 템플릿이 없으면 사용자가 예산 설정을 해야함
    ///   - 템플릿이 있으면 자동으로 월별 예산 생성 가능
    /// 
    /// - Example:
    ///   ```swift
    ///   let template = await useCase.execute()
    ///   
    ///   if let template = template {
    ///       // 템플릿 있음: 자동 예산 생성 가능
    ///   } else {
    ///       // 템플릿 없음: 사용자 설정 필요
    ///   }
    ///   ```
    func execute() async throws -> BudgetTemplateDTO?
}