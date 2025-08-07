//
//  GetMonthlyBudgetUseCase.swift
//  MoneyMoa
//
//  Created by Claude on 8/4/25.
//

import Foundation

// MARK: - GetMonthlyBudgetUseCase

/// 특정 월의 예산 정보를 조회하는 UseCase
public protocol GetMonthlyBudgetUseCase {
    
    /// 특정 월의 예산 정보를 조회합니다
    /// - Parameter yearMonth: 조회할 연월
    /// - Returns: 해당 월의 예산 정보, 설정되지 않았으면 nil
    func execute(yearMonth: YearMonth) async throws -> BudgetDTO?
}
