//
//  YearMonth+.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/28/25.
//

import Foundation

public extension YearMonth {
    /// 해당 YearMonth의 달 시작일(1일 00:00 Calendar)
    func startDate(calendar: Calendar = Calendar.current) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: 1))!
    }
    /// 해당 YearMonth의 다음 달 시작일(= 이번 달의 exclusive end)
    func endExclusive(calendar: Calendar = Calendar.current) -> Date {
        calendar.date(byAdding: .month, value: 1, to: startDate(calendar: calendar))!
    }
}
