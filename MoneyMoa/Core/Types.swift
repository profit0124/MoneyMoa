//
//  Types.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/25/25.
//

import Foundation

// MARK: - YearMonth Type
struct YearMonth: Codable, Comparable, Sendable, Equatable, Hashable {
    let year: Int
    let month: Int
    
    static func < (lhs: YearMonth, rhs: YearMonth) -> Bool {
        if lhs.year != rhs.year {
            return lhs.year < rhs.year
        }
        return lhs.month < rhs.month
    }
    
    static var current: YearMonth {
        let date = Date()
        let calendar = Calendar.current
        return YearMonth(
            year: calendar.component(.year, from: date),
            month: calendar.component(.month, from: date)
        )
    }
    
    func previousMonth() -> YearMonth {
        if month > 1 {
            return YearMonth(year: year, month: month - 1)
        } else {
            return YearMonth(year: year - 1, month: 12)
        }
    }
    
    func nextMonth() -> YearMonth {
        if month < 12 {
            return YearMonth(year: year, month: month + 1)
        } else {
            return YearMonth(year: year + 1, month: 1)
        }
    }
}

// MARK: - Transaction Type Enum
enum TransactionType: String, Codable, CaseIterable, Sendable {
    case income = "income"
    case fixedExpense = "fixedExpense"
    case variableExpense = "variableExpense"
}

// MARK: - Payment Method Type
enum PaymentMethodKind: String, Codable, CaseIterable, Sendable {
    case cash = "cash"
    case transfer = "transfer"
    case credit = "credit"
    case debit = "debit"
}
