//
//  Decimal+.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/3/25.
//

import Foundation

// MARK: - Decimal Extensions for Formatting

extension Decimal {
    
    /// 금액을 원화 표시 문자열로 변환 (예: "15,000원")
    public var formattedAmountWithWon: String {
        let formatter = FormatterManager.shared.amountFormatter
        let formattedAmount = formatter.string(from: self as NSDecimalNumber) ?? "0"
        return "\(formattedAmount)원"
    }

    /// 금액을 문자열로 변환 (예: "15,000")
    public var formattedAmountWithoutWon: String {
        let formatter = FormatterManager.shared.amountFormatter
        let formattedAmount = formatter.string(from: self as NSDecimalNumber) ?? "0"
        return formattedAmount
    }

    /// 수입 거래 금액으로 포맷 (예: "+15,000원")
    public var formattedIncomeAmount: String {
        let formatter = FormatterManager.shared.amountFormatter
        let formattedAmount = formatter.string(from: self as NSDecimalNumber) ?? "0"
        return "+\(formattedAmount)원"
    }
    
    /// 지출 거래 금액으로 포맷 (예: "-15,000원")
    public var formattedExpenseAmount: String {
        let formatter = FormatterManager.shared.amountFormatter
        let formattedAmount = formatter.string(from: self as NSDecimalNumber) ?? "0"
        return "-\(formattedAmount)원"
    }
    
    // MARK: - Calendar Display Extensions
    
    /// Calendar용 압축 금액 표시 (예: "+1만", "-50만", "+1억+")
    public var compactAmountText: String {
        let absoluteValue = abs(self)
        
        // 99,999,999 초과 처리
        if absoluteValue > 99_999_999 {
            return "1억+"
        }
        
        // 1만 이상 (99,999,999 이하)
        if absoluteValue >= 10_000 {
            let tenThousands = absoluteValue / 10_000
            let intValue = Int(truncating: tenThousands as NSDecimalNumber)
            return "\(intValue)만"
        }
        
        // 1만 미만
        let formatter = FormatterManager.shared.amountFormatter
        let formattedAmount = formatter.string(from: absoluteValue as NSDecimalNumber) ?? "0"
        return "\(formattedAmount)"
    }
    
    // MARK: - Currency Formatting (FormatterManager Integration)
    
    /// 통화 형식으로 포맷 (₩15,000)
    /// FormatterManager의 formatCurrency를 사용하는 편의 메서드
    public var currencyFormatted: String {
        return FormatterManager.shared.formatCurrency(self)
    }

    // MARK: - Decimal 변환 (차트 경계에서만 Double 변환)
    var asDouble: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }
}
