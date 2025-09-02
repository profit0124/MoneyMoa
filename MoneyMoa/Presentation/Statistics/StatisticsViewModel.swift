//
//  StatisticsViewModel.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/2/25.
//

import Foundation
import Observation

@Observable
public final class StatisticsViewModel {
    public var selectedDateRange: DateRangePreset = .thisMonth
    public var selectedGrouping: StatisticsGrouping = .daily

    public var showCustomDatePicker = false
    public var customDateRange: DateRange = DateRangePreset.thisMonth.resolve()
    
    public var dashboardData: StatisticsDashboardDTO
    public var isLoading = false
    public var errorMessage: String?
    
    public var hasTransactionData: Bool {
        return !dashboardData.overview.monthly.isEmpty || !dashboardData.overview.daily.isEmpty
    }
    
    public var hasBudgetData: Bool {
        return !dashboardData.budget.byMonth.isEmpty || !dashboardData.budget.byCategory.isEmpty
    }
    
    public var hasAnyCategoryData: Bool {
        return !dashboardData.category.ratios.isEmpty
    }
    
    private let getStatisticsDashboardUseCase: GetStatisticsDashboardUseCase
    
    public init(getStatisticsDashboardUseCase: GetStatisticsDashboardUseCase) {
        self.getStatisticsDashboardUseCase = getStatisticsDashboardUseCase
        self.dashboardData = StatisticsDashboardDTO(
            overview: .init(monthly: [], daily: [], burndown: []),
            category: .init(ratios: [], monthlyStacks: []),
            payment: .init(ratios: []),
            pattern: .init(weekly: .init(days: []), typeRatio: .init(income: 0.0, expense: 0.0), merchants: .init(entries: [])),
            budget: .init(byMonth: [], byCategory: [])
        )
    }
    
    public var currentDateRange: DateRange {
        selectedDateRange == .custom(customDateRange.start, customDateRange.end) ? 
            customDateRange : selectedDateRange.resolve()
    }
    
    public var formattedDateRange: String {
        FormatterManager.shared.formatDateRange(currentDateRange)
    }
    
    // MARK: - Actions
    
    enum Action {
        case loadDashboard
        case updateDateRange(DateRangePreset)
        case updateCustomDateRange(DateRange)
        case updateGrouping(StatisticsGrouping)
    }
    
    func send(_ action: Action) {
        switch action {
        case .loadDashboard:
            Task {
                await loadDashboard()
            }
        case .updateDateRange(let preset):
            updateDateRange(preset)
        case .updateCustomDateRange(let range):
            updateCustomDateRange(range)
        case .updateGrouping(let grouping):
            updateGrouping(grouping)
        }
    }
    
    // MARK: - Private Methods

    private func loadDashboard() async {
        isLoading = true
        errorMessage = nil
        
        do {
            dashboardData = try await getStatisticsDashboardUseCase.execute(range: currentDateRange)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func updateDateRange(_ preset: DateRangePreset) {
        selectedDateRange = preset
        selectedGrouping = preset.resolve().grouping
        send(.loadDashboard)
    }

    private func updateCustomDateRange(_ range: DateRange) {
        customDateRange = range
        selectedDateRange = .custom(range.start, range.end)
        send(.loadDashboard)
    }

    private func updateGrouping(_ grouping: StatisticsGrouping) {
        selectedGrouping = grouping
        send(.loadDashboard)
    }
}
