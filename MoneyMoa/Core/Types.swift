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
        let calendar = FormatterManager.shared.koreaCalendar
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
    
    /// 기본 생성자
    public init(year: Int, month: Int) {
        self.year = year
        self.month = month
    }
    
    /// Date로부터 YearMonth를 생성합니다
    public init(from date: Date) {
        let calendar = Calendar.current
        self.year = calendar.component(.year, from: date)
        self.month = calendar.component(.month, from: date)
    }
}

// MARK: - Transaction Type Enum
public enum TransactionType: String, Codable, CaseIterable, Sendable {
    case income
    case fixedExpense
    case variableExpense
}

// MARK: - Payment Method Type
public enum PaymentMethodKind: String, Codable, CaseIterable, Sendable {
    case cash
    case transfer
    case credit
    case debit
}

// MARK: - Repository Errors
public enum RepositoryError: Error, Sendable {
    case categoryNotFound
    case subCategoryNotFound
    case transactionNotFound
    case paymentMethodNotFound
    case budgetTemplateNotFound
    case budgetNotFound
    case budgetAlreadyExists
    case categoryBudgetNotFound
    case categoryBudgetsExceedTotalAmount
    case cannotDeleteActiveCategory
    case cannotDeleteActiveSubCategory
    case cannotDeleteActivePaymentMethod
    case databaseError(Error)
    case custom(String)
}

// MARK: KST
/// 앱 전역에서 사용하는 KST(Asia/Seoul) 캘린더 유틸
/// - Locale: ko_KR
/// - TimeZone: Asia/Seoul
/// - Calendar: gregorian
public enum KST {
    public static let timeZone = TimeZone(identifier: "Asia/Seoul")!
    public static var calendar: Calendar = {
        FormatterManager.shared.koreaCalendar
    }()
}
