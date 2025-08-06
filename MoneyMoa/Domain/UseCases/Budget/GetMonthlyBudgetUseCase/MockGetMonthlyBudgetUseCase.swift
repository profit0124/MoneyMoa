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
        let currentMonth = YearMonth.current
        let previousMonth = currentMonth.previousMonth()
        
        // 현재 월 예산 (300만원)
        let currentBudget = BudgetDTO(
            month: currentMonth,
            totalAmount: Decimal(3_000_000),
            categoryBudgets: [
                CategoryBudgetDTO(
                    amount: Decimal(800_000),
                    categoryID: UUID(),
                    categoryName: "식비",
                    budgetId: UUID()
                ),
                CategoryBudgetDTO(
                    amount: Decimal(500_000),
                    categoryID: UUID(),
                    categoryName: "교통비",
                    budgetId: UUID()
                ),
                CategoryBudgetDTO(
                    amount: Decimal(1_700_000),
                    categoryID: UUID(),
                    categoryName: "기타",
                    budgetId: UUID()
                )
            ]
        )
        
        // 전월 예산 (280만원)
        let previousBudget = BudgetDTO(
            month: previousMonth,
            totalAmount: Decimal(2_800_000),
            categoryBudgets: []
        )
        
        setMockBudget(currentBudget)
        setMockBudget(previousBudget)
    }
    
    // MARK: - UseCase Implementation
    
    public func execute(yearMonth: YearMonth) async throws -> BudgetDTO? {
        // Mock 딜레이 시뮬레이션
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1초
        
        return mockBudgets[yearMonth]
    }
}