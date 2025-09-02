//
//  BudgetPreviewData.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/2/25.
//

import Foundation
import SwiftUI

public struct BudgetPreviewData {
    public static let budgetVsExpense: [BudgetVsExpenseDTO] = {
        let calendar = Calendar.current
        let today = Date()
        var data: [BudgetVsExpenseDTO] = []
        
        for i in 0..<6 {
            guard let monthStart = calendar.date(byAdding: .month, value: -i, to: today),
                  let startOfMonth = calendar.dateInterval(of: .month, for: monthStart)?.start else { continue }
            
            let budget = Decimal(2800000 + Int.random(in: -200000...200000))
            let expense = budget * Decimal(Double.random(in: 0.8...1.2))
            
            data.append(BudgetVsExpenseDTO(
                monthStart: startOfMonth,
                budget: budget,
                expense: expense
            ))
        }
        
        return data.reversed()
    }()
    
    public static let categoryBudgetVsExpense: [CategoryBudgetVsExpenseDTO] = {
        let categories = [
            ("식비", Decimal(800000), Decimal(750000)),
            ("교통", Decimal(300000), Decimal(320000)),
            ("쇼핑", Decimal(500000), Decimal(480000)),
            ("문화", Decimal(200000), Decimal(250000)),
            ("의료", Decimal(150000), Decimal(130000))
        ]
        
        return categories.enumerated().map { (index, categoryData) in
            let (name, budget, expense) = categoryData
            return CategoryBudgetVsExpenseDTO(
                categoryId: "\(index + 1)",
                categoryName: name,
                budget: budget,
                expense: expense,
                usageRate: Double(truncating: (expense / budget) as NSDecimalNumber),
                status: expense > budget ? .exceeded : (expense > budget * Decimal(0.8) ? .warning : .normal),
                monthCount: 1,
                color: StatisticsColorScheme.categoryColor(at: index)
            )
        }
    }()
}
