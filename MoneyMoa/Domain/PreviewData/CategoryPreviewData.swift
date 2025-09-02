//
//  CategoryPreviewData.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/2/25.
//

import Foundation
import SwiftUI

public struct CategoryPreviewData {
    public static let categoryRatios: [CategoryRatioDTO] = {
        let colors: [Color] = [.red, .blue, .green, .orange, .purple]
        let categories = [
            ("식비", Decimal(980000), 0.35),
            ("교통", Decimal(420000), 0.15),
            ("쇼핑", Decimal(560000), 0.20),
            ("문화", Decimal(336000), 0.12),
            ("기타", Decimal(504000), 0.18)
        ]
        
        return categories.enumerated().map { index, value in
            CategoryRatioDTO(
                categoryId: "\(index + 1)",
                categoryName: value.0,
                ratio: value.2,
                amount: value.1,
                color: colors[index % colors.count],
                previousMonthChange: Double.random(in: -20.0...20.0)
            )
        }
    }()
    
    public static let categoryMonthlyPoints: [CategoryMonthlyPointDTO] = {
        let calendar = Calendar.current
        let today = Date()
        let categories = [
            ("1", "식비", Color.red),
            ("2", "교통", Color.blue),
            ("3", "쇼핑", Color.green),
            ("4", "문화", Color.orange),
            ("5", "기타", Color.purple)
        ]
        
        var points: [CategoryMonthlyPointDTO] = []
        
        for monthsBack in 0..<6 {
            guard let monthStart = calendar.date(byAdding: .month, value: -monthsBack, to: today),
                  let startOfMonth = calendar.dateInterval(of: .month, for: monthStart)?.start else {
                continue
            }
            
            for (index, categoryData) in categories.enumerated() {
                let (id, name, color) = categoryData
                let baseAmount = [800000, 300000, 500000, 200000, 150000][index]
                let variation = Int.random(in: -50000...100000)
                let expense = Decimal(max(0, baseAmount + variation))
                
                points.append(CategoryMonthlyPointDTO(
                    categoryId: id,
                    categoryName: name,
                    monthStart: startOfMonth,
                    expense: expense,
                    color: color
                ))
            }
        }
        
        return points.sorted { $0.monthStart < $1.monthStart }
    }()
}
