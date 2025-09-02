//
//  PatternPreviewData.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/2/25.
//

import Foundation

public struct PatternPreviewData {
    public static let weeklyPattern: WeeklyPatternDTO = {
        let weekdayAmounts: [Decimal] = [85000, 65000, 75000, 90000, 95000, 120000, 110000]
        let days = weekdayAmounts.enumerated().map { index, amount in
            WeeklyPatternDTO.Day(
                weekday: index + 1,
                avgAmount: amount,
                avgCount: Double.random(in: 1.5...4.0)
            )
        }
        return WeeklyPatternDTO(days: days)
    }()
    
    public static let transactionTypeRatio = TransactionTypeRatioDTO(
        income: 0.15,
        expense: 0.85
    )
}
