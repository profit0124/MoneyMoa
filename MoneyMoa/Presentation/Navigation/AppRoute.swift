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
    case transactionTemplate
    case category
    case categorySelector(CategoryDTO)
    case categoryForm(CategoryListMode, CategoryDTO?, TransactionType?)
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

enum StatisticsRoute: Hashable {
    case overview
}

enum TransactionTemplateRoute: Hashable {
    case add
    case update(TransactionTemplateDTO)
}

// MARK: - App Route (Union)

enum AppRoute: Hashable {
    case main(MainRoute)
    case settings(SettingsRoute)
    case transactions(TransactionsRoute)
    case statistics(StatisticsRoute)
    case transactionTemplates(TransactionTemplateRoute)
}

// MARK: - Convenience Extensions

extension AppRoute {
    static let mainHome = AppRoute.main(.home)
    static let settingsRoot = AppRoute.settings(.root)
    static let transactionsAdd = AppRoute.transactions(.add)
    static let statisticsOverview = AppRoute.statistics(.overview)
    static let categorySetup = AppRoute.settings(.category)
    static let settingTransactionTemplate = AppRoute.settings(.transactionTemplate)

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

    static func categoryForm(from mode: CategoryListMode, category: CategoryDTO?, transactionType: TransactionType? = nil) -> AppRoute {
        return .settings(.categoryForm(mode, category, transactionType))
    }

    static func subCategoryForm(
        _ category: CategoryDTO,
        _ subCategory: SubCategoryDTO?
    ) -> AppRoute {
        return .settings(.subCategoryForm(category, subCategory))
    }

    static let transactionTemplateAdd = AppRoute.transactionTemplates(.add)
    static func transactionTemplateUpdate(_ template: TransactionTemplateDTO) -> AppRoute {
        return .transactionTemplates(.update(template))
    }
}
