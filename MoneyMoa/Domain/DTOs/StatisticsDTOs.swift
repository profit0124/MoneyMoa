//
//  StatisticsDTOs.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/28/25.
//

import Foundation

// MARK: - Overview (섹션 1)
/// 월별 수입/지출 포인트 (그룹 바/라인에 사용)
public struct MonthlyPointDTO: Sendable, Hashable {
    public let monthStart: Date    // 해당 월 1일 00:00
    public let income: Decimal     // 월 수입 합
    public let expense: Decimal    // 월 지출 합
    public init(monthStart: Date, income: Decimal, expense: Decimal) {
        self.monthStart = monthStart
        self.income = income
        self.expense = expense
    }
}

/// 일별 지출 포인트 (라인/MA7 계산에 사용)
public struct DailyPointDTO: Sendable, Hashable {
    public let date: Date
    public let amount: Decimal
    public init(date: Date, amount: Decimal) {
        self.date = date
        self.amount = amount
    }
}

/// 버던 차트용 기대/실제 누적 포인트 (1..N일)
public struct BurndownPointDTO: Sendable, Hashable {
    public let day: Int
    public let expectedCumulative: Decimal
    public let actualCumulative: Decimal
}

// MARK: - Category (섹션 2)
/// 카테고리 비율 도넛 차트용
public struct CategoryRatioDTO: Sendable, Hashable {
    public let categoryId: String
    public let categoryName: String
    public let ratio: Double   // 0..1
    public let amount: Decimal // 비율 산출의 분자(금액)
}

/// 카테고리×월 스택 바/멀티라인용
public struct CategoryMonthlyPointDTO: Sendable, Hashable {
    public let categoryId: String
    public let categoryName: String
    public let monthStart: Date
    public let expense: Decimal
}

// MARK: - Payment Method (섹션 3)
/// 결제수단 비율/평균 금액 차트용
public struct PaymentMethodRatioDTO: Sendable, Hashable {
    public let methodId: String
    public let methodName: String
    public let ratio: Double   // 0..1
    public let amount: Decimal // 총액
    public let count: Int      // 건수(평균 산출에 사용)
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
    public let transfer: Double
}

/// 가맹점 랭킹 테이블
public struct MerchantRankingDTO: Sendable, Hashable {
    public struct Entry: Sendable, Hashable {
        public let rank: Int
        public let merchant: String
        public let count: Int
        public let total: Decimal
    }
    public let entries: [Entry]
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
public struct CategoryBudgetVsExpenseDTO: Sendable, Hashable {
    public let categoryId: String
    public let categoryName: String
    public let budget: Decimal
    public let expense: Decimal
    public let usageRate: Double // 지출/예산 (fraction)
    public let status: BudgetStatus
    public let monthCount: Int
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
}
