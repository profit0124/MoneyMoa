//
//  Calendar+.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/28/25.
//

import Foundation

public extension Calendar {
    /// 주어진 날짜의 달 시작일(1일 00:00)
    func startOfMonth(for date: Date) -> Date {
        let comps = dateComponents([.year, .month], from: date)
        return self.date(from: comps)!
    }
    /// 주어진 날짜가 속한 달의 exclusive end(다음 달 1일 00:00)
    func endOfMonthExclusive(for date: Date) -> Date {
        let s = startOfMonth(for: date)
        return self.date(byAdding: .month, value: 1, to: s)!
    }
}
