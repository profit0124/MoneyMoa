//
//  StatisticsDTOs.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/28/25.
//

import Foundation
import SwiftUI

// MARK: - Overview (섹션 1)
/// 월별 수입/지출 포인트 (그룹 바/라인에 사용)
public struct MonthlyPointDTO: Identifiable, Sendable, Hashable {
    public let id = UUID()
    public let monthStart: Date    // 해당 월 1일 00:00
    public let income: Decimal     // 월 수입 합
    public let expense: Decimal    // 월 지출 합
    public let savingsRate: Double // 저축률 = (수입-지출)/수입
    public let previousMonthChange: Double // 전월 대비 순수입 증감률
    
    // UI 계산 필드
    public var netIncome: Decimal { income - expense }
    
    public init(
        monthStart: Date, 
        income: Decimal, 
        expense: Decimal,
        savingsRate: Double = 0,
        previousMonthChange: Double = 0
    ) {
        self.monthStart = monthStart
        self.income = income
        self.expense = expense
        self.savingsRate = savingsRate
        self.previousMonthChange = previousMonthChange
    }
}

/// 일별 지출 포인트 (라인/MA7 계산에 사용)
public struct DailyPointDTO: Identifiable, Sendable, Hashable {
    public let id = UUID()
    public let date: Date
    public let amount: Decimal
    public let movingAverage: Decimal // 7일 이동평균
    public let isWeekend: Bool
    
    public init(
        date: Date, 
        amount: Decimal,
        movingAverage: Decimal = 0,
        isWeekend: Bool = false
    ) {
        self.date = date
        self.amount = amount
        self.movingAverage = movingAverage
        self.isWeekend = isWeekend
    }
}

/// 버던 차트용 기대/실제 누적 포인트 (1..N일)
public struct BurndownPointDTO: Identifiable, Sendable, Hashable {
    public let id = UUID()
    public let day: Int
    public let date: Date // UI에서 날짜 축 표시용
    public let expectedCumulative: Decimal
    public let actualCumulative: Decimal
    
    public init(
        day: Int,
        date: Date,
        expectedCumulative: Decimal,
        actualCumulative: Decimal
    ) {
        self.day = day
        self.date = date
        self.expectedCumulative = expectedCumulative
        self.actualCumulative = actualCumulative
    }
}

// MARK: - Category (섹션 2)
/// 카테고리 비율 도넛 차트용
public struct CategoryRatioDTO: Identifiable, Sendable, Hashable {
    public let id = UUID()
    public let categoryId: String
    public let categoryName: String
    public let ratio: Double   // 0..1
    public let amount: Decimal // 비율 산출의 분자(금액)
    public let color: Color    // UI 표시용 색상
    public let previousMonthChange: Double // 전월 대비 증감률
    
    public init(
        categoryId: String,
        categoryName: String,
        ratio: Double,
        amount: Decimal,
        color: Color = .blue,
        previousMonthChange: Double = 0
    ) {
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.ratio = ratio
        self.amount = amount
        self.color = color
        self.previousMonthChange = previousMonthChange
    }
}

/// 카테고리×월 스택 바/멀티라인용
public struct CategoryMonthlyPointDTO: Identifiable, Sendable, Hashable {
    public let id = UUID()
    public let categoryId: String
    public let categoryName: String
    public let monthStart: Date
    public let expense: Decimal
    public let color: Color    // UI 표시용 색상
    
    public init(
        categoryId: String,
        categoryName: String,
        monthStart: Date,
        expense: Decimal,
        color: Color = .blue
    ) {
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.monthStart = monthStart
        self.expense = expense
        self.color = color
    }
}

// MARK: - Payment Method (섹션 3)
/// 결제수단 비율/평균 금액 차트용
public struct PaymentMethodRatioDTO: Identifiable, Sendable, Hashable {
    public let id = UUID()
    public let methodId: String
    public let methodName: String
    public let ratio: Double   // 0..1
    public let amount: Decimal // 총액
    public let count: Int      // 건수(평균 산출에 사용)
    public let averageAmount: Decimal // 평균 거래 금액
    public let color: Color    // UI 표시용 색상
    
    public init(
        methodId: String,
        methodName: String,
        ratio: Double,
        amount: Decimal,
        count: Int,
        color: Color = .blue
    ) {
        self.methodId = methodId
        self.methodName = methodName
        self.ratio = ratio
        self.amount = amount
        self.count = count
        self.averageAmount = count > 0 ? amount / Decimal(count) : 0
        self.color = color
    }
}

// MARK: - Pattern (섹션 4)
/// 요일별 패턴(평균 지출/건수)
public struct WeeklyPatternDTO: Sendable, Hashable {
    public struct Day: Sendable, Hashable {
        public let weekday: Int      // 1=일 ... 7=토 (Calendar 규약)
        public let avgAmount: Decimal
        public let avgCount: Double  // 월수 정규화된 평균 건수
    }
    public let days: [Day]
}

/// 거래 타입 비율(수입/지출/이체)
public struct TransactionTypeRatioDTO: Sendable, Hashable {
    public let income: Double
    public let expense: Double
}

/// 가맹점 랭킹 테이블
public struct MerchantRankingDTO: Identifiable, Sendable, Hashable {
    public let id = UUID()
    
    public struct Entry: Identifiable, Sendable, Hashable {
        public let id = UUID()
        public let rank: Int
        public let merchant: String
        public let count: Int
        public let total: Decimal
        public let averageAmount: Decimal // 평균 거래 금액
        
        public init(rank: Int, merchant: String, count: Int, total: Decimal) {
            self.rank = rank
            self.merchant = merchant
            self.count = count
            self.total = total
            self.averageAmount = count > 0 ? total / Decimal(count) : 0
        }
    }
    public let entries: [Entry]
    
    public init(entries: [Entry]) {
        self.entries = entries
    }
}

// MARK: - Budget (섹션 5)
public enum BudgetStatus: Sendable { case exceeded, warning, normal }

/// 월별 예산 vs 지출 (콤보차트)
public struct BudgetVsExpenseDTO: Sendable, Hashable {
    public let monthStart: Date
    public let budget: Decimal
    public let expense: Decimal
}

/// 카테고리별 예산 vs 지출 게이지(완전 예산 카테고리만)
public struct CategoryBudgetVsExpenseDTO: Identifiable, Sendable, Hashable {
    public let id = UUID()
    public let categoryId: String
    public let categoryName: String
    public let budget: Decimal
    public let expense: Decimal
    public let usageRate: Double // 지출/예산 (fraction)
    public let status: BudgetStatus
    public let monthCount: Int
    public let color: Color    // UI 표시용 색상
    
    public init(
        categoryId: String,
        categoryName: String,
        budget: Decimal,
        expense: Decimal,
        usageRate: Double,
        status: BudgetStatus,
        monthCount: Int,
        color: Color = .blue
    ) {
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.budget = budget
        self.expense = expense
        self.usageRate = usageRate
        self.status = status
        self.monthCount = monthCount
        self.color = color
    }
}

// MARK: - Dashboard 조립체
public struct StatisticsDashboardDTO: Sendable {
    public struct Overview: Sendable {
        public let monthly: [MonthlyPointDTO]
        public let daily: [DailyPointDTO]        // (필요 시 MA7로 치환된 시리즈)
        public let burndown: [BurndownPointDTO]  // 단일 월 선택 시 유효
    }
    public struct Category: Sendable {
        public let ratios: [CategoryRatioDTO]
        public let monthlyStacks: [CategoryMonthlyPointDTO] // 완전 예산 카테고리만 필터링된 시리즈
    }
    public struct Payment: Sendable { public let ratios: [PaymentMethodRatioDTO] }
    public struct Pattern: Sendable {
        public let weekly: WeeklyPatternDTO
        public let typeRatio: TransactionTypeRatioDTO
        public let merchants: MerchantRankingDTO
    }
    public struct Budget: Sendable {
        public let byMonth: [BudgetVsExpenseDTO]
        public let byCategory: [CategoryBudgetVsExpenseDTO]
    }

    public let overview: Overview
    public let category: Category
    public let payment: Payment
    public let pattern: Pattern
    public let budget: Budget
    
    public init(
        overview: Overview,
        category: Category,
        payment: Payment,
        pattern: Pattern,
        budget: Budget
    ) {
        self.overview = overview
        self.category = category
        self.payment = payment
        self.pattern = pattern
        self.budget = budget
    }
}

// MARK: - Preview Data Extensions

extension MonthlyPointDTO {
    static var previewData: [MonthlyPointDTO] {
        let calendar = Calendar.current
        let today = Date()
        var data: [MonthlyPointDTO] = []

        for monthsBack in 0..<6 {
            guard
                let monthStart = calendar.date(
                    byAdding: .month,
                    value: -monthsBack,
                    to: today
                ),
                let firstOfMonth = calendar.dateInterval(
                    of: .month,
                    for: monthStart
                )?.start
            else {
                continue
            }

            let baseIncome = Decimal(3_500_000)
            let baseExpense = Decimal(2_800_000)
            
            let incomeVariation = Decimal(Int.random(in: -500000...500000))
            let expenseVariation = Decimal(Int.random(in: -400000...600000))
            
            let income = baseIncome + incomeVariation
            let expense = baseExpense + expenseVariation
            let netIncome = income - expense
            let savingsRate = income > 0 ? Double(truncating: (netIncome / income) as NSDecimalNumber) * 100 : 0
            
            let previousMonthChange = data.isEmpty ? 0.0 : Double.random(in: -15.0...15.0)

            data.append(MonthlyPointDTO(
                monthStart: firstOfMonth,
                income: income,
                expense: expense,
                savingsRate: savingsRate,
                previousMonthChange: previousMonthChange
            ))
        }
        
        return data.reversed()
    }
}

extension DailyPointDTO {
    static var previewData: [DailyPointDTO] {
        let calendar = Calendar.current
        let today = Date()
        var data: [DailyPointDTO] = []

        for daysBack in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: -daysBack, to: today) else {
                continue
            }
            
            let isWeekend = calendar.isDateInWeekend(date)
            let baseAmount = isWeekend ? Decimal(120000) : Decimal(80000)
            let variation = Decimal(Int.random(in: -30000...50000))
            let amount = max(0, baseAmount + variation)
            
            let movingAverage = data.count >= 6 ? 
                data.suffix(6).reduce(amount) { $0 + $1.amount } / 7 : amount

            data.append(DailyPointDTO(
                date: date,
                amount: amount,
                movingAverage: movingAverage,
                isWeekend: isWeekend
            ))
        }
        
        return data.reversed()
    }
}

extension BurndownPointDTO {
    static var previewData: [BurndownPointDTO] {
        let calendar = Calendar.current
        let today = Date()
        let monthlyBudget = Decimal(2_500_000)
        let daysInMonth = 30
        
        return (1...daysInMonth).compactMap { day in
            guard let date = calendar.date(byAdding: .day, value: day - daysInMonth, to: today) else {
                return nil
            }
            
            let expectedDaily = monthlyBudget / Decimal(daysInMonth)
            let expectedCumulative = expectedDaily * Decimal(day)
            let actualCumulative = expectedCumulative * Decimal(Double.random(in: 0.8...1.2))
            
            return BurndownPointDTO(
                day: day,
                date: date,
                expectedCumulative: expectedCumulative,
                actualCumulative: actualCumulative
            )
        }
    }
}

extension CategoryRatioDTO {
    static var previewData: [CategoryRatioDTO] {
        let colors: [Color] = [.red, .blue, .green, .orange, .purple]
        let categories = [
            ("식비", Decimal(980000), 0.35),
            ("교통", Decimal(420000), 0.15),
            ("쇼핑", Decimal(560000), 0.20),
            ("문화", Decimal(336000), 0.12),
            ("기타", Decimal(504000), 0.18)
        ]
        
        return categories.enumerated().map { index, (name, amount, ratio) in
            CategoryRatioDTO(
                categoryId: "\(index + 1)",
                categoryName: name,
                ratio: ratio,
                amount: amount,
                color: colors[index % colors.count],
                previousMonthChange: Double.random(in: -20.0...20.0)
            )
        }
    }
}
