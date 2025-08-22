//
//  ViewFactory.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/10/25.
//

import SwiftUI

// MARK: - View Factory

struct ViewFactory {
    let container: DIContainer
    
    @ViewBuilder
    func makeView(for route: AppRoute) -> some View {
        switch route {
        // MARK: - Main Routes
        case .main(.home):
            MainView(viewModel: container.makeMainViewModel())
            
        // MARK: - Settings Routes
        case .settings(.root):
            SettingsView()
            
        case .settings(.budget):
            BudgetSetupView(viewModel: container.makeBudgetSetupViewModel())
            
        // MARK: - Transactions Routes
        case .transactions(.add):
            AddTransactionView(viewModel: container.makeAddTransactionViewModel())
            
        case .transactions(.detail(let transaction)):
            TransactionDetailView(viewModel: container.makeTransactionDetailViewModel(transaction: transaction))
            
        case .transactions(.update(let transaction)):
            UpdateTransactionView(viewModel: container.makeUpdateTransactionViewModel(transaction: transaction))
            
        // MARK: - Charts Routes
        case .charts(.overview):
            ChartView()
        }
    }
}
