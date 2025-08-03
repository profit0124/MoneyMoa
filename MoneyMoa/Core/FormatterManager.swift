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
    
    // MARK: - Formatters
    
    /// 금액 표시용 NumberFormatter (천단위 구분)
    public private(set) lazy var amountFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
    
    /// 거래 날짜 표시용 DateFormatter (스마트 헤더 fallback용)
    public private(set) lazy var transactionDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy.MM.dd (E)"
        return formatter
    }()

    // MARK: - Calendar
    /// 한국 로케일 캘린더 (날짜 계산용)
    /// 추후 Localization 고려
    public private(set) lazy var koreaCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ko_KR")
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? TimeZone.current
        return calendar
    }()
}
