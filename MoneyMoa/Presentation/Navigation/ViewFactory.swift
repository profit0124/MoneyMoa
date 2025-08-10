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
    func makeView(for route: AppRoute, router: AppRouter) -> some View {
        switch route {
        // MARK: - Main Routes
        case .main(.home):
            MainView(viewModel: container.makeMainViewModel())
                .environment(router)
            
        // MARK: - Settings Routes
        case .settings(.root):
            SettingsView(router: router)
            
        case .settings(.budget):
            BudgetTemplateView(router: router)
            
        // MARK: - Transactions Routes
        case .transactions(.add):
            AddTransactionView(router: router)
            
        case .transactions(.detail(let transaction)):
            TransactionDetailView(
                transaction: transaction,
                router: router
            )
            
        case .transactions(.update(let transaction)):
            UpdateTransactionView(
                transaction: transaction,
                router: router
            )
            
        // MARK: - Charts Routes
        case .charts(.overview):
            ChartView(router: router)
        }
    }
}
