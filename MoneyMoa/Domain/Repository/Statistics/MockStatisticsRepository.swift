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
        return OverviewPreviewData.monthlyPoints
    }

    public func fetchDailyExpenses(range: DateRange) async throws -> [DailyPointDTO] {
        return OverviewPreviewData.dailyPoints
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
            cats.enumerated().map { (index, catData) in
                let (id, name) = catData
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
        return PaymentPreviewData.paymentMethodRatios
    }

    public func fetchTransactionTypeRatio(range: DateRange) async throws -> TransactionTypeRatioDTO {
        return PatternPreviewData.transactionTypeRatio
    }

    public func fetchMerchantRanking(range: DateRange) async throws -> MerchantRankingDTO {
        return PaymentPreviewData.merchantRanking
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
        return BudgetPreviewData.budgetVsExpense
    }
}
