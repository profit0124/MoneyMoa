//
//  PaymentMethods.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/27/25.
//

import Foundation
import SwiftData

// MARK: - Payment Method Model

@Model
final class PaymentMethod {
    @Attribute(.unique) var id: UUID
    var name: String
    var kindRawValue: String
    var kind: PaymentMethodKind {
        get { PaymentMethodKind(rawValue: kindRawValue) ?? .credit }
        set { kindRawValue = newValue.rawValue }
    }
    var orderIndex: Int
    var isActive: Bool
    
    @Relationship(deleteRule: .cascade, inverse: \Transaction.paymentMethod)
    var transactions: [Transaction]
    
    // Detailed information(추후 추가)
    var institutionName: String?
    var accountNumber: String?
    var cardNumber: String?
    var color: String?
    var iconName: String?
    
    init(
        id: UUID = UUID(),
        name: String,
        kind: PaymentMethodKind,
        orderIndex: Int = 0,
        isActive: Bool = true,
        transactions: [Transaction] = [],
        institutionName: String? = nil,
        accountNumber: String? = nil,
        cardNumber: String? = nil,
        color: String? = nil,
        iconName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.kindRawValue = kind.rawValue
        self.orderIndex = orderIndex
        self.isActive = isActive
        self.transactions = transactions
        self.institutionName = institutionName
        self.accountNumber = accountNumber
        self.cardNumber = cardNumber
        self.color = color
        self.iconName = iconName
    }
}

// MARK: - PaymentMethod to DTO Extensions

extension PaymentMethod {
    /// PaymentMethod를 PaymentMethodDTO로 변환
    public func toDTO() -> PaymentMethodDTO {
        return PaymentMethodDTO(
            id: self.id,
            name: self.name,
            kind: self.kind,
            iconName: self.iconName,
            orderIndex: self.orderIndex,
            isActive: self.isActive,
        )
    }
}

// MARK: - Collection Extensions

extension Collection where Element == PaymentMethod {
    /// PaymentMethod 배열을 PaymentMethodDTO 배열로 변환
    func toDTOs() -> [PaymentMethodDTO] {
        return self.map { $0.toDTO() }.sorted()
    }
}

// MARK: - DTO to SwiftData Model Extensions

extension PaymentMethodDTO {
    /// PaymentMethodDTO를 SwiftData PaymentMethod 모델로 변환
    func toModel() -> PaymentMethod {
        return PaymentMethod(
            id: self.id,
            name: self.name,
            kind: self.kind,
            orderIndex: self.orderIndex,
            isActive: self.isActive
        )
    }
}
