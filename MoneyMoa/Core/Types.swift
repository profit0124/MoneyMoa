//
//  Types.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/25/25.
//

import Foundation

// MARK: - YearMonth Type
public struct YearMonth: Codable, Comparable, Sendable, Equatable, Hashable {
    public let year: Int
    public let month: Int
    
    static public func < (lhs: YearMonth, rhs: YearMonth) -> Bool {
        if lhs.year != rhs.year {
            return lhs.year < rhs.year
        }
        return lhs.month < rhs.month
    }
    
    static public var current: YearMonth {
        let date = Date()
        let calendar = Calendar.current
        return YearMonth(
            year: calendar.component(.year, from: date),
            month: calendar.component(.month, from: date)
        )
    }
    
    public func previousMonth() -> YearMonth {
        if month > 1 {
            return YearMonth(year: year, month: month - 1)
        } else {
            return YearMonth(year: year - 1, month: 12)
        }
    }
    
    public func nextMonth() -> YearMonth {
        if month < 12 {
            return YearMonth(year: year, month: month + 1)
        } else {
            return YearMonth(year: year + 1, month: 1)
        }
    }
}

// MARK: - Transaction Type Enum
public enum TransactionType: String, Codable, CaseIterable, Sendable {
    case income = "income"
    case fixedExpense = "fixedExpense"
    case variableExpense = "variableExpense"
}

// MARK: - Payment Method Type
public enum PaymentMethodKind: String, Codable, CaseIterable, Sendable {
    case cash = "cash"
    case transfer = "transfer"
    case credit = "credit"
    case debit = "debit"
}

// MARK: - Repository Errors
public enum RepositoryError: Error, Sendable {
    case categoryNotFound
    case subCategoryNotFound
    case cannotDeleteActiveCategory
    case cannotDeleteActiveSubCategory
    case databaseError(Error)
}
