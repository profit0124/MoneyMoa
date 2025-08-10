//
//  MainView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/30/25.
//

import SwiftUI

struct MainView: View {
    @State private var viewModel: MainViewModel
    @Environment(AppRouter.self) private var router
    
    init(viewModel: MainViewModel) {
        self._viewModel = State(wrappedValue: viewModel)
    }
    
    var body: some View {
            ZStack {
                VStack {
                    // Custom Navigation Bar
                    CustomNavigationBarView(
                        onChartTap: handleChartTap,
                        onSettingsTap: handleSettingsTap
                    )
                    .padding(.horizontal, 16)
                    
                    // Year/Month Header
                    YearMonthHeaderView(
                        yearMonth: viewModel.currentYearMonth,
                        onYearMonthChange: handleYearMonthChange
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    
                    // Main Content
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            // Summary Section
                            SummaryView(
                                summaryData: viewModel.summaryData,
                                isLoading: viewModel.isSummaryLoading,
                                onBudgetSetupTap: handleBudgetSetupTap
                            )
                            .padding(.vertical, 8)
                            
                            // Calendar Section
                            CalendarView(
                                yearMonth: viewModel.currentYearMonth,
                                transactionsByDate: viewModel.transactionsByDate,
                                onDateTap: handleDateTap
                            )
                            .padding(.horizontal, 16)
                            
                            // Divider
                            Divider()
                                .padding(.vertical, 16)
                            
                            // TransactionList Section
                            TransactionListView(
                                listData: viewModel.listData,
                                onTransactionTap: handleTransactionTap
                            )
                            
                            // Bottom padding for floating button
                            Spacer()
                                .frame(height: 80)
                        }
                    }
                }
                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingActionButton(onTap: handleAddTransactionTap)
                            .padding(.trailing, 16)
                            .padding(.bottom, 16)
                    }
                }
            }
            .navigationBarHidden(true)
            .task {
                viewModel.send(.loadTransactions)
            }
    }
    
    // MARK: - Private Methods
    
    private func handleTransactionTap(_ transaction: TransactionDTO) {
        router.push(.transactionDetail(transaction))
    }
    
    private func handleDateTap(_ date: Date) {
        print("Date tapped: \(date)")
    }
    
    private func handleYearMonthChange(_ action: MainViewModel.HandleYearMonth) {
        viewModel.send(.handleYearMonth(action))
    }
    
    private func handleBudgetSetupTap() {
        router.push(.settingsBudget)
    }
    
    private func handleChartTap() {
        router.push(.chartsOverview)
    }
    
    private func handleSettingsTap() {
        router.push(.settingsRoot)
    }
    
    private func handleAddTransactionTap() {
        router.present(.transactionsAdd, as: .sheet)
    }
}

// MARK: - Preview

#Preview {
    // Mock dependencies for preview
    let viewModel = MainViewModel(
        getMonthlyTransactionsUseCase: MockGetMonthlyTransactionsUseCase(),
        getExpenseSumUntilDateUseCase: MockGetExpenseSumUntilDateUseCase(),
        getMonthlyBudgetUseCase: MockGetMonthlyBudgetUseCase(),
        getBudgetTemplateUseCase: MockGetBudgetTemplateUseCase(),
        createBudgetFromTemplateUseCase: MockCreateBudgetFromTemplateUseCase()
    )
    
    MainView(viewModel: viewModel)
        .environment(AppRouter())
}
