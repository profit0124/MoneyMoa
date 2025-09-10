//
//  FixedDateHelper.swift
//  MoneyMoaTests
//
//  Created by Claude on 9/10/25.
//

import Foundation
@testable import MoneyMoa

/// Helper for providing fixed dates in tests to ensure CI compatibility
public enum FixedDateHelper {

    /// Fixed date for testing (August 15, 2025)
    /// This ensures consistent test results across different timezones and CI environments
    public static var fixedDate: Date {
        KST.calendar.date(from: DateComponents(year: 2025, month: 8, day: 15))!
    }

    /// Fixed YearMonth for testing
    public static var fixedYearMonth: YearMonth {
        YearMonth(date: fixedDate, calendar: KST.calendar)
    }

    /// Create a date range for the fixed month
    public static var fixedMonthRange: DateRange {
        let month = fixedYearMonth
        return DateRange(
            start: month.startOfMonth,
            end: month.endOfMonth,
            calendar: KST.calendar
        )
    }

    /// Create a multi-month range starting from the fixed date
    public static func createRange(months: Int) -> DateRange {
        let endDate = fixedDate
        let startDate = KST.calendar.date(byAdding: .month, value: -months, to: endDate)!
        return DateRange(start: startDate, end: endDate, calendar: KST.calendar)
    }
}
