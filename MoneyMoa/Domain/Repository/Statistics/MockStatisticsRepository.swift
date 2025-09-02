//
//  MockStatisticsRepository.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/28/25.
//

import Foundation
import SwiftUI

/// 프리뷰/테스트용 Mock 구현
/// - 실제 SwiftData/네트워크 연동 전, UI/로직 검증에 사용합니다.
public final class MockStatisticsRepository: StatisticsRepository {
    public init() {}

    public func fetchMonthlyTotals(range: DateRange) async throws -> [MonthlyPointDTO] {
        let cal = KST.calendar
        let months = cal.yearMonths(in: range)
        var result: [MonthlyPointDTO] = []
        
        for (index, ym) in months.enumerated() {
            let baseIncome = Decimal(2_000_000)
            let baseExpense = Decimal(1_200_000)
            
            // 월별 약간의 변동 추가
            let incomeVariation = Decimal(Int.random(in: -200_000...300_000))
            let expenseVariation = Decimal(Int.random(in: -150_000...200_000))
            
            let income = baseIncome + incomeVariation
            let expense = baseExpense + expenseVariation
            let netIncome = income - expense
            let savingsRate = income > 0 ? Double(truncating: (netIncome / income) as NSDecimalNumber) * 100 : 0
            
            // 전월 대비 변화율 계산
            let previousMonthChange: Double
            if index > 0, let previousNetIncome = result.last?.netIncome, previousNetIncome != 0 {
                let changeRate = Double(truncating: ((netIncome - previousNetIncome) / previousNetIncome) as NSDecimalNumber) * 100
                previousMonthChange = changeRate
            } else {
                previousMonthChange = 0.0
            }
            
            result.append(MonthlyPointDTO(
                monthStart: ym.startDate(calendar: cal),
                income: income,
                expense: expense,
                savingsRate: savingsRate,
                previousMonthChange: previousMonthChange
            ))
        }
        
        return result
    }

    public func fetchDailyExpenses(range: DateRange) async throws -> [DailyPointDTO] {
        let cal = KST.calendar
        var out: [DailyPointDTO] = []
        var cursor = cal.startOfMonth(for: range.start)
        let end = range.end
        
        while cursor < end {
            let isWeekend = cal.isDateInWeekend(cursor)
            let baseAmount = isWeekend ? Decimal(120_000) : Decimal(80_000)
            let variation = Decimal(Int.random(in: -30_000...50_000))
            let amount = max(0, baseAmount + variation)
            
            // 7일 이동평균 계산
            let movingAverage: Decimal
            if out.count >= 6 {
                let last6Days = Array(out.suffix(6))
                let sum = last6Days.reduce(amount) { $0 + $1.amount }
                movingAverage = sum / 7
            } else {
                let sum = out.reduce(amount) { $0 + $1.amount }
                movingAverage = sum / Decimal(out.count + 1)
            }
            
            out.append(DailyPointDTO(
                date: cursor,
                amount: amount,
                movingAverage: movingAverage,
                isWeekend: isWeekend
            ))
            
            cursor = cal.date(byAdding: .day, value: 1, to: cursor)!
        }
        return out
    }

    public func fetchCategoryExpenseByMonth(range: DateRange) async throws -> [CategoryMonthlyPointDTO] {
        let cal = KST.calendar
        let months = cal.yearMonths(in: range)
        let cats = [
            ("food", "식비"),
            ("shop", "쇼핑"),
            ("health", "건강"),
            ("transport", "교통"),
            ("culture", "문화")
        ]
        
        return months.flatMap { ym in
            cats.enumerated().map { index, (id, name) in
                let color = StatisticsColorScheme.categoryColor(at: index)
                return CategoryMonthlyPointDTO(
                    categoryId: id,
                    categoryName: name,
                    monthStart: ym.startDate(calendar: cal),
                    expense: Decimal(Int.random(in: 200_000...800_000)),
                    color: color
                )
            }
        }
    }

    public func fetchPaymentMethodStats(range: DateRange) async throws -> [PaymentMethodRatioDTO] {
        [
            PaymentMethodRatioDTO(
                methodId: "card",
                methodName: "카드",
                ratio: 0.6,
                amount: 1_800_000,
                count: 42,
                color: StatisticsColorScheme.paymentMethodColor(at: 0)
            ),
            PaymentMethodRatioDTO(
                methodId: "cash",
                methodName: "현금",
                ratio: 0.3,
                amount: 900_000,
                count: 20,
                color: StatisticsColorScheme.paymentMethodColor(at: 1)
            ),
            PaymentMethodRatioDTO(
                methodId: "transfer",
                methodName: "이체",
                ratio: 0.1,
                amount: 300_000,
                count: 7,
                color: StatisticsColorScheme.paymentMethodColor(at: 2)
            )
        ]
    }

    public func fetchTransactionTypeRatio(range: DateRange) async throws -> TransactionTypeRatioDTO {
        .init(income: 0.35, expense: 0.6)
    }

    public func fetchMerchantRanking(range: DateRange) async throws -> MerchantRankingDTO {
        .init(entries: [
            .init(rank: 1,
                  merchant: "쿠팡",
                  count: 12,
                  total: 550_000),
            .init(rank: 2,
                  merchant: "스타벅스",
                  count: 18,
                  total: 210_000),
            .init(rank: 3,
                  merchant: "배달의민족",
                  count: 9,
                  total: 180_000),
            .init(rank: 4,
                  merchant: "네이버페이",
                  count: 6,
                  total: 170_000),
            .init(rank: 5,
                  merchant: "이마트",
                  count: 4,
                  total: 160_000)
        ])
    }

    public func fetchBudgetsByCategory(range: DateRange) async throws -> [String: [YearMonth: Decimal]] {
        // 정책 테스트 목적: 식비는 모든 월 예산 존재, 쇼핑은 일부 월만, 건강은 2개월만
        let cal = KST.calendar
        let months = cal.yearMonths(in: range)
        var map: [String: [YearMonth: Decimal]] = [:]
        map["food"] = Dictionary(uniqueKeysWithValues: months.map { ($0, 800_000) })
        map["shop"] = [months.first!: 500_000]
        if months.count >= 2 { map["health"] = [months[0]: 300_000, months[1]: 300_000] }
        return map
    }

    public func fetchBudgetVsExpenseByMonth(range: DateRange) async throws -> [BudgetVsExpenseDTO] {
        let cal = KST.calendar
        return cal.yearMonths(in: range).map { ym in
            .init(monthStart: ym.startDate(calendar: cal), budget: 2_500_000, expense: 2_200_000)
        }
    }
}
