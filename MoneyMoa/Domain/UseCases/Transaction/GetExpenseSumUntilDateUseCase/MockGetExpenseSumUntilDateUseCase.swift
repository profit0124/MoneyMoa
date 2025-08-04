//
//  MockGetExpenseSumUntilDateUseCase.swift
//  MoneyMoa
//
//  Created by Claude on 8/4/25.
//

import Foundation

// MARK: - MockGetExpenseSumUntilDateUseCase

public final class MockGetExpenseSumUntilDateUseCase: GetExpenseSumUntilDateUseCase {
    
    // MARK: - Mock Configuration
    
    /// Mock 지출 데이터 (연월별)
    private var mockExpenseData: [YearMonth: Decimal] = [:]
    
    /// Mock 일별 지출 패턴 (1일당 평균 지출)
    public var dailyAverageExpense: Decimal = Decimal(50_000) // 5만원/일
    
    /// Mock 딜레이 시뮬레이션 (나노초)
    public var mockDelay: UInt64 = 100_000_000 // 0.1초
    
    // MARK: - Initialization
    
    public init() {
        setupDefaultMockData()
    }
    
    // MARK: - UseCase Implementation
    
    public func execute(yearMonth: YearMonth, untilDay: Date = Date()) async throws -> Decimal {
        // Mock 딜레이 시뮬레이션
        try await Task.sleep(nanoseconds: mockDelay)
        
        let calendar = Calendar.current
        let targetYearMonth = YearMonth(from: untilDay)
        
        if yearMonth < targetYearMonth {
            // 과거 월인 경우: 해당 월 전체 지출
            return mockExpenseData[yearMonth] ?? calculateMockMonthlyExpense(for: yearMonth)
        } else {
            // 현재 월인 경우: 해당 일자까지의 지출
            let currentDay = calendar.component(.day, from: untilDay)
            let dailyExpense = mockExpenseData[yearMonth] ?? calculateMockMonthlyExpense(for: yearMonth)
            let daysInMonth = calendar.range(of: .day, in: .month, for: yearMonth.startOfMonth)?.count ?? 30
            
            // 일별 평균으로 계산
            let averageDailyExpense = dailyExpense / Decimal(daysInMonth)
            return averageDailyExpense * Decimal(currentDay)
        }
    }
    
    // MARK: - Mock Configuration Methods
    
    /// 특정 연월의 Mock 지출 데이터를 설정합니다
    public func setMockExpense(for yearMonth: YearMonth, amount: Decimal) {
        mockExpenseData[yearMonth] = amount
    }
    
    /// 여러 연월의 Mock 지출 데이터를 일괄 설정합니다
    public func setMockExpenses(_ expenses: [YearMonth: Decimal]) {
        mockExpenseData = expenses
    }
    
    /// Mock 데이터를 초기화합니다
    public func clearMockData() {
        mockExpenseData.removeAll()
    }
    
    /// 일별 평균 지출을 설정합니다
    public func setDailyAverageExpense(_ amount: Decimal) {
        dailyAverageExpense = amount
    }
    
    /// Mock 딜레이를 설정합니다
    public func setMockDelay(nanoseconds: UInt64) {
        mockDelay = nanoseconds
    }
    
    // MARK: - Preset Scenarios
    
    /// 일반적인 지출 시나리오를 설정합니다
    public func configureNormalExpenseScenario() {
        let currentDate = Date()
        let currentYearMonth = YearMonth.current
        let previousYearMonth = currentYearMonth.previousMonth()
        
        setMockExpense(for: currentYearMonth, amount: Decimal(1_500_000))     // 이번 달: 150만원
        setMockExpense(for: previousYearMonth, amount: Decimal(1_200_000))    // 지난 달: 120만원
        setDailyAverageExpense(Decimal(50_000))                               // 일평균: 5만원
    }
    
    /// 고지출 시나리오를 설정합니다
    public func configureHighExpenseScenario() {
        let currentDate = Date()
        let currentYearMonth = YearMonth.current
        let previousYearMonth = currentYearMonth.previousMonth()
        
        setMockExpense(for: currentYearMonth, amount: Decimal(2_800_000))     // 이번 달: 280만원
        setMockExpense(for: previousYearMonth, amount: Decimal(2_200_000))    // 지난 달: 220만원
        setDailyAverageExpense(Decimal(90_000))                               // 일평균: 9만원
    }
    
    /// 저지출 시나리오를 설정합니다
    public func configureLowExpenseScenario() {
        let currentDate = Date()
        let currentYearMonth = YearMonth.current
        let previousYearMonth = currentYearMonth.previousMonth()
        
        setMockExpense(for: currentYearMonth, amount: Decimal(800_000))       // 이번 달: 80만원
        setMockExpense(for: previousYearMonth, amount: Decimal(750_000))      // 지난 달: 75만원
        setDailyAverageExpense(Decimal(25_000))                               // 일평균: 2.5만원
    }
    
    // MARK: - Private Helper Methods
    
    /// 기본 Mock 데이터를 설정합니다
    private func setupDefaultMockData() {
        configureNormalExpenseScenario()
    }
    
    /// 특정 연월의 Mock 월별 지출을 계산합니다
    private func calculateMockMonthlyExpense(for yearMonth: YearMonth) -> Decimal {
        let calendar = Calendar.current
        let daysInMonth = calendar.range(of: .day, in: .month, for: yearMonth.startOfMonth)?.count ?? 30
        return dailyAverageExpense * Decimal(daysInMonth)
    }
}
