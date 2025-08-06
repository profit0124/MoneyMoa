//
//  MockDIContainer.swift
//  MoneyMoa
//
//  Created by Claude on 8/5/25.
//

import Foundation

// MARK: - MockDIContainer

/// Mock 구현체들을 제공하는 DI 컨테이너
/// Presentation Layer 개발 및 테스트 시 사용됩니다
final class MockDIContainer: DIContainer {
    
    // MARK: - UseCase Factory Methods
    
    /// Mock GetMonthlyTransactionsUseCase를 생성합니다
    func makeGetMonthlyTransactionsUseCase() -> GetMonthlyTransactionsUseCase {
        return MockGetMonthlyTransactionsUseCase()
    }
    
    /// Mock GetExpenseSumUntilDateUseCase를 생성합니다
    func makeGetExpenseSumUntilDateUseCase() -> GetExpenseSumUntilDateUseCase {
        return MockGetExpenseSumUntilDateUseCase()
    }
    
    /// Mock GetMonthlyBudgetUseCase를 생성합니다
    func makeGetMonthlyBudgetUseCase() -> GetMonthlyBudgetUseCase {
        return MockGetMonthlyBudgetUseCase()
    }
    
    /// Mock GetBudgetTemplateUseCase를 생성합니다
    func makeGetBudgetTemplateUseCase() -> GetBudgetTemplateUseCase {
        return MockGetBudgetTemplateUseCase()
    }
    
    /// Mock CreateBudgetFromTemplateUseCase를 생성합니다
    func makeCreateBudgetFromTemplateUseCase() -> CreateBudgetFromTemplateUseCase {
        return MockCreateBudgetFromTemplateUseCase()
    }
}