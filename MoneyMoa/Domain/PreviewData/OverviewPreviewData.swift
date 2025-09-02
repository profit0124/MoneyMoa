//
//  OverviewPreviewData.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/2/25.
//

import Foundation
import SwiftUI

public struct OverviewPreviewData {
    public static let monthlyPoints: [MonthlyPointDTO] = {
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
    }()
    
    public static let dailyPoints: [DailyPointDTO] = {
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
    }()
    
    public static let burndownPoints: [BurndownPointDTO] = {
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
                actualCumulative: actualCumulative,
                monthlyBudget: monthlyBudget
            )
        }
    }()
}
