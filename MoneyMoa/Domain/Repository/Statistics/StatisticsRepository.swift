//
//  StatisticsRepository.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/28/25.
//

import Foundation

/// 통계 화면을 위한 읽기 전용 파사드 리포지토리
/// - 내부적으로 여러 저장소(Transaction/Budget/Category 등)를 조합할 수 있습니다.
/// - UseCase는 데이터 소스/결합 방식을 알 필요 없이 이 인터페이스만 의존합니다.
public protocol StatisticsRepository {
    // 섹션 1
    func fetchMonthlyTotals(range: DateRange) async throws -> [MonthlyPointDTO]
    func fetchDailyExpenses(range: DateRange) async throws -> [DailyPointDTO]

    // 섹션 2
    func fetchCategoryExpenseByMonth(range: DateRange) async throws -> [CategoryMonthlyPointDTO]

    // 섹션 3
    func fetchPaymentMethodStats(range: DateRange) async throws -> [PaymentMethodRatioDTO]

    // 섹션 4
    func fetchTransactionTypeRatio(range: DateRange) async throws -> TransactionTypeRatioDTO
    func fetchMerchantRanking(range: DateRange) async throws -> MerchantRankingDTO

    // 섹션 5 (예산)
    func fetchBudgetsByCategory(range: DateRange) async throws -> [String: [YearMonth: Decimal]]
    func fetchBudgetVsExpenseByMonth(range: DateRange) async throws -> [BudgetVsExpenseDTO]
}
