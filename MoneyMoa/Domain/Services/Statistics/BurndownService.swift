//
//  BurndownService.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/28/25.
//

import Foundation

// MARK: - BurndownService (월 예산 대비 누적 지출)
public protocol BurndownService {
    /// expected = (월예산 / 일수) * dayIndex
    func make(expectedMonthlyBudget: Decimal, dailyExpenses: [DailyPointDTO], calendar: Calendar) -> [BurndownPointDTO]
}

public struct BurndownServiceImpl: BurndownService {
    public init() {}
    public func make(expectedMonthlyBudget: Decimal, dailyExpenses: [DailyPointDTO], calendar: Calendar = Calendar.current) -> [BurndownPointDTO] {
        guard !dailyExpenses.isEmpty else { return [] }
        let sorted = dailyExpenses.sorted { $0.date < $1.date }
        let monthStart = calendar.startOfMonth(for: sorted[0].date)
        let monthEnd = calendar.endOfMonthExclusive(for: monthStart)
        let days = calendar.dateComponents([.day], from: monthStart, to: monthEnd).day ?? 30
        let expectedPerDay = expectedMonthlyBudget / Decimal(days)

        // 일자별 지출 합 → 누적
        var dayMap: [Int: Decimal] = [:]
        for p in sorted { dayMap[calendar.component(.day, from: p.date), default: 0] += p.amount }
        var actualCumulativeSpent: Decimal = 0
        var out: [BurndownPointDTO] = []
        
        for d in 1...days {
            actualCumulativeSpent += dayMap[d, default: 0]
            let dayDate = calendar.date(byAdding: .day, value: d - 1, to: monthStart) ?? monthStart
            
            // 누적 지출 계산
            let expectedCumulative = expectedPerDay * Decimal(d)
            let actualCumulative = actualCumulativeSpent
            
            out.append(.init(day: d,
                             date: dayDate,
                             expectedCumulative: expectedCumulative,
                             actualCumulative: actualCumulative,
                             monthlyBudget: expectedMonthlyBudget))
        }
        return out
    }
}
