//
//  PaymentMethodKind+.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/3/25.
//

import Foundation
import SwiftUI

// MARK: - PaymentMethodKind Extensions

extension PaymentMethodKind {
    
    /// PaymentMethodKind별 표시 이름
    public var displayName: String {
        switch self {
        case .cash:
            return "현금"
        case .credit:
            return "신용카드"
        case .debit:
            return "체크카드"
        case .transfer:
            return "계좌이체"
        }
    }
    
    /// PaymentMethodKind별 기본 아이콘명
    public var iconName: String {
        switch self {
        case .cash:
            return "banknote"
        case .credit:
            return "creditcard"
        case .debit:
            return "rectangle.and.hand.point.up.left"
        case .transfer:
            return "building.columns"
        }
    }

    public var color: Color {
        switch self {
        case .cash:
            return .green
        case .credit:
            return .blue
        case .debit:
            return .orange
        case .transfer:
            return .purple
        }
    }
}
