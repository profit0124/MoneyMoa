//
//  BudgetDTOs.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/28/25.
//

import Foundation

// MARK: - BudgetTemplate DTO

public struct BudgetTemplateDTO: Sendable, Hashable, Identifiable {
    public let id: UUID
    public let totalAmount: Decimal
    public let categoryBudgetTemplates: [CategoryBudgetTemplateDTO]
    
    public init(
        id: UUID = UUID(),
        totalAmount: Decimal,
        categoryBudgetTemplates: [CategoryBudgetTemplateDTO] = []
    ) {
        self.id = id
        self.totalAmount = totalAmount
        self.categoryBudgetTemplates = categoryBudgetTemplates
    }
}

// MARK: - CategoryBudgetTemplate DTO

public struct CategoryBudgetTemplateDTO: Sendable, Hashable, Identifiable {
    public let id: UUID
    public let amount: Decimal
    public let categoryID: UUID
    public let categoryName: String
    public let budgetTemplateId: UUID
    
    public init(
        id: UUID = UUID(),
        amount: Decimal,
        categoryID: UUID,
        categoryName: String,
        budgetTemplateId: UUID
    ) {
        self.id = id
        self.amount = amount
        self.categoryID = categoryID
        self.categoryName = categoryName
        self.budgetTemplateId = budgetTemplateId
    }
}

// MARK: - Budget DTO

public struct BudgetDTO: Sendable, Hashable, Identifiable {
    public let id: UUID
    public let month: YearMonth
    public let totalAmount: Decimal
    public let categoryBudgets: [CategoryBudgetDTO]
    
    public init(
        id: UUID = UUID(),
        month: YearMonth,
        totalAmount: Decimal,
        categoryBudgets: [CategoryBudgetDTO] = []
    ) {
        self.id = id
        self.month = month
        self.totalAmount = totalAmount
        self.categoryBudgets = categoryBudgets
    }
}

// MARK: - CategoryBudget DTO

public struct CategoryBudgetDTO: Sendable, Hashable, Identifiable {
    public let id: UUID
    public let amount: Decimal
    public let categoryID: UUID
    public let categoryName: String
    public let budgetId: UUID
    
    public init(
        id: UUID = UUID(),
        amount: Decimal,
        categoryID: UUID,
        categoryName: String,
        budgetId: UUID
    ) {
        self.id = id
        self.amount = amount
        self.categoryID = categoryID
        self.categoryName = categoryName
        self.budgetId = budgetId
    }
}

// MARK: - Comparable Extensions

extension BudgetDTO: Comparable {
    public static func < (lhs: BudgetDTO, rhs: BudgetDTO) -> Bool {
        // YearMonth 기준 내림차순 정렬 (최신 월이 먼저)
        lhs.month > rhs.month
    }
}

extension CategoryBudgetDTO: Comparable {
    public static func < (lhs: CategoryBudgetDTO, rhs: CategoryBudgetDTO) -> Bool {
        // 카테고리 이름 기준 오름차순 정렬
        lhs.categoryName < rhs.categoryName
    }
}

extension CategoryBudgetTemplateDTO: Comparable {
    public static func < (lhs: CategoryBudgetTemplateDTO, rhs: CategoryBudgetTemplateDTO) -> Bool {
        // 카테고리 이름 기준 오름차순 정렬
        lhs.categoryName < rhs.categoryName
    }
}

// MARK: - Conversion Extensions

extension BudgetTemplateDTO {
    /// BudgetTemplateDTO를 특정 월의 BudgetDTO로 변환합니다
    /// - Parameter month: 적용할 연월
    /// - Returns: 변환된 BudgetDTO
    func toBudgetDTO(for month: YearMonth) -> BudgetDTO {
        let budgetId = UUID()
        let categoryBudgets = categoryBudgetTemplates.map { template in
            CategoryBudgetDTO(
                amount: template.amount,
                categoryID: template.categoryID,
                categoryName: template.categoryName,
                budgetId: budgetId
            )
        }
        
        return BudgetDTO(
            id: budgetId,
            month: month,
            totalAmount: totalAmount,
            categoryBudgets: categoryBudgets
        )
    }
}

extension BudgetDTO {
    func toBudgetTemplateDTO() -> BudgetTemplateDTO {
        let budgetId = UUID()

        let categoryBudgetTemplates = categoryBudgets.map {
            CategoryBudgetTemplateDTO(amount: $0.amount, categoryID: $0.categoryID, categoryName: $0.categoryName, budgetTemplateId: budgetId)
        }

        return BudgetTemplateDTO(
            id: budgetId,
            totalAmount: totalAmount,
            categoryBudgetTemplates: categoryBudgetTemplates
        )
    }
}

extension CategoryBudgetTemplateDTO {
    /// CategoryBudgetTemplateDTO를 CategoryBudgetDTO로 변환합니다
    /// - Parameter budgetId: 상위 예산의 ID
    /// - Returns: 변환된 CategoryBudgetDTO
    func toCategoryBudgetDTO(budgetId: UUID) -> CategoryBudgetDTO {
        CategoryBudgetDTO(
            amount: amount,
            categoryID: categoryID,
            categoryName: categoryName,
            budgetId: budgetId
        )
    }
}

#if DEBUG
// MARK: - Mock Data Extensions

extension BudgetTemplateDTO {
    static let mockStandard = BudgetTemplateDTO(
        totalAmount: 2_000_000,
        categoryBudgetTemplates: [
            .mockFood, .mockTransport, .mockLifestyle, .mockOthers
        ]
    )
    
    static let mockSimple = BudgetTemplateDTO(
        totalAmount: 1_000_000,
        categoryBudgetTemplates: [.mockFood]
    )
    
    static let mockLarge = BudgetTemplateDTO(
        totalAmount: 3_000_000,
        categoryBudgetTemplates: [
            .mockFoodLarge, .mockTransportLarge, .mockLifestyleLarge, .mockOthersLarge
        ]
    )
}

extension CategoryBudgetTemplateDTO {
    private static let mockTemplateId = UUID()
    
    static let mockFood = CategoryBudgetTemplateDTO(
        amount: 800_000,
        categoryID: CategoryDTO.mockExpense.id,
        categoryName: "식비",
        budgetTemplateId: mockTemplateId
    )
    
    static let mockTransport = CategoryBudgetTemplateDTO(
        amount: 300_000,
        categoryID: CategoryDTO.mockExpense.id,
        categoryName: "교통비",
        budgetTemplateId: mockTemplateId
    )
    
    static let mockLifestyle = CategoryBudgetTemplateDTO(
        amount: 500_000,
        categoryID: CategoryDTO.mockExpense.id,
        categoryName: "생활용품",
        budgetTemplateId: mockTemplateId
    )
    
    static let mockOthers = CategoryBudgetTemplateDTO(
        amount: 400_000,
        categoryID: CategoryDTO.mockExpense.id,
        categoryName: "기타",
        budgetTemplateId: mockTemplateId
    )
    
    // Large budget versions
    static let mockFoodLarge = CategoryBudgetTemplateDTO(
        amount: 1_200_000,
        categoryID: CategoryDTO.mockExpense.id,
        categoryName: "식비",
        budgetTemplateId: mockTemplateId
    )
    
    static let mockTransportLarge = CategoryBudgetTemplateDTO(
        amount: 500_000,
        categoryID: CategoryDTO.mockExpense.id,
        categoryName: "교통비",
        budgetTemplateId: mockTemplateId
    )
    
    static let mockLifestyleLarge = CategoryBudgetTemplateDTO(
        amount: 800_000,
        categoryID: CategoryDTO.mockExpense.id,
        categoryName: "생활용품",
        budgetTemplateId: mockTemplateId
    )
    
    static let mockOthersLarge = CategoryBudgetTemplateDTO(
        amount: 500_000,
        categoryID: CategoryDTO.mockExpense.id,
        categoryName: "기타",
        budgetTemplateId: mockTemplateId
    )
}

extension BudgetDTO {
    static let mockCurrent = BudgetDTO(
        month: .current,
        totalAmount: 3_000_000,
        categoryBudgets: [
            .mockFood, .mockTransport, .mockOthers
        ]
    )
    
    static let mockPrevious = BudgetDTO(
        month: YearMonth.current.previousMonth(),
        totalAmount: 2_800_000,
        categoryBudgets: []
    )
    
    static let mockStandard = BudgetDTO(
        month: YearMonth(year: 2025, month: 1),
        totalAmount: 1_000_000,
        categoryBudgets: [.mockFood]
    )
    
    static func mockFor(month: YearMonth, amount: Decimal = 1_000_000) -> BudgetDTO {
        BudgetDTO(
            month: month,
            totalAmount: amount,
            categoryBudgets: []
        )
    }
}

extension CategoryBudgetDTO {
    private static let mockBudgetId = UUID()
    
    static let mockFood = CategoryBudgetDTO(
        amount: 800_000,
        categoryID: CategoryDTO.mockExpense.id,
        categoryName: "식비",
        budgetId: mockBudgetId
    )
    
    static let mockTransport = CategoryBudgetDTO(
        amount: 500_000,
        categoryID: CategoryDTO.mockExpense.id,
        categoryName: "교통비",
        budgetId: mockBudgetId
    )
    
    static let mockOthers = CategoryBudgetDTO(
        amount: 1_700_000,
        categoryID: CategoryDTO.mockExpense.id,
        categoryName: "기타",
        budgetId: mockBudgetId
    )
    
    static func mockWith(name: String, amount: Decimal, categoryId: UUID = CategoryDTO.mockExpense.id) -> CategoryBudgetDTO {
        CategoryBudgetDTO(
            amount: amount,
            categoryID: categoryId,
            categoryName: name,
            budgetId: mockBudgetId
        )
    }
}
#endif
