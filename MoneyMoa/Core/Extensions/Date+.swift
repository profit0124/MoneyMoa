//
//  Date+.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/3/25.
//

import Foundation

// MARK: - Date Extensions for Formatting

extension Date {
    
    /// 스마트 헤더 텍스트로 변환 ("오늘", "어제", "N일전", "yyyy.MM.dd (E)")
    public var transactionListSectionHeader: String {
        let calendar = FormatterManager.shared.koreaCalendar
        let today = Date()
        
        if calendar.isDate(self, inSameDayAs: today) {
            return "오늘"
        }
        
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
           calendar.isDate(self, inSameDayAs: yesterday) {
            return "어제"
        }
        
        let startSelf = calendar.startOfDay(for: self)
        let startToday = calendar.startOfDay(for: today)
        let daysDifference = calendar.dateComponents([.day], from: startSelf, to: startToday).day ?? 0
        
        if daysDifference > 0 && daysDifference <= 3 {
            return "\(daysDifference)일전"
        }
        
        // 일주일 이상 차이나는 경우 DateFormatter 사용
        let formatter = FormatterManager.shared.transactionDateFormatter
        return formatter.string(from: self)
    }
    
    // MARK: - Date Formatting (FormatterManager Integration)
    
    /// 날짜만 포맷 (2025년 8월 20일 (화))
    /// FormatterManager의 formatDate(.dateOnly)를 사용하는 편의 메서드
    public var dateOnlyFormatted: String {
        return FormatterManager.shared.formatDate(self, format: .dateOnly)
    }
    
    /// 시간만 포맷 (14:30)
    /// FormatterManager의 formatDate(.timeOnly)를 사용하는 편의 메서드
    public var timeOnlyFormatted: String {
        return FormatterManager.shared.formatDate(self, format: .timeOnly)
    }
    
    /// 거래 날짜 포맷 (2025.08.20 (화))
    /// FormatterManager의 formatDate(.transaction)를 사용하는 편의 메서드
    public var transactionFormatted: String {
        return FormatterManager.shared.formatDate(self, format: .transaction)
    }
    
}
