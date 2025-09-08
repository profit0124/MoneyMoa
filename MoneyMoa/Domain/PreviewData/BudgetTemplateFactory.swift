//
//  BudgetTemplateFactory.swift
//  MoneyMoa
//
//  Created by Claude Code on 9/8/25.
//

import Foundation

/// Factory for generating BudgetTemplate test data
/// - Provides realistic budget template data for testing and previews
/// - Supports various scenarios and bulk generation
public enum BudgetTemplateFactory {
    
    // MARK: - Basic Builders
    
    /// Create a simple sample budget template for testing
    public static func sample() -> BudgetTemplateDTO {
        return create(
            totalAmount: 1_500_000,
            categoryBudgetTemplates: [
                CategoryBudgetTemplateFactory.create(
                    amount: 500_000,
                    categoryID: UUID(),
                    categoryName: "식비",
                    budgetTemplateId: UUID()
                ),
                CategoryBudgetTemplateFactory.create(
                    amount: 300_000,
                    categoryID: UUID(),
                    categoryName: "교통비",
                    budgetTemplateId: UUID()
                )
            ]
        )
    }
    
    /// Create a single budget template with specified parameters
    public static func create(
        id: UUID = UUID(),
        totalAmount: Decimal,
        categoryBudgetTemplates: [CategoryBudgetTemplateDTO] = []
    ) -> BudgetTemplateDTO {
        return BudgetTemplateDTO(
            id: id,
            totalAmount: totalAmount,
            categoryBudgetTemplates: categoryBudgetTemplates
        )
    }
    
    /// Create a realistic budget template with Korean categories
    public static func createRealistic() -> BudgetTemplateDTO {
        let templateId = UUID()
        
        let categoryTemplates = [
            CategoryBudgetTemplateFactory.create(amount: 600_000, categoryID: UUID(), categoryName: "식비", budgetTemplateId: templateId),
            CategoryBudgetTemplateFactory.create(amount: 300_000, categoryID: UUID(), categoryName: "교통비", budgetTemplateId: templateId),
            CategoryBudgetTemplateFactory.create(amount: 400_000, categoryID: UUID(), categoryName: "쇼핑", budgetTemplateId: templateId),
            CategoryBudgetTemplateFactory.create(amount: 200_000, categoryID: UUID(), categoryName: "문화생활", budgetTemplateId: templateId),
            CategoryBudgetTemplateFactory.create(amount: 150_000, categoryID: UUID(), categoryName: "미용", budgetTemplateId: templateId),
            CategoryBudgetTemplateFactory.create(amount: 100_000, categoryID: UUID(), categoryName: "의료비", budgetTemplateId: templateId),
            CategoryBudgetTemplateFactory.create(amount: 250_000, categoryID: UUID(), categoryName: "기타", budgetTemplateId: templateId)
        ]
        
        let totalAmount = categoryTemplates.reduce(0) { $0 + $1.amount }
        
        return create(
            id: templateId,
            totalAmount: totalAmount,
            categoryBudgetTemplates: categoryTemplates
        )
    }
    
    // MARK: - Test Scenarios
    
    /// Empty budget template
    public static var empty: BudgetTemplateDTO {
        create(totalAmount: 0, categoryBudgetTemplates: [])
    }
    
    /// Minimal budget template for basic testing
    public static var minimal: BudgetTemplateDTO {
        let templateId = UUID()
        return create(
            id: templateId,
            totalAmount: 800_000,
            categoryBudgetTemplates: [
                CategoryBudgetTemplateFactory.create(
                    amount: 500_000,
                    categoryID: UUID(),
                    categoryName: "식비",
                    budgetTemplateId: templateId
                ),
                CategoryBudgetTemplateFactory.create(
                    amount: 300_000,
                    categoryID: UUID(),
                    categoryName: "교통비",
                    budgetTemplateId: templateId
                )
            ]
        )
    }
    
    /// Normal budget template for regular testing
    public static var normal: BudgetTemplateDTO {
        let templateId = UUID()
        
        let categoryTemplates = [
            CategoryBudgetTemplateFactory.create(amount: 500_000, categoryID: UUID(), categoryName: "식비", budgetTemplateId: templateId),
            CategoryBudgetTemplateFactory.create(amount: 250_000, categoryID: UUID(), categoryName: "교통비", budgetTemplateId: templateId),
            CategoryBudgetTemplateFactory.create(amount: 300_000, categoryID: UUID(), categoryName: "쇼핑", budgetTemplateId: templateId),
            CategoryBudgetTemplateFactory.create(amount: 150_000, categoryID: UUID(), categoryName: "문화생활", budgetTemplateId: templateId),
            CategoryBudgetTemplateFactory.create(amount: 100_000, categoryID: UUID(), categoryName: "미용", budgetTemplateId: templateId)
        ]
        
        return create(
            id: templateId,
            totalAmount: 1_300_000,
            categoryBudgetTemplates: categoryTemplates
        )
    }
    
    /// Budget templates for different income levels
    public static var lowIncome: BudgetTemplateDTO {
        let templateId = UUID()
        
        let categoryTemplates = [
            CategoryBudgetTemplateFactory.create(amount: 300_000, categoryID: UUID(), categoryName: "식비", budgetTemplateId: templateId),
            CategoryBudgetTemplateFactory.create(amount: 150_000, categoryID: UUID(), categoryName: "교통비", budgetTemplateId: templateId),
            CategoryBudgetTemplateFactory.create(amount: 100_000, categoryID: UUID(), categoryName: "생활용품", budgetTemplateId: templateId),
            CategoryBudgetTemplateFactory.create(amount: 50_000, categoryID: UUID(), categoryName: "기타", budgetTemplateId: templateId)
        ]
        
        return create(
            id: templateId,
            totalAmount: 600_000,
            categoryBudgetTemplates: categoryTemplates
        )
    }
    
    public static var middleIncome: BudgetTemplateDTO {
        let templateId = UUID()
        
        let categoryTemplates = [
            CategoryBudgetTemplateFactory.create(amount: 700_000, categoryID: UUID(), categoryName: "식비", budgetTemplateId: templateId),
            CategoryBudgetTemplateFactory.create(amount: 400_000, categoryID: UUID(), categoryName: "교통비", budgetTemplateId: templateId),
            CategoryBudgetTemplateFactory.create(amount: 500_000, categoryID: UUID(), categoryName: "쇼핑", budgetTemplateId: templateId),
            CategoryBudgetTemplateFactory.create(amount: 300_000, categoryID: UUID(), categoryName: "문화생활", budgetTemplateId: templateId),
            CategoryBudgetTemplateFactory.create(amount: 200_000, categoryID: UUID(), categoryName: "미용", budgetTemplateId: templateId),
            CategoryBudgetTemplateFactory.create(amount: 400_000, categoryID: UUID(), categoryName: "기타", budgetTemplateId: templateId)
        ]
        
        return create(
            id: templateId,
            totalAmount: 2_500_000,
            categoryBudgetTemplates: categoryTemplates
        )
    }
    
    public static var highIncome: BudgetTemplateDTO {
        let templateId = UUID()
        
        let categoryTemplates = [
            CategoryBudgetTemplateFactory.create(amount: 1_000_000, categoryID: UUID(), categoryName: "식비", budgetTemplateId: templateId),
            CategoryBudgetTemplateFactory.create(amount: 500_000, categoryID: UUID(), categoryName: "교통비", budgetTemplateId: templateId),
            CategoryBudgetTemplateFactory.create(amount: 800_000, categoryID: UUID(), categoryName: "쇼핑", budgetTemplateId: templateId),
            CategoryBudgetTemplateFactory.create(amount: 600_000, categoryID: UUID(), categoryName: "문화생활", budgetTemplateId: templateId),
            CategoryBudgetTemplateFactory.create(amount: 400_000, categoryID: UUID(), categoryName: "미용", budgetTemplateId: templateId),
            CategoryBudgetTemplateFactory.create(amount: 300_000, categoryID: UUID(), categoryName: "의료비", budgetTemplateId: templateId),
            CategoryBudgetTemplateFactory.create(amount: 400_000, categoryID: UUID(), categoryName: "교육", budgetTemplateId: templateId),
            CategoryBudgetTemplateFactory.create(amount: 1_000_000, categoryID: UUID(), categoryName: "기타", budgetTemplateId: templateId)
        ]
        
        return create(
            id: templateId,
            totalAmount: 5_000_000,
            categoryBudgetTemplates: categoryTemplates
        )
    }
    
    /// Edge cases and boundary values
    public static var edge: BudgetTemplateDTO {
        let templateId = UUID()
        
        let categoryTemplates = [
            // Very small amount
            CategoryBudgetTemplateFactory.create(amount: 1, categoryID: UUID(), categoryName: "최소", budgetTemplateId: templateId),
            // Very large amount
            CategoryBudgetTemplateFactory.create(amount: 99_999_999, categoryID: UUID(), categoryName: "최대", budgetTemplateId: templateId),
            // Zero amount
            CategoryBudgetTemplateFactory.create(amount: 0, categoryID: UUID(), categoryName: "제로", budgetTemplateId: templateId)
        ]
        
        return create(
            id: templateId,
            totalAmount: 100_000_000,
            categoryBudgetTemplates: categoryTemplates
        )
    }
    
    // MARK: - Bulk Generators
    
    /// Generate multiple budget templates with different scenarios
    public static func multipleTemplates() -> [BudgetTemplateDTO] {
        return [
            lowIncome,
            middleIncome,
            highIncome
        ]
    }
    
    /// Create random budget template
    public static func createRandom(categoryCount: Int = 5) -> BudgetTemplateDTO {
        let templateId = UUID()
        let baseAmount = Decimal(Int.random(in: 500_000...5_000_000))
        
        let categoryNames = ["식비", "교통비", "쇼핑", "문화생활", "미용", "의료비", "교육", "기타", "생활용품", "경조사"]
        let selectedCategories = categoryNames.shuffled().prefix(categoryCount)
        
        let categoryTemplates = selectedCategories.map { name in
            let percentage = Double.random(in: 0.1...0.3)
            let amount = baseAmount * Decimal(percentage)
            
            return CategoryBudgetTemplateFactory.create(
                amount: amount,
                categoryID: UUID(),
                categoryName: name,
                budgetTemplateId: templateId
            )
        }
        
        let totalCategoryAmount = categoryTemplates.reduce(0) { $0 + $1.amount }
        let totalAmount = max(totalCategoryAmount, baseAmount)
        
        return create(
            id: templateId,
            totalAmount: totalAmount,
            categoryBudgetTemplates: categoryTemplates
        )
    }
}

// MARK: - CategoryBudgetTemplateFactory

public enum CategoryBudgetTemplateFactory {
    
    /// Create a single category budget template with specified parameters
    public static func create(
        id: UUID = UUID(),
        amount: Decimal,
        categoryID: UUID,
        categoryName: String,
        budgetTemplateId: UUID
    ) -> CategoryBudgetTemplateDTO {
        return CategoryBudgetTemplateDTO(
            id: id,
            amount: amount,
            categoryID: categoryID,
            categoryName: categoryName,
            budgetTemplateId: budgetTemplateId
        )
    }
    
    /// Create a sample category budget template
    public static func sample() -> CategoryBudgetTemplateDTO {
        return create(
            amount: 300_000,
            categoryID: UUID(),
            categoryName: "샘플 카테고리",
            budgetTemplateId: UUID()
        )
    }
    
    /// Create category templates for common Korean expense categories
    public static func commonExpenseTemplates(budgetTemplateId: UUID) -> [CategoryBudgetTemplateDTO] {
        return [
            create(amount: 600_000, categoryID: UUID(), categoryName: "식비", budgetTemplateId: budgetTemplateId),
            create(amount: 300_000, categoryID: UUID(), categoryName: "교통비", budgetTemplateId: budgetTemplateId),
            create(amount: 200_000, categoryID: UUID(), categoryName: "문화생활", budgetTemplateId: budgetTemplateId),
            create(amount: 150_000, categoryID: UUID(), categoryName: "미용", budgetTemplateId: budgetTemplateId),
            create(amount: 100_000, categoryID: UUID(), categoryName: "의료비", budgetTemplateId: budgetTemplateId),
            create(amount: 250_000, categoryID: UUID(), categoryName: "기타", budgetTemplateId: budgetTemplateId)
        ]
    }
}
