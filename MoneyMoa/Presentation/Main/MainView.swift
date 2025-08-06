//
//  MainView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/30/25.
//

import SwiftUI

struct MainView: View {
    @State private var viewModel: MainViewModel
    
    init(viewModel: MainViewModel) {
        self._viewModel = State(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
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
    }
    
    // MARK: - Private Methods
    
    private func handleTransactionTap(_ transaction: TransactionDTO) {
        // TODO: 거래 상세 화면으로 이동
        print("Transaction tapped: \(transaction.id)")
    }
    
    private func handleDateTap(_ date: Date) {
        // TODO: 해당 날짜 거래 목록으로 스크롤
        print("Date tapped: \(date)")
    }
    
    private func handleYearMonthChange(_ action: MainViewModel.HandleYearMonth) {
        viewModel.send(.handleYearMonth(action))
    }
    
    private func handleBudgetSetupTap() {
        // TODO: 예산 설정 화면으로 이동
        print("Budget setup tapped")
    }
    
    private func handleChartTap() {
        // TODO: 차트/분석 화면으로 이동
        print("Chart tapped")
    }
    
    private func handleSettingsTap() {
        // TODO: 설정 화면으로 이동
        print("Settings tapped")
    }
    
    private func handleAddTransactionTap() {
        // TODO: 거래 추가 화면으로 이동
        print("Add transaction tapped")
    }
}

// MARK: - Preview

#Preview {
    // TODO: 실제 의존성 주입으로 교체 예정
    let viewModel = MainViewModel(
        getMonthlyTransactionsUseCase: MockGetMonthlyTransactionsUseCase(),
        getExpenseSumUntilDateUseCase: MockGetExpenseSumUntilDateUseCase(),
        getMonthlyBudgetUseCase: MockGetMonthlyBudgetUseCase(),
        getBudgetTemplateUseCase: MockGetBudgetTemplateUseCase(),
        createBudgetFromTemplateUseCase: MockCreateBudgetFromTemplateUseCase()
    )
    
    MainView(viewModel: viewModel)
}
