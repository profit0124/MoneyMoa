//
//  MockUpdateBudgetTemplateUseCase.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/22/25.
//

import Foundation

public struct MockUpdateTemplateFromBudgetUseCase: UpdateTemplateFromBudgetUseCase {

    public init() {}
    
    public func execute(_ budget: BudgetDTO) async throws {
        // Mock implementation: 템플릿 업데이트를 시뮬레이션
        // 실제로는 BudgetRepository에서 기존 템플릿을 업데이트하지만, Mock에서는 아무것도 하지 않음
        
        // 약간의 지연을 시뮬레이션
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5초
        
        // 성공적으로 완료됨을 표시
        print("Mock: Budget Template updated from Budget with totalAmount: \(budget.totalAmount), categoryBudgets count: \(budget.categoryBudgets.count)")
    }
}
