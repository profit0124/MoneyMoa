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

#if DEBUG
extension CategoryDTO {
    static let mockExpense = CategoryDTO(
        name: "생활비",
        iconName: "house.fill",
        transactionType: .variableExpense
    )
    
    static let mockIncome = CategoryDTO(
        name: "수입",
        iconName: "plus.circle.fill",
        transactionType: .income
    )
    
    static let mockFood = CategoryDTO(
        name: "식비",
        iconName: "fork.knife",
        transactionType: .variableExpense,
        orderIndex: 0
    )
    
    static let mockTransport = CategoryDTO(
        name: "교통비",
        iconName: "car.fill",
        transactionType: .variableExpense,
        orderIndex: 1
    )
    
    static let mockSalary = CategoryDTO(
        name: "급여",
        iconName: "banknote",
        transactionType: .income,
        orderIndex: 0
    )
    
    static let mockRent = CategoryDTO(
        name: "월세",
        iconName: "house.fill",
        transactionType: .fixedExpense,
        orderIndex: 0
    )
}

extension SubCategoryDTO {
    static let mockFoodExpense = SubCategoryDTO(
        name: "외식비",
        transactionType: .variableExpense,
        categoryId: CategoryDTO.mockFood.id,
        categoryIconName: CategoryDTO.mockFood.iconName
    )
    
    static let mockIncomeAllowance = SubCategoryDTO(
        name: "용돈",
        transactionType: .income,
        categoryId: CategoryDTO.mockIncome.id,
        categoryIconName: CategoryDTO.mockIncome.iconName
    )
    
    static let mockTransportBus = SubCategoryDTO(
        name: "교통",
        transactionType: .variableExpense,
        categoryId: CategoryDTO.mockExpense.id,
        categoryIconName: CategoryDTO.mockExpense.iconName
    )
    
    static let mockBeauty = SubCategoryDTO(
        name: "미용",
        transactionType: .variableExpense,
        categoryId: CategoryDTO.mockIncome.id,
        categoryIconName: CategoryDTO.mockIncome.iconName
    )
    
    static let mockSalary = SubCategoryDTO(
        name: "급여",
        transactionType: .income,
        categoryId: CategoryDTO.mockIncome.id,
        categoryIconName: CategoryDTO.mockIncome.iconName
    )
}
#endif
