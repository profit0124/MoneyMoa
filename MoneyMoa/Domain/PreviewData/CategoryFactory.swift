//
//  CategoryFactory.swift
//  MoneyMoa
//
//  Created by Claude Code on 9/3/25.
//

import Foundation

/// Factory for generating Category and SubCategory test data
/// - Provides realistic category data for testing and previews
/// - Supports Korean localization and various scenarios
/// - Includes both Category and SubCategory generation with proper relationships
public enum CategoryFactory {
    
    // MARK: - Basic Builders
    
    /// Create a simple sample category for testing
    public static func sampleCategory() -> CategoryDTO {
        return createCategory(
            name: "샘플 카테고리",
            iconName: "folder",
            transactionType: .variableExpense,
            isActive: true,
            orderIndex: 0
        )
    }
    
    /// Create a simple sample subcategory for testing
    public static func sampleSubCategory() -> SubCategoryDTO {
        let parentCategory = sampleCategory()
        return createSubCategory(
            name: "샘플 하위카테고리",
            transactionType: .variableExpense,
            parentCategory: parentCategory,
            isActive: true,
            orderIndex: 0
        )
    }
    
    /// Create a single category with specified parameters
    public static func createCategory(
        id: UUID = UUID(),
        name: String,
        iconName: String,
        transactionType: TransactionType,
        isActive: Bool = true,
        orderIndex: Int
    ) -> CategoryDTO {
        return CategoryDTO(
            id: id,
            name: name,
            iconName: iconName,
            transactionType: transactionType,
            isActive: isActive,
            orderIndex: orderIndex,
            subCategories: []
        )
    }
    
    /// Create a single subcategory with specified parameters
    public static func createSubCategory(
        id: UUID = UUID(),
        name: String,
        transactionType: TransactionType,
        parentCategory: CategoryDTO,
        isActive: Bool = true,
        orderIndex: Int
    ) -> SubCategoryDTO {
        return SubCategoryDTO(
            id: id,
            name: name,
            transactionType: transactionType,
            isActive: isActive,
            orderIndex: orderIndex,
            categoryId: parentCategory.id,
            categoryName: parentCategory.name,
            categoryIconName: parentCategory.iconName
        )
    }
    
    /// Create random categories with Korean names
    public static func createRandomCategories(count: Int) -> [CategoryDTO] {
        let transactionTypes: [TransactionType] = [.income, .fixedExpense, .variableExpense]
        var categories: [CategoryDTO] = []
        
        for index in 0..<count {
            let type = transactionTypes.randomElement()!
            let categoryTemplate = getRandomCategoryTemplate(for: type)
            
            categories.append(
                createCategory(
                    name: categoryTemplate.name,
                    iconName: categoryTemplate.iconName,
                    transactionType: type,
                    isActive: Bool.random() || Double.random(in: 0...1) > 0.2, // 80% active
                    orderIndex: index
                )
            )
        }
        
        return categories
    }
    
    // MARK: - Bulk Generators
    
    /// Generate a set of random categories and subcategories
    public static func randomSet(categoryCount: Int = 10, subCategoryCount: Int = 30) -> (categories: [CategoryDTO], subCategories: [SubCategoryDTO]) {
        let categories = createRandomCategories(count: categoryCount)
        let subCategories = createRandomSubCategories(for: categories, targetCount: subCategoryCount)
        
        return (categories, subCategories)
    }
    
    /// Generate realistic category and subcategory data with proper Korean distribution
    public static func realistic() -> (categories: [CategoryDTO], subCategories: [SubCategoryDTO]) {
        let categories = createRealisticCategories()
        let subCategories = createRealisticSubCategories(for: categories)
        
        return (categories, subCategories)
    }
    
    // MARK: - Test Scenarios
    
    /// Empty category list
    public static var empty: (categories: [CategoryDTO], subCategories: [SubCategoryDTO]) {
        return ([], [])
    }
    
    /// Minimal category set for basic testing
    public static var minimal: (categories: [CategoryDTO], subCategories: [SubCategoryDTO]) {
        let categories = [
            createCategory(name: "식비", iconName: "fork.knife", transactionType: .variableExpense, orderIndex: 0),
            createCategory(name: "월급", iconName: "banknote", transactionType: .income, orderIndex: 0)
        ]
        
        let subCategories = [
            createSubCategory(name: "외식비", transactionType: .variableExpense, parentCategory: categories[0], orderIndex: 0),
            createSubCategory(name: "월급여", transactionType: .income, parentCategory: categories[1], orderIndex: 0)
        ]
        
        return (categories, subCategories)
    }
    
    /// Normal category set for regular testing
    public static var normal: (categories: [CategoryDTO], subCategories: [SubCategoryDTO]) {
        let categories = createNormalCategories()
        let subCategories = createNormalSubCategories(for: categories)
        
        return (categories, subCategories)
    }
    
    /// Edge cases and boundary values
    public static var edge: (categories: [CategoryDTO], subCategories: [SubCategoryDTO]) {
        let categories = [
            // Very long name
            createCategory(name: "아주아주아주아주아주아주아주아주긴카테고리이름", iconName: "folder", transactionType: .variableExpense, orderIndex: 0),
            // Single character name
            createCategory(name: "A", iconName: "a", transactionType: .income, orderIndex: 1),
            // Inactive category
            createCategory(name: "비활성카테고리", iconName: "trash", transactionType: .fixedExpense, isActive: false, orderIndex: 2),
            // Maximum order index
            createCategory(name: "마지막카테고리", iconName: "arrow.down", transactionType: .variableExpense, orderIndex: Int.max)
        ]
        
        let subCategories = [
            createSubCategory(name: "아주아주아주아주아주아주긴하위카테고리이름", transactionType: .variableExpense, parentCategory: categories[0], orderIndex: 0),
            createSubCategory(name: "B", transactionType: .income, parentCategory: categories[1], orderIndex: 0),
            createSubCategory(name: "비활성하위", transactionType: .fixedExpense, parentCategory: categories[2], isActive: false, orderIndex: 0)
        ]
        
        return (categories, subCategories)
    }
    
    // MARK: - Private Helpers
    
    private static func createRealisticCategories() -> [CategoryDTO] {
        var categories: [CategoryDTO] = []
        var orderIndex = 0
        
        // Income Categories
        let incomeCategories = [
            ("급여", "banknote"),
            ("부수입", "plus.circle"),
            ("투자수익", "chart.line.uptrend.xyaxis"),
            ("용돈", "gift")
        ]
        
        for (name, icon) in incomeCategories {
            categories.append(
                createCategory(name: name, iconName: icon, transactionType: .income, orderIndex: orderIndex)
            )
            orderIndex += 1
        }
        
        // Fixed Expense Categories
        orderIndex = 0
        let fixedExpenseCategories = [
            ("주거비", "house"),
            ("보험료", "shield"),
            ("통신비", "phone"),
            ("대출이자", "creditcard"),
            ("구독서비스", "tv")
        ]
        
        for (name, icon) in fixedExpenseCategories {
            categories.append(
                createCategory(name: name, iconName: icon, transactionType: .fixedExpense, orderIndex: orderIndex)
            )
            orderIndex += 1
        }
        
        // Variable Expense Categories
        orderIndex = 0
        let variableExpenseCategories = [
            ("식비", "fork.knife"),
            ("교통비", "car"),
            ("쇼핑", "bag"),
            ("의료비", "cross.case"),
            ("문화생활", "gamecontroller"),
            ("미용", "scissors"),
            ("교육", "book"),
            ("경조사", "gift.circle"),
            ("기타", "ellipsis.circle")
        ]
        
        for (name, icon) in variableExpenseCategories {
            categories.append(
                createCategory(name: name, iconName: icon, transactionType: .variableExpense, orderIndex: orderIndex)
            )
            orderIndex += 1
        }
        
        return categories
    }
    
    private static func createNormalCategories() -> [CategoryDTO] {
        var categories: [CategoryDTO] = []
        var orderIndex = 0
        
        // Income
        categories.append(createCategory(name: "급여", iconName: "banknote", transactionType: .income, orderIndex: orderIndex))
        orderIndex += 1
        categories.append(createCategory(name: "부수입", iconName: "plus.circle", transactionType: .income, orderIndex: orderIndex))
        orderIndex += 1
        
        // Fixed Expense
        orderIndex = 0
        categories.append(createCategory(name: "주거비", iconName: "house", transactionType: .fixedExpense, orderIndex: orderIndex))
        orderIndex += 1
        categories.append(createCategory(name: "보험료", iconName: "shield", transactionType: .fixedExpense, orderIndex: orderIndex))
        orderIndex += 1
        
        // Variable Expense
        orderIndex = 0
        categories.append(createCategory(name: "식비", iconName: "fork.knife", transactionType: .variableExpense, orderIndex: orderIndex))
        orderIndex += 1
        categories.append(createCategory(name: "쇼핑", iconName: "bag", transactionType: .variableExpense, orderIndex: orderIndex))
        orderIndex += 1
        categories.append(createCategory(name: "문화생활", iconName: "gamecontroller", transactionType: .variableExpense, orderIndex: orderIndex))
        
        return categories
    }
    
    private static func createRealisticSubCategories(for categories: [CategoryDTO]) -> [SubCategoryDTO] {
        var subCategories: [SubCategoryDTO] = []
        
        for category in categories {
            let categorySubCategories = createRealisticSubCategoriesForCategory(category)
            subCategories.append(contentsOf: categorySubCategories)
        }
        
        return subCategories
    }
    
    private static func createNormalSubCategories(for categories: [CategoryDTO]) -> [SubCategoryDTO] {
        var subCategories: [SubCategoryDTO] = []
        
        for category in categories {
            let categorySubCategories = createNormalSubCategoriesForCategory(category)
            subCategories.append(contentsOf: categorySubCategories)
        }
        
        return subCategories
    }
    
    private static func createRandomSubCategories(for categories: [CategoryDTO], targetCount: Int) -> [SubCategoryDTO] {
        var subCategories: [SubCategoryDTO] = []
        let subCategoriesPerCategory = max(1, targetCount / categories.count)
        
        for category in categories {
            let count = Int.random(in: 1...subCategoriesPerCategory)
            for orderIndex in 0..<count {
                let template = getRandomSubCategoryTemplate(for: category.transactionType)
                subCategories.append(
                    createSubCategory(
                        name: template,
                        transactionType: category.transactionType,
                        parentCategory: category,
                        isActive: Bool.random() || Double.random(in: 0...1) > 0.1, // 90% active
                        orderIndex: orderIndex
                    )
                )
            }
        }
        
        return subCategories
    }
    
    private static func createRealisticSubCategoriesForCategory(_ category: CategoryDTO) -> [SubCategoryDTO] {
        let subCategoryNames = CategorySubCategoryMapping.getRealisticSubCategoryNames(for: category.name)
        
        return subCategoryNames.enumerated().map { index, name in
            createSubCategory(
                name: name,
                transactionType: category.transactionType,
                parentCategory: category,
                orderIndex: index
            )
        }
    }
    
    private static func createNormalSubCategoriesForCategory(_ category: CategoryDTO) -> [SubCategoryDTO] {
        let subCategoryNames = CategorySubCategoryMapping.getNormalSubCategoryNames(for: category.name)
        
        return subCategoryNames.enumerated().map { index, name in
            createSubCategory(
                name: name,
                transactionType: category.transactionType,
                parentCategory: category,
                orderIndex: index
            )
        }
    }
    
    private static func getRandomCategoryTemplate(for type: TransactionType) -> (name: String, iconName: String) {
        switch type {
        case .income:
            let templates = [
                ("급여", "banknote"),
                ("부수입", "plus.circle"),
                ("투자수익", "chart.line.uptrend.xyaxis"),
                ("용돈", "gift")
            ]
            return templates.randomElement()!
            
        case .fixedExpense:
            let templates = [
                ("주거비", "house"),
                ("보험료", "shield"),
                ("통신비", "phone"),
                ("대출이자", "creditcard"),
                ("구독서비스", "tv")
            ]
            return templates.randomElement()!
            
        case .variableExpense:
            let templates = [
                ("식비", "fork.knife"),
                ("교통비", "car"),
                ("쇼핑", "bag"),
                ("의료비", "cross.case"),
                ("문화생활", "gamecontroller"),
                ("미용", "scissors"),
                ("교육", "book"),
                ("경조사", "gift.circle"),
                ("기타", "ellipsis.circle")
            ]
            return templates.randomElement()!
        }
    }
    
    private static func getRandomSubCategoryTemplate(for type: TransactionType) -> String {
        switch type {
        case .income:
            let templates = ["월급", "상여금", "프리랜서", "투자수익", "중고판매", "알바", "용돈"]
            return templates.randomElement()!
            
        case .fixedExpense:
            let templates = ["월세", "관리비", "보험료", "통신비", "대출이자", "구독료", "주유비"]
            return templates.randomElement()!
            
        case .variableExpense:
            let templates = ["외식", "마트", "카페", "택시", "영화", "쇼핑", "미용", "병원", "약국"]
            return templates.randomElement()!
        }
    }
}

// MARK: - Convenience Extensions

public extension CategoryFactory {
    /// Get categories only from realistic data
    static func realisticCategories() -> [CategoryDTO] {
        return realistic().categories
    }
    
    /// Get subcategories only from realistic data
    static func realisticSubCategories() -> [SubCategoryDTO] {
        return realistic().subCategories
    }
    
    /// Get categories only from normal data
    static func normalCategories() -> [CategoryDTO] {
        return normal.categories
    }
    
    /// Get subcategories only from normal data
    static func normalSubCategories() -> [SubCategoryDTO] {
        return normal.subCategories
    }
    
    /// Get categories only from minimal data
    static func minimalCategories() -> [CategoryDTO] {
        return minimal.categories
    }
    
    /// Get subcategories only from minimal data
    static func minimalSubCategories() -> [SubCategoryDTO] {
        return minimal.subCategories
    }
}

// MARK: - Category SubCategory Mapping

private enum CategorySubCategoryMapping {
    
    static func getRealisticSubCategoryNames(for categoryName: String) -> [String] {
        return realisticMappings[categoryName] ?? ["기본"]
    }
    
    static func getNormalSubCategoryNames(for categoryName: String) -> [String] {
        return normalMappings[categoryName] ?? ["기본"]
    }
    
    private static let realisticMappings: [String: [String]] = [
        "급여": ["월급", "상여금", "성과급", "야근수당"],
        "부수입": ["프리랜서", "투자수익", "중고판매", "알바"],
        "투자수익": ["주식", "펀드", "채권", "예적금이자"],
        "용돈": ["부모님용돈", "배우자용돈", "기타용돈"],
        "주거비": ["월세", "관리비", "공과금", "주택담보대출"],
        "보험료": ["건강보험", "자동차보험", "생명보험", "손해보험"],
        "통신비": ["휴대폰요금", "인터넷요금", "케이블TV"],
        "대출이자": ["신용대출", "주택대출", "자동차대출"],
        "구독서비스": ["넷플릭스", "스포티파이", "유튜브프리미엄", "기타구독"],
        "식비": ["외식", "배달음식", "마트장보기", "카페", "술"],
        "교통비": ["대중교통", "택시", "주유비", "주차비", "톨게이트"],
        "쇼핑": ["의류", "신발", "가방", "액세서리", "생활용품"],
        "의료비": ["병원비", "약값", "건강검진", "치과", "안경"],
        "문화생활": ["영화", "공연", "전시", "게임", "독서"],
        "미용": ["미용실", "화장품", "네일", "마사지", "피부관리"],
        "교육": ["도서", "강의", "학원", "자격증", "어학"],
        "경조사": ["결혼식", "장례식", "돌잔치", "생일선물"],
        "기타": ["잡비", "기부", "벌금", "수수료"]
    ]
    
    private static let normalMappings: [String: [String]] = [
        "급여": ["월급", "상여금"],
        "부수입": ["프리랜서", "투자수익"],
        "주거비": ["월세", "관리비"],
        "보험료": ["건강보험", "자동차보험"],
        "식비": ["외식", "마트장보기", "카페"],
        "쇼핑": ["의류", "생활용품"],
        "문화생활": ["영화", "게임", "독서"]
    ]
}
