//
//  DateRangePresetTests.swift
//  MoneyMoaTests
//
//  Created by Sooik Kim on 8/29/25.
//

import Foundation
import Testing
@testable import MoneyMoa

/// DateRangePreset이 KST 경계와 그룹핑 규약을 따르는지 검증
struct DateRangePresetTests {

    @Test
    func thisMonth_isKSTBoundaries() {
        // 상황: 임의 중간일/시간이라도 해당 달의 시작~다음달 시작으로 정규화되어야 함.
        let cal = Calendar.current
        let fixed = cal.date(from: DateComponents(year: 2025, month: 8, day: 15, hour: 12))!
        let r = DateRangePreset.thisMonth.resolve(now: fixed, calendar: cal)
        #expect(r.start == cal.date(from: DateComponents(year: 2025, month: 8, day: 1)))
        #expect(r.end   == cal.date(from: DateComponents(year: 2025, month: 9, day: 1)))
    }

    @Test
    func lastMonth_isPreviousMonthRange() {
        let cal = Calendar.current
        let fixed = cal.date(from: DateComponents(year: 2025, month: 8, day: 2))!
        let r = DateRangePreset.lastMonth.resolve(now: fixed, calendar: cal)
        #expect(r.start == cal.date(from: DateComponents(year: 2025, month: 7, day: 1)))
        #expect(r.end   == cal.date(from: DateComponents(year: 2025, month: 8, day: 1)))
    }

    @Test
    func threeMonths_switchesToMonthlyGrouping() {
        // 상황: 3개월 구간이면 monthly 그룹핑이어야 함.
        let cal = Calendar.current
        let r = DateRangePreset.threeMonths.resolve(now: cal.date(from: .init(year: 2025, month: 8, day: 15))!, calendar: cal)
        #expect(r.grouping == .monthly)
    }

    @Test
    func custom_oneMonthOrLess_dailyGrouping() {
        // 상황: 한달 이내면 daily
        let cal = Calendar.current
        let s = cal.date(from: .init(year: 2025, month: 8, day: 1))!
        let e = cal.date(from: .init(year: 2025, month: 9, day: 1))!
        let r = DateRange(start: s, end: e, calendar: cal)
        #expect(r.grouping == .daily)
    }

    @Test
    func sixMonths_switchesToMonthlyGrouping() {
        let cal = Calendar.current
        let r = DateRangePreset.sixMonths.resolve(now: cal.date(from: .init(year: 2025, month: 8, day: 15))!, calendar: cal)
        #expect(r.grouping == .monthly)
    }

    @Test
    func thisYear_coversFullYear() {
        let cal = Calendar.current
        let fixed = cal.date(from: DateComponents(year: 2025, month: 6, day: 15))!
        let r = DateRangePreset.thisYear.resolve(now: fixed, calendar: cal)
        #expect(r.start == cal.date(from: DateComponents(year: 2025, month: 1, day: 1)))
        #expect(r.end == cal.date(from: DateComponents(year: 2026, month: 1, day: 1)))
        #expect(r.grouping == .monthly)
    }

    @Test
    func custom_exactSameDateRange_dailyGrouping() {
        let cal = Calendar.current
        let date = cal.date(from: .init(year: 2025, month: 8, day: 15))!
        let r = DateRangePreset.custom(date, date).resolve(calendar: cal)
        #expect(r.start == date)
        #expect(r.end == date)
        #expect(r.grouping == .daily)
    }

    @Test
    func dateRange_inclusiveRange_correctConversion() {
        let cal = Calendar.current
        let start = cal.date(from: .init(year: 2025, month: 8, day: 1))!
        let end = cal.date(from: .init(year: 2025, month: 9, day: 1))!
        let range = DateRange(start: start, end: end, calendar: cal)
        let (incStart, incEnd) = range.inclusiveRange(cal: cal)
        
        #expect(incStart == start)
        #expect(incEnd < end) // end - 1초
    }

    @Test
    func dateRange_monthsCalculation() {
        let cal = Calendar.current
        let start = cal.date(from: .init(year: 2025, month: 6, day: 1))!
        let end = cal.date(from: .init(year: 2025, month: 9, day: 1))!
        let range = DateRange(start: start, end: end, calendar: cal)
        let months = range.months(cal: cal)
        
        #expect(months.count == 3) // Jun, Jul, Aug
        #expect(months[0].month == 6)
        #expect(months[1].month == 7)
        #expect(months[2].month == 8)
    }

    @Test
    func dateRange_crossYearBoundary() {
        let cal = Calendar.current
        let start = cal.date(from: .init(year: 2024, month: 11, day: 1))!
        let end = cal.date(from: .init(year: 2025, month: 2, day: 1))!
        let range = DateRange(start: start, end: end, calendar: cal)
        let months = range.months(cal: cal)
        
        #expect(months.count == 3) // Nov 2024, Dec 2024, Jan 2025
        #expect(months[0].year == 2024 && months[0].month == 11)
        #expect(months[1].year == 2024 && months[1].month == 12)
        #expect(months[2].year == 2025 && months[2].month == 1)
    }

    @Test
    func dateRange_twoMonthsExactly_monthlyGrouping() {
        let cal = Calendar.current
        let start = cal.date(from: .init(year: 2025, month: 8, day: 1))!
        let end = cal.date(from: .init(year: 2025, month: 10, day: 1))!
        let range = DateRange(start: start, end: end, calendar: cal)
        #expect(range.grouping == .monthly)
    }
}
