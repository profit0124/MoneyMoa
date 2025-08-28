//
//  MockStatisticsRepository.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/28/25.
//

import Foundation

/// 프리뷰/테스트용 Mock 구현
/// - 실제 SwiftData/네트워크 연동 전, UI/로직 검증에 사용합니다.
public final class MockStatisticsRepository: StatisticsRepository {
    public init() {}

    public func fetchMonthlyTotals(range: DateRange) async throws -> [MonthlyPointDTO] {
        let cal = KST.calendar
        // 각 월을 동일한 금액으로 생성 (UI/테스트 안정성 위해 고정값)
        return cal.yearMonths(in: range).map { ym in
            .init(monthStart: ym.startDate(calendar: cal), income: 2_000_000, expense: 1_200_000)
        }
    }

    public func fetchDailyExpenses(range: DateRange) async throws -> [DailyPointDTO] {
        // 단순 난수 기반 일별 지출 (시각화 확인용)
        var out: [DailyPointDTO] = []
        var cursor = KST.calendar.startOfMonth(for: range.start)
        let end = range.end
        while cursor < end {
            out.append(.init(date: cursor, amount: Decimal(Int.random(in: 10_00...12_00)) * 1_00))
            cursor = KST.calendar.date(byAdding: .day, value: 1, to: cursor)!
        }
        return out
    }

    public func fetchCategoryExpenseByMonth(range: DateRange) async throws -> [CategoryMonthlyPointDTO] {
        // 카테고리 3종(식비/쇼핑/건강) × 월
        let cal = KST.calendar
        let months = cal.yearMonths(in: range)
        let cats = [
            ("food", "식비"),
            ("shop", "쇼핑"),
            ("health", "건강")
        ]
        return months.flatMap { ym in
            cats.map { (id, name) in
                .init(categoryId: id, categoryName: name, monthStart: ym.startDate(calendar: cal),
                      expense: Decimal(Int.random(in: 200_000...800_000)))
            }
        }
    }

    public func fetchPaymentMethodStats(range: DateRange) async throws -> [PaymentMethodRatioDTO] {
        [
            .init(methodId: "card",
                  methodName: "카드",
                  ratio: 0.6,
                  amount: 1_800_000,
                  count: 42
                 ),
            .init(methodId: "cash",
                  methodName: "현금",
                  ratio: 0.3,
                  amount: 900_000,
                  count: 20),
            .init(methodId: "transfer",
                  methodName: "이체",
                  ratio: 0.1,
                  amount: 300_000,
                  count: 7)
        ]
    }

    public func fetchTransactionTypeRatio(range: DateRange) async throws -> TransactionTypeRatioDTO {
        .init(income: 0.35, expense: 0.6, transfer: 0.05)
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
