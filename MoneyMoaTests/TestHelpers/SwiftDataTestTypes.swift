//
//  SwiftDataTestTypes.swift
//  MoneyMoaTests
//
//  Created by Sooik Kim on 7/27/25.
//

import Foundation
@testable import MoneyMoa

// MARK: - SwiftData Model Type Aliases for Tests
// 테스트에서 SwiftData 모델들의 타입 충돌을 방지하기 위한 typealias 정의

public typealias CategoryModel = MoneyMoa.Category
public typealias SubCategoryModel = MoneyMoa.SubCategory
public typealias TransactionModel = MoneyMoa.Transaction
public typealias PaymentMethodModel = MoneyMoa.PaymentMethod
public typealias BudgetTemplateModel = MoneyMoa.BudgetTemplate
public typealias CategoryBudgetTemplateModel = MoneyMoa.CategoryBudgetTemplate
public typealias BudgetModel = MoneyMoa.Budget
public typealias CategoryBudgetModel = MoneyMoa.CategoryBudget
