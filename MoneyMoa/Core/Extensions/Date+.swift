//
//  Date+.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/3/25.
//

import Foundation

// MARK: - Date Extensions for Formatting

extension Date {
    
    /// 스마트 헤더 텍스트로 변환 (로케일별 대응)
    /// - 한국어: "오늘", "어제", "N일전", "yyyy.MM.dd (E)"
    /// - 영어: "Today", "Yesterday", "N days ago", "MMM dd, yyyy (E)"
    public var transactionListSectionHeader: String {
        let calendar = Calendar.current
        let today = Date()
        /// 현재 로케일이 한국어인지 확인
        let isKoreanLocale: Bool = Locale.current.language.languageCode == "ko"

        if calendar.isDate(self, inSameDayAs: today) {
            return isKoreanLocale ? "오늘" : "Today"
        }
        
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
           calendar.isDate(self, inSameDayAs: yesterday) {
            return isKoreanLocale ? "어제" : "Yesterday"
        }
        
        let startSelf = calendar.startOfDay(for: self)
        let startToday = calendar.startOfDay(for: today)
        let daysDifference = calendar.dateComponents([.day], from: startSelf, to: startToday).day ?? 0
        
        if daysDifference > 0 && daysDifference <= 3 {
            return isKoreanLocale ? "\(daysDifference)일전" : "\(daysDifference) days ago"
        }
        
        // 4일 이상 차이나는 경우 DateFormatter 사용
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

// MARK: - TimeZone Conversion Extensions

extension Date {

    /// 현재 Date를 UTC 절대시점으로 변환
    /// 현재 기기 시간대 기준으로 해석된 Date를 UTC 절대시점으로 변환
    public var toUTC: Date {
        // 현재 기기의 Calendar로 컴포넌트 추출
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second, .nanosecond], from: self)
        
        // UTC Calendar로 같은 컴포넌트를 절대시점으로 해석
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!
        
        return utcCalendar.date(from: components) ?? self
    }

    /// UTC 절대시점을 특정 TimeContext의 로컬 시간으로 변환
    /// 예: UTC "05:00" → Seoul Context → "14:00" (KST 표시용)
    public func toTimeContext(_ context: TransactionTimeContext) -> Date {
        // UTC에서 컴포넌트 추출
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!
        
        let components = utcCalendar.dateComponents([.year, .month, .day, .hour, .minute, .second, .nanosecond], from: self)
        
        // 같은 컴포넌트를 target TimeZone에서 해석
        return context.calendar.date(from: components) ?? self
    }

    /// UTC 절대시점을 현재 기기 시간대로 변환
    /// 현재 TimeZone 기준으로 표시할 Date 반환
    public var toCurrent: Date {
        // UTC에서 컴포넌트 추출
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!
        
        let components = utcCalendar.dateComponents([.year, .month, .day, .hour, .minute, .second, .nanosecond], from: self)
        
        // 현재 기기 시간대에서 해석
        return Calendar.current.date(from: components) ?? self
    }
}
