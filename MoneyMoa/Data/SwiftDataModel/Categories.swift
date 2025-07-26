//
//  Categories.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/26/25.
//

import Foundation
import SwiftData

// MARK: - Category Model

@Model
final class Category {
    @Attribute(.unique) var id: UUID
    var name: String
    var orderIndex: Int
    var transactionType: TransactionType
    
    var isActive: Bool
    
    @Relationship(deleteRule: .cascade, inverse: \SubCategory.category)
    var subCategories: [SubCategory] = []
    
    init(id: UUID = UUID(), name: String, transactionType: TransactionType, orderIndex: Int = 0, isActive: Bool = true) {
        self.id = id
        self.name = name
        self.transactionType = transactionType
        self.orderIndex = orderIndex
        self.isActive = isActive
    }
}

// MARK: - SubCategory Model

@Model
final class SubCategory {
    @Attribute(.unique) var id: UUID
    var name: String
    var transactionType: TransactionType
    var orderIndex: Int
    
    var isActive: Bool
    
    @Relationship
    var category: Category
    @Relationship(deleteRule: .cascade, inverse: \Transaction.subCategory)
    var transactions: [Transaction]
    
    init(id: UUID = UUID(),
         name: String,
         transactionType: TransactionType,
         orderIndex: Int = 0,
         category: Category,
         isActive: Bool = true,
         transactions: [Transaction] = []
    ) {
        self.id = id
        self.name = name
        self.transactionType = transactionType
        self.orderIndex = orderIndex
        self.category = category
        self.isActive = isActive
        self.transactions = transactions
    }
}
