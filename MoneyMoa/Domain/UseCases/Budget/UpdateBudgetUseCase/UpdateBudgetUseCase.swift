//
//  UpdateBudgetUseCase.swift
//  MoneyMoa
//
//  Created by Claude on 8/22/25.
//

import Foundation

public protocol UpdateBudgetUseCase {
    /// 특정 월의 예산을 업데이트합니다
    /// - Parameters:
    ///   - month: 업데이트할 연월
    ///   - budget: 업데이트할 예산 정보
    func execute(for month: YearMonth, budget: BudgetDTO) async throws
}
