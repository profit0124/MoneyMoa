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
    public var formattedAmount: String {
        let formatter = FormatterManager.shared.amountFormatter
        let formattedAmount = formatter.string(from: self as NSDecimalNumber) ?? "0"
        return "\(formattedAmount)원"
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
}
