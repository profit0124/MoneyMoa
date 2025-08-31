//
//  StatisticsServicesTests.swift
//  MoneyMoaTests
//
//  Created by Sooik Kim on 8/29/25.
//
import Foundation
import Testing
@testable import MoneyMoa

struct ServicesTests {

    // MARK: MA7
    @Test
    func ma7_computesRollingAverage_andKeepsCount() {
        let cal = KST.calendar
        let start = cal.date(from: .init(year: 2025, month: 8, day: 1))!
        let daily = (0..<10).map { i in DailyPointDTO(date: cal.date(byAdding: .day, value: i, to: start)!, amount: Decimal(i+1)) }
        let svc = MovingAverageServiceImpl()
        let out = svc.ma7(daily, calendar: cal)
        #expect(out.count == 10)
        // 7번째 항목(index 6)은 1~7의 평균
        #expect(out[6].amount == Decimal( (1+2+3+4+5+6+7)/7 ))
        // 10번째 항목(index 9)은 4~10의 평균 (sliding window)
        #expect(out[9].amount == Decimal( (4+5+6+7+8+9+10)/7 ))
    }

    @Test
    func ma7_emptyInput_returnsEmpty() {
        let out = MovingAverageServiceImpl().ma7([], calendar: KST.calendar)
        #expect(out.isEmpty)
    }

    @Test
    func ma7_singleItem_returnsSame() {
        let cal = KST.calendar
        let daily = [DailyPointDTO(date: cal.date(from: .init(year: 2025, month: 8, day: 1))!, amount: 100)]
        let out = MovingAverageServiceImpl().ma7(daily, calendar: cal)
        #expect(out.count == 1)
        #expect(out[0].amount == 100)
    }

    @Test
    func ma7_twoItems_correctAverages() {
        let cal = KST.calendar
        let start = cal.date(from: .init(year: 2025, month: 8, day: 1))!
        let daily = [
            DailyPointDTO(date: start, amount: 100),
            DailyPointDTO(date: cal.date(byAdding: .day, value: 1, to: start)!, amount: 200)
        ]
        let out = MovingAverageServiceImpl().ma7(daily, calendar: cal)
        #expect(out.count == 2)
        #expect(out[0].amount == 100) // first day: only itself
        #expect(out[1].amount == 150) // second day: (100+200)/2
    }

    @Test
    func ma7_unsortedInput_sortsBeforeProcessing() {
        let cal = KST.calendar
        let start = cal.date(from: .init(year: 2025, month: 8, day: 1))!
        let daily = [
            DailyPointDTO(date: cal.date(byAdding: .day, value: 2, to: start)!, amount: 30),
            DailyPointDTO(date: start, amount: 10),
            DailyPointDTO(date: cal.date(byAdding: .day, value: 1, to: start)!, amount: 20)
        ]
        let out = MovingAverageServiceImpl().ma7(daily, calendar: cal)
        #expect(out.count == 3)
        #expect(out[0].amount == 10) // 첫 번째는 10
        #expect(out[1].amount == 15) // 두 번째는 (10+20)/2
        #expect(out[2].amount == 20) // 세 번째는 (10+20+30)/3
    }

    @Test
    func ma7_exactlySevenItems_lastItemUsesAllSeven() {
        let cal = KST.calendar
        let start = cal.date(from: .init(year: 2025, month: 8, day: 1))!
        let daily = (0..<7).map { i in 
            DailyPointDTO(date: cal.date(byAdding: .day, value: i, to: start)!, amount: Decimal(i+1))
        }
        let out = MovingAverageServiceImpl().ma7(daily, calendar: cal)
        #expect(out.count == 7)
        #expect(out[6].amount == Decimal((1+2+3+4+5+6+7)/7)) // 7일 평균
    }

    @Test
    func ma7_moreThanSevenItems_slidingWindow() {
        let cal = KST.calendar
        let start = cal.date(from: .init(year: 2025, month: 8, day: 1))!
        let daily = (0..<12).map { i in 
            DailyPointDTO(date: cal.date(byAdding: .day, value: i, to: start)!, amount: Decimal(i+1))
        }
        let out = MovingAverageServiceImpl().ma7(daily, calendar: cal)
        #expect(out.count == 12)
        // 8일째는 2~8일의 평균
        #expect(out[7].amount == Decimal((2+3+4+5+6+7+8)/7))
        // 12일째는 6~12일의 평균
        #expect(out[11].amount == Decimal((6+7+8+9+10+11+12)/7))
    }

    @Test
    func ma7_zeroAmounts_handledCorrectly() {
        let cal = KST.calendar
        let start = cal.date(from: .init(year: 2025, month: 8, day: 1))!
        let daily = [
            DailyPointDTO(date: start, amount: 0),
            DailyPointDTO(date: cal.date(byAdding: .day, value: 1, to: start)!, amount: 100),
            DailyPointDTO(date: cal.date(byAdding: .day, value: 2, to: start)!, amount: 0)
        ]
        let out = MovingAverageServiceImpl().ma7(daily, calendar: cal)
        #expect(out.count == 3)
        #expect(out[0].amount == 0)
        #expect(out[1].amount == 50) // (0+100)/2
        #expect(out[2].amount == Decimal(100)/Decimal(3)) // (0+100+0)/3
    }

    @Test
    func ma7_preservesDateOrder() {
        let cal = KST.calendar
        let start = cal.date(from: .init(year: 2025, month: 8, day: 1))!
        let daily = (0..<5).map { i in 
            DailyPointDTO(date: cal.date(byAdding: .day, value: i, to: start)!, amount: Decimal(i+1))
        }
        let out = MovingAverageServiceImpl().ma7(daily, calendar: cal)
        
        for i in 0..<(out.count-1) {
            #expect(out[i].date <= out[i+1].date)
        }
    }

    // MARK: Burndown
    @Test
    func burndown_buildsExpectedVsActual_forMonth() {
        let cal = KST.calendar
        let start = cal.date(from: .init(year: 2025, month: 8, day: 1))!
        let daily: [DailyPointDTO] = [
            .init(date: start, amount: 10),
            .init(date: cal.date(byAdding: .day, value: 1, to: start)!, amount: 20)
        ]
        let out = BurndownServiceImpl().make(expectedMonthlyBudget: 300, dailyExpenses: daily, calendar: cal)
        #expect(!out.isEmpty)
        #expect(out[0].actualCumulative == 10)
        #expect(out[1].actualCumulative == 30)
        #expect(out.last!.expectedCumulative > 0)
    }

    @Test
    func burndown_emptyInput_returnsEmpty() {
        let out = BurndownServiceImpl().make(expectedMonthlyBudget: 1000, dailyExpenses: [], calendar: KST.calendar)
        #expect(out.isEmpty)
    }

    @Test
    func burndown_singleDayExpense_correctCalculation() {
        let cal = KST.calendar
        let start = cal.date(from: .init(year: 2025, month: 8, day: 1))!
        let daily = [DailyPointDTO(date: start, amount: 100)]
        let out = BurndownServiceImpl().make(expectedMonthlyBudget: 3100, dailyExpenses: daily, calendar: cal) // 31일 × 100 = 3100
        
        #expect(out.count == 31) // August has 31 days
        #expect(out[0].day == 1)
        #expect(out[0].expectedCumulative == 100)
        #expect(out[0].actualCumulative == 100)
        #expect(out[30].day == 31)
        #expect(out[30].expectedCumulative == 3100)
        #expect(out[30].actualCumulative == 100) // only one day has expense
    }

    @Test
    func burndown_multipleDaysWithGaps_fillsGaps() {
        let cal = KST.calendar
        let start = cal.date(from: .init(year: 2025, month: 8, day: 1))!
        let daily = [
            DailyPointDTO(date: start, amount: 50), // Day 1
            DailyPointDTO(date: cal.date(byAdding: .day, value: 2, to: start)!, amount: 100) // Day 3
        ]
        let out = BurndownServiceImpl().make(expectedMonthlyBudget: 3100, dailyExpenses: daily, calendar: cal)
        
        #expect(out.count == 31)
        #expect(out[0].actualCumulative == 50) // Day 1
        #expect(out[1].actualCumulative == 50) // Day 2 (no expense, same cumulative)
        #expect(out[2].actualCumulative == 150) // Day 3 (50+100)
    }

    @Test
    func burndown_sameDayMultipleExpenses_sumsCorrectly() {
        let cal = KST.calendar
        let start = cal.date(from: .init(year: 2025, month: 8, day: 1))!
        let daily = [
            DailyPointDTO(date: start, amount: 50),
            DailyPointDTO(date: start, amount: 30), // same day
            DailyPointDTO(date: start, amount: 20)  // same day
        ]
        let out = BurndownServiceImpl().make(expectedMonthlyBudget: 3100, dailyExpenses: daily, calendar: cal)
        
        #expect(out.count == 31)
        #expect(out[0].actualCumulative == 100) // 50+30+20
        #expect(out[1].actualCumulative == 100) // no additional expense
    }

    @Test
    func burndown_februaryLeapYear_correctDayCount() {
        let cal = KST.calendar
        let start = cal.date(from: .init(year: 2024, month: 2, day: 1))! // 2024 is leap year
        let daily = [DailyPointDTO(date: start, amount: 100)]
        let out = BurndownServiceImpl().make(expectedMonthlyBudget: 2900, dailyExpenses: daily, calendar: cal) // 29 × 100
        
        #expect(out.count == 29) // February 2024 has 29 days
        #expect(out[28].day == 29)
        #expect(out[28].expectedCumulative == 2900)
    }

    @Test
    func burndown_februaryNonLeapYear_correctDayCount() {
        let cal = KST.calendar
        let start = cal.date(from: .init(year: 2025, month: 2, day: 1))! // 2025 is not leap year
        let daily = [DailyPointDTO(date: start, amount: 100)]
        let out = BurndownServiceImpl().make(expectedMonthlyBudget: 2800, dailyExpenses: daily, calendar: cal) // 28 × 100
        
        #expect(out.count == 28) // February 2025 has 28 days
        #expect(out[27].day == 28)
        #expect(out[27].expectedCumulative == 2800)
    }

    @Test
    func burndown_zeroBudget_correctExpectedValues() {
        let cal = KST.calendar
        let start = cal.date(from: .init(year: 2025, month: 8, day: 1))!
        let daily = [DailyPointDTO(date: start, amount: 100)]
        let out = BurndownServiceImpl().make(expectedMonthlyBudget: 0, dailyExpenses: daily, calendar: cal)
        
        #expect(out.count == 31)
        #expect(out[0].expectedCumulative == 0)
        #expect(out[30].expectedCumulative == 0)
        #expect(out[0].actualCumulative == 100)
    }

    @Test
    func burndown_expensesFromDifferentMonths_usesOnlyFirstMonth() {
        let cal = KST.calendar
        let start = cal.date(from: .init(year: 2025, month: 8, day: 1))!
        let nextMonth = cal.date(from: .init(year: 2025, month: 9, day: 1))!
        let daily = [
            DailyPointDTO(date: start, amount: 100),
            DailyPointDTO(date: nextMonth, amount: 200) // Different month
        ]
        let out = BurndownServiceImpl().make(expectedMonthlyBudget: 3100, dailyExpenses: daily, calendar: cal)
        
        #expect(out.count == 31) // Still August days
        // The next month expense shouldn't affect the calculation since it's outside the month range
    }

    @Test
    func burndown_fractionalBudgetPerDay_correctCalculation() {
        let cal = KST.calendar
        let start = cal.date(from: .init(year: 2025, month: 8, day: 1))!
        let daily = [DailyPointDTO(date: start, amount: 33)]
        let out = BurndownServiceImpl().make(expectedMonthlyBudget: 100, dailyExpenses: daily, calendar: cal) // 100/31 per day
        
        #expect(out.count == 31)
        let expectedPerDay = Decimal(100) / Decimal(31)
        #expect(out[0].expectedCumulative == expectedPerDay)
        #expect(out[2].expectedCumulative == expectedPerDay * Decimal(3))
    }

    @Test
    func burndown_unsortedExpenses_sortsCorrectly() {
        let cal = KST.calendar
        let start = cal.date(from: .init(year: 2025, month: 8, day: 1))!
        let daily = [
            DailyPointDTO(date: cal.date(byAdding: .day, value: 2, to: start)!, amount: 200), // Day 3
            DailyPointDTO(date: start, amount: 100), // Day 1
            DailyPointDTO(date: cal.date(byAdding: .day, value: 1, to: start)!, amount: 150) // Day 2
        ]
        let out = BurndownServiceImpl().make(expectedMonthlyBudget: 3100, dailyExpenses: daily, calendar: cal)
        
        #expect(out[0].actualCumulative == 100) // Day 1
        #expect(out[1].actualCumulative == 250) // Day 2: 100+150
        #expect(out[2].actualCumulative == 450) // Day 3: 100+150+200
    }

    // MARK: BudgetCompleteness
    @Test
    func budgetCompleteness_filtersOnlyCompleteCategories() {
        let cal = KST.calendar
        let s = cal.date(from: .init(year: 2025, month: 6, day: 1))!
        let e = cal.date(from: .init(year: 2025, month: 9, day: 1))!
        let range = DateRange(start: s, end: e, calendar: cal)
        let months = cal.yearMonths(in: range)
        let budgets: [String: [YearMonth: Decimal]] = [
            "food": Dictionary(uniqueKeysWithValues: months.map { ($0, 1) }),
            "shop": [months[0]: 1, months[2]: 1] // 일부 누락
        ]
        let ok = BudgetCompletenessServiceImpl().completeCategories(budgets: budgets, months: months)
        #expect(ok == ["food"])
    }

    @Test
    func budgetCompleteness_emptyMonths_returnsEmptySet() {
        let ok = BudgetCompletenessServiceImpl().completeCategories(budgets: ["any": [:]], months: [])
        #expect(ok.isEmpty)
    }

    @Test
    func weeklyPattern_normalizesCountByMonthCount() {
        let cal = KST.calendar
        // 두 달에 걸친 동일 요일 4건 → 평균건수는 4/2 = 2 로 정규화
        let d1 = cal.date(from: .init(year: 2025, month: 7, day: 6))! // 일
        let d2 = cal.date(from: .init(year: 2025, month: 7, day: 13))!
        let d3 = cal.date(from: .init(year: 2025, month: 8, day: 3))!
        let d4 = cal.date(from: .init(year: 2025, month: 8, day: 10))!
        let daily: [DailyPointDTO] = [d1, d2, d3, d4].map { .init(date: $0, amount: 100) }

        let pat = WeeklyPatternService.make(daily, calendar: cal)
        let sunday = pat.days.first { $0.weekday == 1 }!
        #expect(sunday.avgAmount == 100) // 동일 금액 4건의 평균
        #expect(sunday.avgCount == 2)    // 4건 / 2개월
    }

    @Test
    func weeklyPattern_emptyInput_returnsEmptyDays() {
        let pat = WeeklyPatternService.make([], calendar: KST.calendar)
        #expect(pat.days.isEmpty)
    }

    @Test
    func weeklyPattern_singleMonth_correctAvgCount() {
        let cal = KST.calendar
        // 같은 달 내 월요일 3건
        let d1 = cal.date(from: .init(year: 2025, month: 8, day: 4))! // 월
        let d2 = cal.date(from: .init(year: 2025, month: 8, day: 11))!
        let d3 = cal.date(from: .init(year: 2025, month: 8, day: 18))!
        let daily: [DailyPointDTO] = [d1, d2, d3].map { .init(date: $0, amount: 50) }

        let pat = WeeklyPatternService.make(daily, calendar: cal)
        let monday = pat.days.first { $0.weekday == 2 }! // Monday is weekday 2
        #expect(monday.avgAmount == 50)
        #expect(monday.avgCount == 3.0) // 3건 / 1개월
    }

    @Test
    func weeklyPattern_multipleWeekdays_separateCalculation() {
        let cal = KST.calendar
        let monday = cal.date(from: .init(year: 2025, month: 8, day: 4))!
        let tuesday = cal.date(from: .init(year: 2025, month: 8, day: 5))!
        let friday = cal.date(from: .init(year: 2025, month: 8, day: 8))!
        
        let daily: [DailyPointDTO] = [
            .init(date: monday, amount: 100),
            .init(date: tuesday, amount: 200),
            .init(date: friday, amount: 300)
        ]

        let pat = WeeklyPatternService.make(daily, calendar: cal)
        
        let mon = pat.days.first { $0.weekday == 2 }! // Monday
        let tue = pat.days.first { $0.weekday == 3 }! // Tuesday
        let fri = pat.days.first { $0.weekday == 6 }! // Friday
        
        #expect(mon.avgAmount == 100)
        #expect(tue.avgAmount == 200)
        #expect(fri.avgAmount == 300)
        #expect(mon.avgCount == 1.0)
        #expect(tue.avgCount == 1.0)
        #expect(fri.avgCount == 1.0)
    }

    @Test
    func weeklyPattern_sameWeekdayDifferentAmounts_correctAverage() {
        let cal = KST.calendar
        let d1 = cal.date(from: .init(year: 2025, month: 8, day: 4))! // 월
        let d2 = cal.date(from: .init(year: 2025, month: 8, day: 11))!
        
        let daily: [DailyPointDTO] = [
            .init(date: d1, amount: 100),
            .init(date: d2, amount: 200)
        ]

        let pat = WeeklyPatternService.make(daily, calendar: cal)
        let monday = pat.days.first { $0.weekday == 2 }!
        #expect(monday.avgAmount == 150) // (100+200)/2
        #expect(monday.avgCount == 2.0)
    }

    @Test
    func weeklyPattern_allSevenDays_correctStructure() {
        let cal = KST.calendar
        let pat = WeeklyPatternService.make([
            .init(date: cal.date(from: .init(year: 2025, month: 8, day: 3))!, amount: 10), // 일
            .init(date: cal.date(from: .init(year: 2025, month: 8, day: 4))!, amount: 20), // 월
            .init(date: cal.date(from: .init(year: 2025, month: 8, day: 5))!, amount: 30), // 화
            .init(date: cal.date(from: .init(year: 2025, month: 8, day: 6))!, amount: 40), // 수
            .init(date: cal.date(from: .init(year: 2025, month: 8, day: 7))!, amount: 50), // 목
            .init(date: cal.date(from: .init(year: 2025, month: 8, day: 8))!, amount: 60), // 금
            .init(date: cal.date(from: .init(year: 2025, month: 8, day: 9))!, amount: 70)  // 토
        ], calendar: cal)
        
        #expect(pat.days.count == 7)
        #expect(pat.days.map { $0.weekday }.sorted() == [1, 2, 3, 4, 5, 6, 7])
        #expect(pat.days.first { $0.weekday == 1 }?.avgAmount == 10) // 일
        #expect(pat.days.first { $0.weekday == 7 }?.avgAmount == 70) // 토
    }

    @Test
    func weeklyPattern_zeroAmountDays_handledCorrectly() {
        let cal = KST.calendar
        let daily: [DailyPointDTO] = [
            .init(date: cal.date(from: .init(year: 2025, month: 8, day: 4))!, amount: 0),
            .init(date: cal.date(from: .init(year: 2025, month: 8, day: 5))!, amount: 100)
        ]

        let pat = WeeklyPatternService.make(daily, calendar: cal)
        let monday = pat.days.first { $0.weekday == 2 }! // 0 amount day
        let tuesday = pat.days.first { $0.weekday == 3 }! // 100 amount day
        
        #expect(monday.avgAmount == 0)
        #expect(monday.avgCount == 1.0)
        #expect(tuesday.avgAmount == 100)
        #expect(tuesday.avgCount == 1.0)
    }
}
