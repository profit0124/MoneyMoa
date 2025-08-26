//
//  AppRoute.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/10/25.
//

import Foundation

// MARK: - Feature Routes

enum MainRoute: Hashable {
    case home
}

enum SettingsRoute: Hashable {
    case root
    case budget(YearMonth)
    case category
    case categorySelector(CategoryDTO)
    case categoryForm(CategoryListMode, CategoryDTO?)
    case subCategoryForm(CategoryDTO, SubCategoryDTO?)
}

enum TransactionsRoute: Hashable {
    case add
    case detail(TransactionDTO)
    case update(TransactionDTO)
}

enum ChartsRoute: Hashable {
    case overview
}

// MARK: - App Route (Union)

enum AppRoute: Hashable {
    case main(MainRoute)
    case settings(SettingsRoute)
    case transactions(TransactionsRoute)
    case charts(ChartsRoute)
}

// MARK: - Convenience Extensions

extension AppRoute {
    static let mainHome = AppRoute.main(.home)
    static let settingsRoot = AppRoute.settings(.root)
    static let transactionsAdd = AppRoute.transactions(.add)
    static let chartsOverview = AppRoute.charts(.overview)
    static let categorySetup = AppRoute.settings(.category)

    static func settingsBudget(_ yearMonth: YearMonth) -> AppRoute {
        return .settings(.budget(yearMonth))
    }

    static func transactionDetail(_ transaction: TransactionDTO) -> AppRoute {
        return .transactions(.detail(transaction))
    }
    
    static func transactionUpdate(_ transaction: TransactionDTO) -> AppRoute {
        return .transactions(.update(transaction))
    }

    static func categorySelector(_ category: CategoryDTO) -> AppRoute {
        return .settings(.categorySelector(category))
    }

    static func categoryForm(from mode: CategoryListMode, category: CategoryDTO?) -> AppRoute {
        return .settings(.categoryForm(mode, category))
    }

    static func subCategoryForm(
        _ category: CategoryDTO,
        _ subCategory: SubCategoryDTO?
    ) -> AppRoute {
        return .settings(.subCategoryForm(category, subCategory))
    }
}
