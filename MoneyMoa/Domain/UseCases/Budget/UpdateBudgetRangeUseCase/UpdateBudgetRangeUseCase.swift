//
//  UpdateBudgetRangeUseCase.swift
//  MoneyMoa
//
//  Created by Claude on 8/22/25.
//

import Foundation

public protocol UpdateBudgetRangeUseCase {
    /// 특정 월부터 현재 월까지의 예산을 일괄 업데이트합니다
    /// - Parameters:
    ///   - startMonth: 시작 연월
    ///   - budget: 업데이트할 예산 정보 (템플릿 기준)
    func execute(from startMonth: YearMonth, budget: BudgetDTO) async throws
}
