//
//  CreateBudgetUseCase.swift
//  MoneyMoa
//
//  Created by Claude on 8/22/25.
//

import Foundation

public protocol CreateBudgetUseCase {
    /// 새로운 예산을 생성합니다
    /// - Parameters:
    ///   - budget: 생성할 예산 정보 (BudgetDTO)
    /// - Returns: 생성된 예산 DTO
    func execute(_ budget: BudgetDTO) async throws -> BudgetDTO
}
