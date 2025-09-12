//
//  GetStatisticsDashboardUseCaseImpl.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/29/25.
//

import Foundation

public final class GetStatisticsDashboardUseCaseImpl: GetStatisticsDashboardUseCase {
    private let repo: StatisticsRepository
    private let ma: MovingAverageService
    private let burndown: BurndownService
    private let completeness: BudgetCompletenessService
    private let cal = Calendar.current
    private let cache = StatisticsCache()

    public init(repo: StatisticsRepository,
                ma: MovingAverageService = MovingAverageServiceImpl(),
                burndown: BurndownService = BurndownServiceImpl(),
                completeness: BudgetCompletenessService = BudgetCompletenessServiceImpl()) {
        self.repo = repo
        self.ma = ma
        self.burndown = burndown
        self.completeness = completeness
    }

    public func execute(range: DateRange) async throws -> StatisticsDashboardDTO {
        if let cached = await cache.value(for: range) { return cached }

        async let monthly = repo.fetchMonthlyTotals(range: range)
        async let daily   = repo.fetchDailyExpenses(range: range)
        async let byCat   = repo.fetchCategoryExpenseByMonth(range: range)
        async let byPay   = repo.fetchPaymentMethodStats(range: range)
        async let typeR   = repo.fetchTransactionTypeRatio(range: range)
        async let rank    = repo.fetchMerchantRanking(range: range)
        async let budgets = repo.fetchBudgetsByCategory(range: range)
        async let byMonth = repo.fetchBudgetVsExpenseByMonth(range: range)

        let months = cal.yearMonths(in: range)
        let budgetsMap = try await budgets
        let complete = completeness.completeCategories(budgets: budgetsMap, months: months)

        let dailyRaw = try await daily
        let dailyMA = ma.ma7(dailyRaw, calendar: cal)

        // Burndown: 현재 선택 기간이 1개월일 때에 가장 유의미(여러 달 지원 시 월별 제공)
        let burndownPoints: [BurndownPointDTO] = makeBurndownPointDTOs(months: months, budgetsMap: budgetsMap, dailyRaw: dailyRaw)

        // Category ratios: sum by category / total
        let byCategory = try await byCat
        let ratios: [CategoryRatioDTO] = makeCategoryRatioDTOs(byCategory: byCategory)

        let filteredMonthlyStacks = byCategory.filter { complete.contains($0.categoryId) }

        // Budget by category (complete only)
        let byCatBudget: [CategoryBudgetVsExpenseDTO] = complete.sorted().compactMap { catId in
            makeCategoryBudgetVsExpenseDTO(catId: catId, byCategory: byCategory, months: months, budgetsMap: budgetsMap)
        }

        let overview = StatisticsDashboardDTO.Overview(
            monthly: try await monthly,
            daily: dailyMA,
            burndown: burndownPoints
        )
        let category = StatisticsDashboardDTO.Category(ratios: ratios, monthlyStacks: filteredMonthlyStacks)
        let payment = StatisticsDashboardDTO.Payment(ratios: try await byPay)
        let pattern = StatisticsDashboardDTO.Pattern(weekly: WeeklyPatternService.make(dailyRaw, calendar: cal), typeRatio: try await typeR, merchants: try await rank)
        let budget = StatisticsDashboardDTO.Budget(byMonth: try await byMonth, byCategory: byCatBudget)

        let dto = StatisticsDashboardDTO(overview: overview, category: category, payment: payment, pattern: pattern, budget: budget)
        await cache.set(dto, for: range)
        return dto
    }

    private func makeBurndownPointDTOs(months: [YearMonth], budgetsMap: [String: [YearMonth: Decimal]], dailyRaw: [DailyPointDTO]) -> [BurndownPointDTO] {
        let burndownPoints: [BurndownPointDTO]
        if let one = months.first, months.count == 1, let budgetsForCats = budgetsMap.values.first, let anyBudget = budgetsForCats[one] {
            burndownPoints = burndown.make(expectedMonthlyBudget: anyBudget, dailyExpenses: dailyRaw, calendar: cal)
        } else {
            burndownPoints = []
        }

        return burndownPoints
    }

    private func makeCategoryRatioDTOs(byCategory: [CategoryMonthlyPointDTO]) -> [CategoryRatioDTO] {
        let totalExpense = byCategory.reduce(Decimal(0)) { $0 + $1.expense }
        return Dictionary(grouping: byCategory, by: { $0.categoryId }).map { (catId, rows) in
            let name = rows.first?.categoryName ?? catId
            let sum = rows.reduce(Decimal(0)) { $0 + $1.expense }
            let ratio = (totalExpense == 0) ? 0 : (sum / totalExpense).asDouble
            return CategoryRatioDTO(categoryId: catId, categoryName: name, ratio: ratio, amount: sum)
        }.sorted { $0.amount > $1.amount }
    }

    private func makeCategoryBudgetVsExpenseDTO(catId: String, byCategory: [CategoryMonthlyPointDTO], months: [YearMonth], budgetsMap: [String: [YearMonth: Decimal]]) -> CategoryBudgetVsExpenseDTO {
        let name = byCategory.first(where: { $0.categoryId == catId })?.categoryName ?? catId
        let budgetsForCat = budgetsMap[catId] ?? [:]
        let monthCount = months.count
        let budgetTotal = months.reduce(Decimal(0)) { $0 + (budgetsForCat[$1] ?? 0) }
        let expenseTotal = byCategory.filter { $0.categoryId == catId }.reduce(Decimal(0)) { $0 + $1.expense }
        let usage = (budgetTotal == 0) ? 0 : (expenseTotal / budgetTotal).asDouble
        let status: BudgetStatus = usage > 1.0 ? .exceeded : (usage >= 0.9 ? .warning : .normal)
        return .init(categoryId: catId, categoryName: name, budget: budgetTotal, expense: expenseTotal, usageRate: usage, status: status, monthCount: monthCount)
    }
}

public enum WeeklyPatternService {
    public static func make(_ daily: [DailyPointDTO], calendar: Calendar = Calendar.current) -> WeeklyPatternDTO {
        guard !daily.isEmpty else { return .init(days: []) }
        var sum: [Int: (amount: Decimal, count: Int)] = [:]
        for p in daily {
            let wd = calendar.component(.weekday, from: p.date) // 1..7
            var cur = sum[wd] ?? (0, 0)
            cur.amount += p.amount
            cur.count += 1
            sum[wd] = cur
        }
        let days = (1...7).map { wd -> WeeklyPatternDTO.Day in
            let v = sum[wd] ?? (0, 0)
            let avgAmount = v.count == 0 ? 0 : (v.amount / Decimal(v.count))
            let avgCount = v.count == 0 ? 0 : Double(v.count) / Double( Set(daily.map { calendar.startOfMonth(for: $0.date) }).count )
            return .init(weekday: wd, avgAmount: avgAmount, avgCount: avgCount)
        }
        return .init(days: days)
    }
}
