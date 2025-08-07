//
//  TransactionType+.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/3/25.
//

import Foundation
import SwiftUI

// MARK: - TransactionType Extensions for Formatting

extension TransactionType {
    
    /// TransactionType 에 따른 색상 구분 필요시 사용
    public var color: Color {
        switch self {
        case .income:
            return .green
        case .fixedExpense:
            return .orange
        case .variableExpense:
            return .red
        }
    }
    
    /// TransactionType에 따른 금액 포맷팅
    /// - Parameter amount: 포맷할 금액
    /// - Returns: 거래 유형에 맞는 포맷된 금액 문자열
    public func formatAmount(_ amount: Decimal) -> String {
        switch self {
        case .income:
            return amount.formattedIncomeAmount
        case .fixedExpense, .variableExpense:
            return amount.formattedExpenseAmount
        }
    }
}
