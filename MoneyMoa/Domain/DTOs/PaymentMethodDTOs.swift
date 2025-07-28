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
    public let orderIndex: Int
    public let isActive: Bool
    
    public init(
        id: UUID = UUID(),
        name: String,
        kind: PaymentMethodKind,
        orderIndex: Int = 0,
        isActive: Bool = true,
    ) {
        self.id = id
        self.name = name
        self.kind = kind
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
