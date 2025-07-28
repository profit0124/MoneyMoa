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
    
    /// 해당 월의 첫날 00:00:00 Date를 반환
    public var startOfMonth: Date {
        let calendar = Calendar.current
        let components = DateComponents(year: year, month: month, day: 1, hour: 0, minute: 0, second: 0)
        return calendar.date(from: components) ?? Date()
    }
    
    /// 해당 월의 마지막날 23:59:59 Date를 반환
    public var endOfMonth: Date {
        let calendar = Calendar.current
        let nextMonth = self.nextMonth()
        let nextMonthStart = nextMonth.startOfMonth
        // 다음 달 첫날에서 1초를 빼서 이번 달 마지막날 23:59:59를 만듦
        return calendar.date(byAdding: .second, value: -1, to: nextMonthStart) ?? Date()
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
    case transactionNotFound
    case paymentMethodNotFound
    case cannotDeleteActiveCategory
    case cannotDeleteActiveSubCategory
    case databaseError(Error)
}
