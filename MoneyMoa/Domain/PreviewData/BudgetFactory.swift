//
//  BudgetFactory.swift
//  MoneyMoa
//
//  Created by Claude Code on 9/8/25.
//

import Foundation

/// Factory for generating Budget test data
/// - Provides realistic budget data for testing and previews
/// - Supports various scenarios and monthly budget generation
public enum BudgetFactory {
    
    // MARK: - Basic Builders
    
    /// Create a simple sample budget for testing
    public static func sample() -> BudgetDTO {
        return create(
            month: YearMonth.current,
            totalAmount: 1_500_000,
            categoryBudgets: [
                CategoryBudgetFactory.create(
                    amount: 500_000,
                    categoryID: UUID(),
                    categoryName: "식비",
                    budgetId: UUID()
                ),
                CategoryBudgetFactory.create(
                    amount: 300_000,
                    categoryID: UUID(),
                    categoryName: "교통비",
                    budgetId: UUID()
                )
            ]
        )
    }
    
    /// Create a single budget with specified parameters
    public static func create(
        id: UUID = UUID(),
        month: YearMonth,
        totalAmount: Decimal,
        categoryBudgets: [CategoryBudgetDTO] = []
    ) -> BudgetDTO {
        return BudgetDTO(
            id: id,
            month: month,
            totalAmount: totalAmount,
            categoryBudgets: categoryBudgets
        )
    }
    
    /// Create a realistic budget for specific month with Korean categories
    public static func createRealistic(for month: YearMonth) -> BudgetDTO {
        let budgetId = UUID()
        
        let categoryBudgets = [
            CategoryBudgetFactory.create(amount: 600_000, categoryID: UUID(), categoryName: "식비", budgetId: budgetId),
            CategoryBudgetFactory.create(amount: 300_000, categoryID: UUID(), categoryName: "교통비", budgetId: budgetId),
            CategoryBudgetFactory.create(amount: 400_000, categoryID: UUID(), categoryName: "쇼핑", budgetId: budgetId),
            CategoryBudgetFactory.create(amount: 200_000, categoryID: UUID(), categoryName: "문화생활", budgetId: budgetId),
            CategoryBudgetFactory.create(amount: 150_000, categoryID: UUID(), categoryName: "미용", budgetId: budgetId),
            CategoryBudgetFactory.create(amount: 100_000, categoryID: UUID(), categoryName: "의료비", budgetId: budgetId),
            CategoryBudgetFactory.create(amount: 250_000, categoryID: UUID(), categoryName: "기타", budgetId: budgetId)
        ]
        
        let totalAmount = categoryBudgets.reduce(0) { $0 + $1.amount }
        
        return create(
            id: budgetId,
            month: month,
            totalAmount: totalAmount,
            categoryBudgets: categoryBudgets
        )
    }
    
    /// Create budget from template
    public static func createFromTemplate(_ template: BudgetTemplateDTO, for month: YearMonth) -> BudgetDTO {
        return template.toBudgetDTO(for: month)
    }
    
    // MARK: - Test Scenarios
    
    /// Empty budget
    public static func empty(for month: YearMonth = YearMonth.current) -> BudgetDTO {
        create(month: month, totalAmount: 0, categoryBudgets: [])
    }
    
    /// Minimal budget for basic testing
    public static func minimal(for month: YearMonth = YearMonth.current) -> BudgetDTO {
        let budgetId = UUID()
        return create(
            id: budgetId,
            month: month,
            totalAmount: 800_000,
            categoryBudgets: [
                CategoryBudgetFactory.create(
                    amount: 500_000,
                    categoryID: UUID(),
                    categoryName: "식비",
                    budgetId: budgetId
                ),
                CategoryBudgetFactory.create(
                    amount: 300_000,
                    categoryID: UUID(),
                    categoryName: "교통비",
                    budgetId: budgetId
                )
            ]
        )
    }
    
    /// Normal budget for regular testing
    public static func normal(for month: YearMonth = YearMonth.current) -> BudgetDTO {
        let budgetId = UUID()
        
        let categoryBudgets = [
            CategoryBudgetFactory.create(amount: 500_000, categoryID: UUID(), categoryName: "식비", budgetId: budgetId),
            CategoryBudgetFactory.create(amount: 250_000, categoryID: UUID(), categoryName: "교통비", budgetId: budgetId),
            CategoryBudgetFactory.create(amount: 300_000, categoryID: UUID(), categoryName: "쇼핑", budgetId: budgetId),
            CategoryBudgetFactory.create(amount: 150_000, categoryID: UUID(), categoryName: "문화생활", budgetId: budgetId),
            CategoryBudgetFactory.create(amount: 100_000, categoryID: UUID(), categoryName: "미용", budgetId: budgetId)
        ]
        
        return create(
            id: budgetId,
            month: month,
            totalAmount: 1_300_000,
            categoryBudgets: categoryBudgets
        )
    }
    
    /// Budgets for different income levels
    public static func lowIncome(for month: YearMonth = YearMonth.current) -> BudgetDTO {
        let budgetId = UUID()
        
        let categoryBudgets = [
            CategoryBudgetFactory.create(amount: 300_000, categoryID: UUID(), categoryName: "식비", budgetId: budgetId),
            CategoryBudgetFactory.create(amount: 150_000, categoryID: UUID(), categoryName: "교통비", budgetId: budgetId),
            CategoryBudgetFactory.create(amount: 100_000, categoryID: UUID(), categoryName: "생활용품", budgetId: budgetId),
            CategoryBudgetFactory.create(amount: 50_000, categoryID: UUID(), categoryName: "기타", budgetId: budgetId)
        ]
        
        return create(
            id: budgetId,
            month: month,
            totalAmount: 600_000,
            categoryBudgets: categoryBudgets
        )
    }
    
    public static func middleIncome(for month: YearMonth = YearMonth.current) -> BudgetDTO {
        let budgetId = UUID()
        
        let categoryBudgets = [
            CategoryBudgetFactory.create(amount: 700_000, categoryID: UUID(), categoryName: "식비", budgetId: budgetId),
            CategoryBudgetFactory.create(amount: 400_000, categoryID: UUID(), categoryName: "교통비", budgetId: budgetId),
            CategoryBudgetFactory.create(amount: 500_000, categoryID: UUID(), categoryName: "쇼핑", budgetId: budgetId),
            CategoryBudgetFactory.create(amount: 300_000, categoryID: UUID(), categoryName: "문화생활", budgetId: budgetId),
            CategoryBudgetFactory.create(amount: 200_000, categoryID: UUID(), categoryName: "미용", budgetId: budgetId),
            CategoryBudgetFactory.create(amount: 400_000, categoryID: UUID(), categoryName: "기타", budgetId: budgetId)
        ]
        
        return create(
            id: budgetId,
            month: month,
            totalAmount: 2_500_000,
            categoryBudgets: categoryBudgets
        )
    }
    
    public static func highIncome(for month: YearMonth = YearMonth.current) -> BudgetDTO {
        let budgetId = UUID()
        
        let categoryBudgets = [
            CategoryBudgetFactory.create(amount: 1_000_000, categoryID: UUID(), categoryName: "식비", budgetId: budgetId),
            CategoryBudgetFactory.create(amount: 500_000, categoryID: UUID(), categoryName: "교통비", budgetId: budgetId),
            CategoryBudgetFactory.create(amount: 800_000, categoryID: UUID(), categoryName: "쇼핑", budgetId: budgetId),
            CategoryBudgetFactory.create(amount: 600_000, categoryID: UUID(), categoryName: "문화생활", budgetId: budgetId),
            CategoryBudgetFactory.create(amount: 400_000, categoryID: UUID(), categoryName: "미용", budgetId: budgetId),
            CategoryBudgetFactory.create(amount: 300_000, categoryID: UUID(), categoryName: "의료비", budgetId: budgetId),
            CategoryBudgetFactory.create(amount: 400_000, categoryID: UUID(), categoryName: "교육", budgetId: budgetId),
            CategoryBudgetFactory.create(amount: 1_000_000, categoryID: UUID(), categoryName: "기타", budgetId: budgetId)
        ]
        
        return create(
            id: budgetId,
            month: month,
            totalAmount: 5_000_000,
            categoryBudgets: categoryBudgets
        )
    }
    
    /// Edge cases and boundary values
    public static func edge(for month: YearMonth = YearMonth.current) -> BudgetDTO {
        let budgetId = UUID()
        
        let categoryBudgets = [
            // Very small amount
            CategoryBudgetFactory.create(amount: 1, categoryID: UUID(), categoryName: "최소", budgetId: budgetId),
            // Very large amount
            CategoryBudgetFactory.create(amount: 99_999_999, categoryID: UUID(), categoryName: "최대", budgetId: budgetId),
            // Zero amount
            CategoryBudgetFactory.create(amount: 0, categoryID: UUID(), categoryName: "제로", budgetId: budgetId)
        ]
        
        return create(
            id: budgetId,
            month: month,
            totalAmount: 100_000_000,
            categoryBudgets: categoryBudgets
        )
    }
    
    // MARK: - Bulk Generators
    
    /// Generate budgets for multiple months
    public static func multipleMonths(count: Int = 12, scenario: BudgetScenario = .normal) -> [BudgetDTO] {
        let currentMonth = YearMonth.current
        var budgets: [BudgetDTO] = []
        
        for i in 0..<count {
            let month = YearMonth(year: currentMonth.year, month: max(1, currentMonth.month - i))
            let budget = createBudget(for: month, scenario: scenario)
            budgets.append(budget)
        }
        
        return budgets.sorted { $0.month > $1.month }
    }
    
    /// Create realistic budget history for testing
    public static func recentHistory() -> [BudgetDTO] {
        let currentMonth = YearMonth.current
        let scenarios: [BudgetScenario] = [.normal, .lowIncome, .middleIncome, .highIncome]
        
        return (0..<6).map { i in
            let month = YearMonth(year: currentMonth.year, month: max(1, currentMonth.month - i))
            let scenario = scenarios[i % scenarios.count]
            return createBudget(for: month, scenario: scenario)
        }.sorted { $0.month > $1.month }
    }
    
    /// Create random budget
    public static func createRandom(for month: YearMonth = YearMonth.current, categoryCount: Int = 5) -> BudgetDTO {
        let budgetId = UUID()
        let baseAmount = Decimal(Int.random(in: 500_000...5_000_000))
        
        let categoryNames = ["식비", "교통비", "쇼핑", "문화생활", "미용", "의료비", "교육", "기타", "생활용품", "경조사"]
        let selectedCategories = categoryNames.shuffled().prefix(categoryCount)
        
        let categoryBudgets = selectedCategories.map { name in
            let percentage = Double.random(in: 0.1...0.3)
            let amount = baseAmount * Decimal(percentage)
            
            return CategoryBudgetFactory.create(
                amount: amount,
                categoryID: UUID(),
                categoryName: name,
                budgetId: budgetId
            )
        }
        
        let totalCategoryAmount = categoryBudgets.reduce(0) { $0 + $1.amount }
        let totalAmount = max(totalCategoryAmount, baseAmount)
        
        return create(
            id: budgetId,
            month: month,
            totalAmount: totalAmount,
            categoryBudgets: categoryBudgets
        )
    }
    
    // MARK: - Private Helpers
    
    private static func createBudget(for month: YearMonth, scenario: BudgetScenario) -> BudgetDTO {
        switch scenario {
        case .minimal:
            return minimal(for: month)
        case .normal:
            return normal(for: month)
        case .lowIncome:
            return lowIncome(for: month)
        case .middleIncome:
            return middleIncome(for: month)
        case .highIncome:
            return highIncome(for: month)
        case .edge:
            return edge(for: month)
        }
    }
    
    public enum BudgetScenario {
        case minimal, normal, lowIncome, middleIncome, highIncome, edge
    }
}

// MARK: - CategoryBudgetFactory

public enum CategoryBudgetFactory {
    
    /// Create a single category budget with specified parameters
    public static func create(
        id: UUID = UUID(),
        amount: Decimal,
        categoryID: UUID,
        categoryName: String,
        budgetId: UUID
    ) -> CategoryBudgetDTO {
        return CategoryBudgetDTO(
            id: id,
            amount: amount,
            categoryID: categoryID,
            categoryName: categoryName,
            budgetId: budgetId
        )
    }
    
    /// Create a sample category budget
    public static func sample() -> CategoryBudgetDTO {
        return create(
            amount: 300_000,
            categoryID: UUID(),
            categoryName: "샘플 카테고리",
            budgetId: UUID()
        )
    }
    
    /// Create category budgets for common Korean expense categories
    public static func commonExpenseBudgets(budgetId: UUID) -> [CategoryBudgetDTO] {
        return [
            create(amount: 600_000, categoryID: UUID(), categoryName: "식비", budgetId: budgetId),
            create(amount: 300_000, categoryID: UUID(), categoryName: "교통비", budgetId: budgetId),
            create(amount: 200_000, categoryID: UUID(), categoryName: "문화생활", budgetId: budgetId),
            create(amount: 150_000, categoryID: UUID(), categoryName: "미용", budgetId: budgetId),
            create(amount: 100_000, categoryID: UUID(), categoryName: "의료비", budgetId: budgetId),
            create(amount: 250_000, categoryID: UUID(), categoryName: "기타", budgetId: budgetId)
        ]
    }
}

// MARK: - Convenience Extensions

public extension BudgetFactory {
    /// Get current month budget with normal scenario
    static var currentNormal: BudgetDTO {
        return normal()
    }
    
    /// Get previous month budget with normal scenario
    static var previousNormal: BudgetDTO {
        let previousMonth = YearMonth.current.previousMonth()
        return normal(for: previousMonth)
    }
    
    /// Get next month budget with normal scenario
    static var nextNormal: BudgetDTO {
        let nextMonth = YearMonth.current.nextMonth()
        return normal(for: nextMonth)
    }
}
