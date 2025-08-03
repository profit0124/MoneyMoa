//
//  CategoryDTOs.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/27/25.
//

import Foundation

// MARK: - Category DTO

public struct CategoryDTO: Sendable, Hashable, Identifiable {
    public let id: UUID
    public let name: String
    public let iconName: String
    public let transactionType: TransactionType
    public let isActive: Bool
    public let orderIndex: Int
    public let subCategories: [SubCategoryDTO]
    
    public init(
        id: UUID = UUID(),
        name: String,
        iconName: String,
        transactionType: TransactionType,
        isActive: Bool = true,
        orderIndex: Int = 0,
        subCategories: [SubCategoryDTO] = []
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.transactionType = transactionType
        self.isActive = isActive
        self.orderIndex = orderIndex
        self.subCategories = subCategories
    }
}

// MARK: - SubCategory DTO

public struct SubCategoryDTO: Sendable, Hashable, Identifiable {
    public let id: UUID
    public let name: String
    public let transactionType: TransactionType
    public let isActive: Bool
    public let orderIndex: Int
    public let categoryId: UUID
    public let categoryIconName: String
    
    public init(
        id: UUID = UUID(),
        name: String,
        transactionType: TransactionType,
        isActive: Bool = true,
        orderIndex: Int = 0,
        categoryId: UUID,
        categoryIconName: String
    ) {
        self.id = id
        self.name = name
        self.transactionType = transactionType
        self.isActive = isActive
        self.orderIndex = orderIndex
        self.categoryId = categoryId
        self.categoryIconName = categoryIconName
    }
}

// MARK: - for Sorting

extension CategoryDTO: Comparable {
    static public func < (lhs: CategoryDTO, rhs: CategoryDTO) -> Bool {
        // 먼저 orderIndex로 정렬, 같으면 이름으로 정렬
        if lhs.orderIndex != rhs.orderIndex {
            return lhs.orderIndex < rhs.orderIndex
        }
        return lhs.name < rhs.name
    }
}

extension SubCategoryDTO: Comparable {
    static public func < (lhs: SubCategoryDTO, rhs: SubCategoryDTO) -> Bool {
        // 먼저 orderIndex로 정렬, 같으면 이름으로 정렬
        if lhs.orderIndex != rhs.orderIndex {
            return lhs.orderIndex < rhs.orderIndex
        }
        return lhs.name < rhs.name
    }
}
