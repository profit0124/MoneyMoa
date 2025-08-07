//
//  MockGetMonthlyBudgetUseCase.swift
//  MoneyMoa
//
//  Created by Claude on 8/4/25.
//

import Foundation

// MARK: - MockGetMonthlyBudgetUseCase

public final class MockGetMonthlyBudgetUseCase: GetMonthlyBudgetUseCase {
    
    // MARK: - Mock Data
    
    private var mockBudgets: [YearMonth: BudgetDTO] = [:]
    
    // MARK: - Mock Configuration
    
    /// Mock 예산 데이터를 설정합니다
    public func setMockBudget(_ budget: BudgetDTO) {
        mockBudgets[budget.month] = budget
    }
    
    /// 모든 Mock 데이터를 초기화합니다
    public func clearMockData() {
        mockBudgets.removeAll()
    }
    
    /// 기본 Mock 데이터를 설정합니다 (테스트 및 개발용)
    public func setupDefaultMockData() {
        setMockBudget(.mockCurrent)
        setMockBudget(.mockPrevious)
    }
    
    // MARK: - UseCase Implementation
    
    public func execute(yearMonth: YearMonth) async throws -> BudgetDTO? {
        // Mock 딜레이 시뮬레이션
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1초
        
        return mockBudgets[yearMonth]
    }
}
