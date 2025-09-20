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

        // MARK: - Transactions Routes
        case .transactions(.add):
            AddTransactionView(viewModel: container.makeAddTransactionViewModel())
            
        case .transactions(.detail(let transaction)):
            TransactionDetailView(viewModel: container.makeTransactionDetailViewModel(transaction: transaction))
            
        case .transactions(.update(let transaction)):
            UpdateTransactionView(viewModel: container.makeUpdateTransactionViewModel(transaction: transaction))
            
        // MARK: - Statistics Routes
        case .statistics(.overview):
            StatisticsView(viewModel: container.makeStatisticsViewModel())

        case .settings(let settingsRoute):
            handleSetting(settingsRoute: settingsRoute)
        }
    }

    // MARK: - Settings Routes

    @ViewBuilder
    private func handleSetting(settingsRoute: SettingsRoute) -> some View {
        switch settingsRoute {
        case .root:
            SettingsView()

        case .budget(let yearMonth):
            BudgetSetupView(viewModel: container.makeBudgetSetupViewModel(yearMonth: yearMonth))

        case .transactionTemplate:
            TransactionTemplateSettingsView(viewModel: container.makeTransactionTemplateSettingsViewModel())

        case .category:
            CategorySetupView(viewModel: container.makeCategoryListViewModel(mode: .configuration))

        case .categorySelector(let category):
            CategorySelectorView(viewModel: container.makeCategorySelectorViewModel(selectedCategory: category))

        case .categoryForm(let mode, let category, let transactionType):
            CategoryFormView(viewModel: container.makeCategoryFormViewModel(from: mode, category: category, transactionType: transactionType))

        case .subCategoryForm(let category, let subCategory):
            SubCategoryFormView(viewModel: container.makeSubCategoryFormViewModel(category: category, subCategory: subCategory))
        }
    }
}
