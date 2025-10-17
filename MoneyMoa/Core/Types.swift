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

    /// Date와 Calendar 로부터 YearMonth를 생성합니다
    public init(date: Date, calendar: Calendar = Calendar.current) {
        self.year = calendar.component(.year, from: date)
        self.month = calendar.component(.month, from: date)
    }
    
    /// 예산 설정 화면용 포맷된 타이틀을 반환합니다
    /// 예: "2025년 1월 예산 설정" (한국어) 또는 "January 2025 Budget Setup" (영어)
    public var budgetSetupTitle: String {
        if isKoreanLocale {
            let parts = formattedComponents.split(separator: " ")
            return "\(parts[0])년 \(parts[1])월 예산 설정"
        }

        return "\(formattedComponents) Budget Setup"
    }
    
    /// 포맷된 연월 문자열을 반환합니다
    /// 예: "2025년 1월" (한국어) 또는 "January 2025" (영어)
    public var formattedString: String {
        if isKoreanLocale {
            let parts = formattedComponents.split(separator: " ")
            return "\(parts[0])년 \(parts[1])월"
        }

        return formattedComponents
    }

    /// DateFormatter를 사용해서 로케일별 포맷된 컴포넌트를 추출
    private var formattedComponents: String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current

        if isKoreanLocale {
            dateFormatter.dateFormat = "yyyy M"  // "2025 1"
        } else {
            dateFormatter.dateFormat = "MMM yyyy"  // "Jan 2025"
        }
        
        let components = DateComponents(year: year, month: month)
        let date = Calendar.current.date(from: components) ?? Date()
        let formatted = dateFormatter.string(from: date)

        return formatted
    }
    
    /// 한국어 로케일인지 확인하는 방법 (iOS 17+)
    private var isKoreanLocale: Bool {
        Locale.current.language.languageCode == "ko"
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
    case hasActiveTemplates
    case databaseError(Error)
    case custom(String)
}

// MARK: - TransactionTimeContext

/// 거래 발생 시점의 시간대 및 로케일 컨텍스트
/// Experience-Based Time을 위한 핵심 타입
public struct TransactionTimeContext: Codable, Sendable, Hashable {
    /// 시간대 식별자 (e.g., "Asia/Seoul", "America/New_York")
    public let timeZoneIdentifier: String
    
    /// 캘린더 식별자 (e.g., "gregorian", "japanese", "chinese")
    public let calendarIdentifier: String
    
    /// 로케일 식별자 (e.g., "ko_KR", "en_US")
    public let localeIdentifier: String?
    
    /// TimeZone 객체 (계산된 프로퍼티)
    public var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .current
    }
    
    /// Calendar 객체 (계산된 프로퍼티)
    public var calendar: Calendar {
        // Calendar.Identifier를 문자열에서 직접 생성하는 방법
        let calendarID: Calendar.Identifier
        switch calendarIdentifier.lowercased() {
        case "gregorian": calendarID = .gregorian
        case "buddhist": calendarID = .buddhist
        case "chinese": calendarID = .chinese
        case "coptic": calendarID = .coptic
        case "ethiopicAmeteMihret": calendarID = .ethiopicAmeteMihret
        case "ethiopicAmeteAlem": calendarID = .ethiopicAmeteAlem
        case "hebrew": calendarID = .hebrew
        case "iso8601": calendarID = .iso8601
        case "indian": calendarID = .indian
        case "islamic": calendarID = .islamic
        case "islamicCivil": calendarID = .islamicCivil
        case "japanese": calendarID = .japanese
        case "persian": calendarID = .persian
        case "republicOfChina": calendarID = .republicOfChina
        case "islamicTabular": calendarID = .islamicTabular
        case "islamicUmmAlQura": calendarID = .islamicUmmAlQura
        default: calendarID = .gregorian
        }
        
        var cal = Calendar(identifier: calendarID)
        cal.timeZone = timeZone
        if let locale = locale {
            cal.locale = locale
        }
        return cal
    }
    
    /// Locale 객체 (계산된 프로퍼티)
    public var locale: Locale? {
        localeIdentifier.map { Locale(identifier: $0) }
    }
    
    /// 기본 생성자
    public init(
        timeZoneIdentifier: String,
        calendarIdentifier: String = "gregorian",
        localeIdentifier: String? = nil
    ) {
        self.timeZoneIdentifier = timeZoneIdentifier
        self.calendarIdentifier = calendarIdentifier
        self.localeIdentifier = localeIdentifier
    }
    
    /// 현재 기기 설정 기반 생성자
    public static var current: TransactionTimeContext {
        return TransactionTimeContext(
            timeZoneIdentifier: TimeZone.current.identifier,
            calendarIdentifier: Calendar.current.identifier.toString,
            localeIdentifier: Locale.current.identifier
        )
    }
}

// MARK: - RecurrencePeriod

//// Template 의 반복주기를 나타내는 Property
public enum RecurrencePeriod: String, CaseIterable, Codable, Sendable {
    case none
    case weekly
    case monthly
    case yearly

    public var displayName: String {
        switch self {
        case .none:
            "반복 없음"
        case .weekly:
            "매주"
        case .monthly:
            "매월"
        case .yearly:
            "매년"
        }
    }

    public func calculateOccurenceDate(from base: Date, processCount: Int, calendar: Calendar = Calendar.current) -> Date? {
        let component: Calendar.Component
        switch self {
        case .none:
            return nil
        case .weekly:
            component = .weekOfYear
        case .monthly:
            component = .month
        case .yearly:
            component = .year
        }

        return calendar.date(byAdding: component, value: processCount, to: base)
    }
}
