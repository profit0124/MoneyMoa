//
//  SummaryDisplayData.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/7/25.
//

import Foundation

// MARK: - SummaryDisplayData

/// Summary Section에 표시할 데이터 구조
public struct SummaryDisplayData: Sendable, Equatable {
    
    // MARK: - Core Data
    
    /// 현재 월 지출 총액 (현재 날짜까지)
    public let currentMonthExpense: Decimal
    
    /// 전월 지출 총액 (같은 날짜까지)
    public let previousMonthExpense: Decimal
    
    /// 전월 대비 증감 금액 (전월 데이터가 없으면 nil)
    public let monthlyComparison: Decimal?
    
    /// 전월 대비 증감률 (-1.0 ~ 1.0+, 전월 데이터가 없으면 nil)
    public let comparisonPercentage: Double?
    
    /// 전월 데이터 존재 여부
    public let hasPreviousMonthData: Bool
    
    // MARK: - Budget Data (Optional)
    
    /// 예산 정보 (없으면 nil)
    public let budget: BudgetDTO?
    
    /// 예산 잔여 금액 (없으면 nil)
    public let remainingBudget: Decimal?
    
    /// 예산 사용률 (0.0 ~ 1.0+, 없으면 nil)
    public let budgetUsagePercentage: Double?
    
    // MARK: - Initializer
    
    public init(
        currentMonthExpense: Decimal,
        previousMonthExpense: Decimal,
        monthlyComparison: Decimal? = nil,
        comparisonPercentage: Double? = nil,
        hasPreviousMonthData: Bool,
        budget: BudgetDTO? = nil,
        remainingBudget: Decimal? = nil,
        budgetUsagePercentage: Double? = nil
    ) {
        self.currentMonthExpense = currentMonthExpense
        self.previousMonthExpense = previousMonthExpense
        self.monthlyComparison = monthlyComparison
        self.comparisonPercentage = comparisonPercentage
        self.hasPreviousMonthData = hasPreviousMonthData
        self.budget = budget
        self.remainingBudget = remainingBudget
        self.budgetUsagePercentage = budgetUsagePercentage
    }
    
    // MARK: - Computed Properties
    
    /// 예산이 설정되어 있는지 여부
    public var hasBudget: Bool {
        budget != nil
    }
    
    /// 예산을 초과했는지 여부
    public var isBudgetExceeded: Bool {
        guard let budget = budget else { return false }
        return currentMonthExpense > budget.totalAmount
    }
    
    /// 전월 대비 지출이 증가했는지 여부
    public var isExpenseIncreased: Bool {
        guard let comparison = monthlyComparison else { return false }
        return comparison > 0
    }
    
    /// 전월 대비 지출이 감소했는지 여부
    public var isExpenseDecreased: Bool {
        guard let comparison = monthlyComparison else { return false }
        return comparison < 0
    }
    
    /// 전월과 지출이 동일한지 여부
    public var isExpenseUnchanged: Bool {
        guard let comparison = monthlyComparison else { return false }
        return comparison == 0
    }
    
    /// 전월 비교 데이터를 표시할 수 있는지 여부
    public var canShowComparison: Bool {
        hasPreviousMonthData && previousMonthExpense > 0
    }
}
