//
//  MockUpdateBudgetUseCase.swift
//  MoneyMoa
//
//  Created by Claude on 8/22/25.
//

import Foundation

public struct MockUpdateBudgetUseCase: UpdateBudgetUseCase {
    
    public init() {}
    
    public func execute(for month: YearMonth, budget: BudgetDTO) async throws {
        // Mock implementation - 실제로는 아무것도 하지 않음
    }
}
