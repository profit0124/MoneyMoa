//
//  FormatterManager.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/30/25.
//

import Foundation

// MARK: - FormatterManager

/// 앱 전체에서 사용되는 Formatter들을 관리하는 싱글톤 클래스
/// 생성 비용이 높은 Formatter들을 한 번만 생성하여 재사용
public final class FormatterManager {
    
    // MARK: - Singleton
    
    public static let shared = FormatterManager()
    
    private init() {}
    
    // MARK: - Locale Helper
    
    /// 현재 로케일이 한국어인지 확인
    private var isKoreanLocale: Bool {
        Locale.current.identifier == "ko"
    }
    
    // MARK: - Formatters
    
    /// 금액 표시용 NumberFormatter (천단위 구분)
    public private(set) lazy var amountFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale.current
        return formatter
    }()
    
    /// 거래 날짜 표시용 DateFormatter (스마트 헤더 fallback용)
    public private(set) lazy var transactionDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.calendar = Calendar.current
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = isKoreanLocale ? "yyyy.MM.dd (E)" : "MMM dd, yyyy (E)"
        return formatter
    }()
    
    /// 날짜만 표시용 DateFormatter
    public private(set) lazy var dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.calendar = Calendar.current
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = isKoreanLocale ? "yyyy년 MM월 dd일 (E)" : "MMMM dd, yyyy (EEEE)"
        return formatter
    }()
    
    /// 시간만 표시용 DateFormatter
    public private(set) lazy var timeOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.calendar = Calendar.current
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = isKoreanLocale ? "HH:mm" : "h:mm a"
        return formatter
    }()
    
    // MARK: - Formatting Methods
    
    /// 통화 형식으로 금액을 포맷팅
    /// - Parameter amount: 포맷팅할 금액 (Decimal)
    /// - Returns: "₩15,000" 형식의 문자열
    public func formatCurrency(_ amount: Decimal) -> String {
        guard let formattedAmount = amountFormatter.string(from: amount as NSDecimalNumber) else {
            return "₩0"
        }
        return "₩\(formattedAmount)"
    }
    
    /// 날짜 포맷팅 (다양한 형식 지원)
    /// - Parameters:
    ///   - date: 포맷팅할 날짜
    ///   - format: 포맷 타입
    /// - Returns: 포맷팅된 날짜 문자열
    public func formatDate(_ date: Date, format: DateFormatType) -> String {
        switch format {
        case .dateOnly:
            return dateOnlyFormatter.string(from: date)
        case .timeOnly:
            return timeOnlyFormatter.string(from: date)
        case .transaction:
            return transactionDateFormatter.string(from: date)
        }
    }
    
    /// 날짜 범위 포맷팅 (통계 제목용)
    /// - Parameter range: 날짜 범위
    /// - Returns: "8.1-8.31" (한국) 또는 "Aug 1-Aug 31" (영어) 형식의 간단한 문자열
    public func formatDateRange(_ range: DateRange) -> String {
        let titleFormatter = DateFormatter()
        titleFormatter.locale = Locale.current
        
        if isKoreanLocale {
            titleFormatter.dateFormat = "YY.MM.dd"
        } else {
            titleFormatter.dateFormat = "MMM dd"
        }

        let startStr = titleFormatter.string(from: range.start)
        let endStr = titleFormatter.string(from: Calendar.current.date(byAdding: .day, value: -1, to: range.end) ?? range.end)
        return "\(startStr)-\(endStr)"
    }
}

// MARK: - Date Format Types

public enum DateFormatType {
    case dateOnly    // "2025년 8월 20일 (화)"
    case timeOnly    // "14:30"
    case transaction // "2025.08.20 (화)"
}
