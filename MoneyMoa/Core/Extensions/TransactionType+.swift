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
    
    /// TransactionType에 따른 표시 이름
    public var displayName: String {
        switch self {
        case .income:
            return "수입"
        case .fixedExpense:
            return "고정지출"
        case .variableExpense:
            return "변동지출"
        }
    }
    
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
    
    /// TransactionType에 따른 아이콘
    public var icon: String {
        switch self {
        case .income:
            return "plus.circle.fill"
        case .fixedExpense:
            return "minus.circle.fill"
        case .variableExpense:
            return "minus.circle"
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
