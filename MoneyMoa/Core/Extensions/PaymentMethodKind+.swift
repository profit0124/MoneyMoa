//
//  PaymentMethodKind+.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/3/25.
//

import Foundation

// MARK: - PaymentMethodKind Extensions

extension PaymentMethodKind {
    
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
}
