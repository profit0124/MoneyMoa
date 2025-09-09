//
//  StatisticsView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/1/25.
//

import Charts
import SwiftUI

struct StatisticsView: View {
    @State private var viewModel: StatisticsViewModel

    init(viewModel: StatisticsViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Filter Bar
                filterBar

                // Section 1: 전체 개요
                overviewSection

                // Section 2: 카테고리 분석
                categoryAnalysisSection

                // Section 3: 결제수단 분석
                paymentMethodAnalysisSection

                // Section 4: 패턴 분석
                patternAnalysisSection

                // Section 5: 예산 분석
                budgetAnalysisSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .toolbar {
            ToolbarItem(placement: .principal) {
                navigationBarTitle
            }
        }

        .sheet(isPresented: $viewModel.showCustomDatePicker) {
            CustomDatePickerView(dateRange: $viewModel.customDateRange) {
                viewModel.send(.updateCustomDateRange(viewModel.customDateRange))
                viewModel.showCustomDatePicker = false
            }
        }
        .task {
            viewModel.send(.loadDashboard)
        }
    }

    // MARK: - NavigationTitle

    private var navigationBarTitle: some View {
        VStack(spacing: 2) {
            Text("통계")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(viewModel.formattedDateRange)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        VStack(spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(
                        [
                            DateRangePreset.thisMonth, .lastMonth, .threeMonths,
                            .sixMonths, .thisYear
                        ],
                        id: \.self
                    ) { preset in
                        Button {
                            viewModel.send(.updateDateRange(preset))
                        } label: {
                            Text(preset.title)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(
                                    viewModel.selectedDateRange.title
                                        == preset.title ? .white : .primary
                                )
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background {
                                    if viewModel.selectedDateRange.title == preset.title {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(.blue)
                                    } else {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color(.systemGray5))
                                    }
                                }
                        }
                    }

                    Button("사용자 지정") {
                        viewModel.showCustomDatePicker = true
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray5))
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 8)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Sections

    private var overviewSection: some View {
        StatisticsSectionView(
            title: "전체 개요",
            icon: "chart.bar.fill",
            iconColor: .blue
        ) {
            VStack(spacing: 20) {
                if viewModel.currentDateRange.months().count <= 4 {
                    Picker("그룹핑", selection: Binding(
                        get: { viewModel.selectedGrouping },
                        set: { viewModel.send(.updateGrouping($0)) }
                    )) {
                        Text("일별").tag(StatisticsGrouping.daily)
                        Text("월별").tag(StatisticsGrouping.monthly)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 16)
                }

                if viewModel.selectedGrouping == .monthly {
                    MonthlyIncomeExpenseView(
                        data: viewModel.dashboardData.overview.monthly
                    )
                } else {
                    DailyExpenseFlowView(
                        data: viewModel.dashboardData.overview.daily
                    )
                    BurndownChartView(
                        data: viewModel.dashboardData.overview.burndown
                    )
                }
            }
        }
    }

    private var categoryAnalysisSection: some View {
        StatisticsSectionView(
            title: "카테고리 분석",
            icon: "folder.fill",
            iconColor: .orange
        ) {
            VStack(spacing: 20) {
                CategoryRatioView(data: viewModel.dashboardData.category.ratios)
                CategoryMonthlyTrendView(
                    data: viewModel.dashboardData.category.monthlyStacks
                )
            }
        }
    }

    private var paymentMethodAnalysisSection: some View {
        StatisticsSectionView(
            title: "결제수단 분석",
            icon: "creditcard.fill",
            iconColor: .green
        ) {
            PaymentMethodRatioView(data: viewModel.dashboardData.payment.ratios)
        }
    }

    private var patternAnalysisSection: some View {
        StatisticsSectionView(
            title: "패턴 분석",
            icon: "waveform.path.ecg",
            iconColor: .purple
        ) {
            VStack(spacing: 20) {
                WeeklyPatternView(data: viewModel.dashboardData.pattern.weekly)
                TransactionTypeRatioView(
                    data: viewModel.dashboardData.pattern.typeRatio
                )
                MerchantRankingView(
                    data: viewModel.dashboardData.pattern.merchants
                )
            }
        }
    }

    private var budgetAnalysisSection: some View {
        StatisticsSectionView(
            title: "예산 분석",
            icon: "dollarsign.circle.fill",
            iconColor: .mint
        ) {
            VStack(spacing: 20) {
                BudgetVsExpenseView(
                    data: viewModel.dashboardData.budget.byMonth
                )
                CategoryBudgetView(
                    data: viewModel.dashboardData.budget.byCategory
                )
            }
        }
    }
}

// MARK: - DateRangePreset Extension

extension DateRangePreset {
    var title: String {
        switch self {
        case .thisMonth: return "이번 달"
        case .lastMonth: return "지난 달"
        case .threeMonths: return "최근 3개월"
        case .sixMonths: return "최근 6개월"
        case .thisYear: return "올해"
        case .custom: return "사용자 지정"
        }
    }
}

// MARK: - Custom Date Picker

struct CustomDatePickerView: View {
    @Binding var dateRange: DateRange
    let onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var startDate = Date()
    @State private var endDate = Date()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                DatePicker(
                    "시작일",
                    selection: $startDate,
                    displayedComponents: .date
                )
                DatePicker(
                    "종료일",
                    selection: $endDate,
                    displayedComponents: .date
                )

                Spacer()
            }
            .padding()
            .navigationTitle("기간 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("확인") {
                        let calendar = Calendar.current
                        let start = calendar.startOfDay(for: startDate)
                        let end = calendar.startOfDay(
                            for: calendar.date(
                                byAdding: .day,
                                value: 1,
                                to: endDate
                            ) ?? endDate
                        )
                        dateRange = DateRange(start: start, end: end)
                        onConfirm()
                    }
                }
            }
        }
        .onAppear {
            startDate = dateRange.start
            endDate =
                Calendar.current.date(
                    byAdding: .day,
                    value: -1,
                    to: dateRange.end
                ) ?? dateRange.end
        }
    }
}

#Preview {
    NavigationStack {
        StatisticsView(
            viewModel: MockDIContainer().makeStatisticsViewModel()
        )
        .navigationTitle(Text("asdf"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
