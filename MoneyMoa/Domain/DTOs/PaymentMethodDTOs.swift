//
//  PaymentMethodDTOs.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/27/25.
//

import Foundation

// MARK: - Payment Method DTO

public struct PaymentMethodDTO: Sendable, Hashable, Identifiable {
    public let id: UUID
    public let name: String
    public let kind: PaymentMethodKind
    public let iconName: String?
    public let orderIndex: Int
    public let isActive: Bool
    
    public init(
        id: UUID = UUID(),
        name: String,
        kind: PaymentMethodKind,
        iconName: String? = nil,
        orderIndex: Int = 0,
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.iconName = iconName
        self.orderIndex = orderIndex
        self.isActive = isActive
    }
}

// MARK: - for Sorting

extension PaymentMethodDTO: Comparable {
    static public func < (lhs: PaymentMethodDTO, rhs: PaymentMethodDTO) -> Bool {
        // 먼저 orderIndex로 정렬, 같으면 이름으로 정렬
        if lhs.orderIndex != rhs.orderIndex {
            return lhs.orderIndex < rhs.orderIndex
        }
        return lhs.name < rhs.name
    }
}

// MARK: - for displayIcon

extension PaymentMethodDTO {
    /// 표시할 아이콘명 (커스텀 아이콘 우선, 없으면 kind 기본 아이콘)
    public var displayIconName: String {
        return iconName ?? kind.iconName
    }
}

#if DEBUG
// MARK: - Mock Data Extensions

extension PaymentMethodDTO {
    static let mockCreditCard = PaymentMethodDTO(
        name: "신용카드",
        kind: .credit,
        orderIndex: 0
    )
    
    static let mockDebitCard = PaymentMethodDTO(
        name: "체크카드",
        kind: .debit,
        orderIndex: 1
    )
    
    static let mockCash = PaymentMethodDTO(
        name: "현금",
        kind: .cash,
        orderIndex: 2
    )
    
    static let mockTransfer = PaymentMethodDTO(
        name: "계좌이체",
        kind: .transfer,
        orderIndex: 3
    )
    
    static let mockCustomCard = PaymentMethodDTO(
        name: "커스텀카드",
        kind: .credit,
        iconName: "creditcard.fill",
        orderIndex: 4
    )
    
    static let mockStandards = [mockCreditCard, mockDebitCard, mockCash, mockTransfer]
    
    static func mockWith(
        name: String,
        kind: PaymentMethodKind,
        iconName: String? = nil,
        orderIndex: Int = 0,
        isActive: Bool = true
    ) -> PaymentMethodDTO {
        return PaymentMethodDTO(
            name: name,
            kind: kind,
            iconName: iconName,
            orderIndex: orderIndex,
            isActive: isActive
        )
    }
}
#endif
