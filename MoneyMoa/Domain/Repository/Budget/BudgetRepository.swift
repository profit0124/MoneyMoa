//
//  BudgetRepository.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/28/25.
//

import Foundation

/// Budget 통합 Repository (Reader + Writer)
public typealias BudgetRepository = BudgetReader & BudgetWriter

/// BudgetTemplate 통합 Repository (Reader + Writer)
public typealias BudgetTemplateRepository = BudgetTemplateReader & BudgetTemplateWriter

/// 전체 Budget 시스템 Repository (Budget + Template)
public typealias CompleteBudgetRepository = BudgetRepository & BudgetTemplateRepository
