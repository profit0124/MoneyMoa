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
    var transactionTypeRawValue: String
    var transactionType: TransactionType {
        get { TransactionType(rawValue: transactionTypeRawValue) ?? .variableExpense }
        set { transactionTypeRawValue = newValue.rawValue }
    }
    
    var isActive: Bool
    
    @Relationship(deleteRule: .cascade, inverse: \SubCategory.category)
    var subCategories: [SubCategory] = []
    
    init(id: UUID = UUID(), name: String, transactionType: TransactionType, orderIndex: Int = 0, isActive: Bool = true) {
        self.id = id
        self.name = name
        self.transactionTypeRawValue = transactionType.rawValue
        self.orderIndex = orderIndex
        self.isActive = isActive
    }
}

// MARK: - SubCategory Model

@Model
final class SubCategory {
    @Attribute(.unique) var id: UUID
    var name: String
    var transactionTypeRawValue: String
    var transactionType: TransactionType {
        get { TransactionType(rawValue: transactionTypeRawValue) ?? .variableExpense }
        set { transactionTypeRawValue = newValue.rawValue }
    }
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
        self.transactionTypeRawValue = transactionType.rawValue
        self.orderIndex = orderIndex
        self.category = category
        self.isActive = isActive
        self.transactions = transactions
    }
}

// MARK: - Category to DTO Extensions

extension Category {
    /// Category를 CategoryDTO로 변환 (서브카테고리 포함)
    public func toDTO(includeSubCategories: Bool = false) -> CategoryDTO {
        let subCategoryDTOs: [SubCategoryDTO] = includeSubCategories ?
        self.subCategories.toDTOs() : []
        
        return CategoryDTO(
            id: self.id,
            name: self.name,
            transactionType: self.transactionType,
            isActive: self.isActive,
            orderIndex: self.orderIndex,
            subCategories: subCategoryDTOs
        )
    }
}

extension SubCategory {
    /// SubCategory를 SubCategoryDTO로 변환
    public func toDTO() -> SubCategoryDTO {
        return SubCategoryDTO(
            id: self.id,
            name: self.name,
            transactionType: self.transactionType,
            isActive: self.isActive,
            orderIndex: self.orderIndex,
            categoryId: self.category.id
        )
    }
}

// MARK: - Collection Extensions

extension Collection where Element == Category {
    /// Category 배열을 CategoryDTO 배열로 변환
    func toDTOs(includeSubCategories: Bool = false) -> [CategoryDTO] {
        return self.map { $0.toDTO(includeSubCategories: includeSubCategories) }
    }
}

extension Collection where Element == SubCategory {
    /// SubCategory 배열을 SubCategoryDTO 배열로 변환
    func toDTOs() -> [SubCategoryDTO] {
        return self.map { $0.toDTO() }.sorted(by: { $0.orderIndex < $1.orderIndex })
    }
}


// MARK: - DTO to SwiftData Model Extensions

extension CategoryDTO {
    /// CategoryDTO를 SwiftData Category 모델로 변환
    /// - Note: 서브카테고리는 별도로 생성해야 함 (관계형 데이터)
    func toModel() -> Category {
        return Category(
            id: self.id,
            name: self.name,
            transactionType: self.transactionType,
            orderIndex: self.orderIndex,
            isActive: self.isActive
        )
    }
}

extension SubCategoryDTO {
    /// SubCategoryDTO를 SwiftData SubCategory 모델로 변환
    /// - Parameter parentCategory: 상위 카테고리 모델 (필수)
    func toModel(parentCategory: Category) -> SubCategory {
        return SubCategory(
            id: self.id,
            name: self.name,
            transactionType: self.transactionType,
            orderIndex: self.orderIndex,
            category: parentCategory,
            isActive: self.isActive
        )
    }
}
