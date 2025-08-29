//
//  Rows.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/29/25.
//

import Foundation

public struct IncomeExpenseMonthlyRow: Sendable {
    public let monthStart: Date
    public let income: Decimal
    public let expense: Decimal
}

public struct CategoryMonthlyRow: Sendable {
    public let categoryId: String
    public let categoryName: String
    public let monthStart: Date
    public let expense: Decimal
}

public struct PaymentMethodStatsRow: Sendable {
    public let methodId: String
    public let methodName: String
    public let amount: Decimal
    public let count: Int
}

public struct MerchantRankingRow: Sendable {
    public let merchant: String
    public let count: Int
    public let total: Decimal
}

public struct BudgetVsExpenseMonthlyRow: Sendable {
    public let monthStart: Date
    public let budget: Decimal
    public let expense: Decimal
}

public struct TransactionRow: Sendable {
    public let date: Date
    public let amount: Decimal
}
