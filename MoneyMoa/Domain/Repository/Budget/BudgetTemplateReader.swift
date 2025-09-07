//
//  BudgetTemplateReader.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/28/25.
//

import Foundation

/// BudgetTemplate 읽기 전용 인터페이스
public protocol BudgetTemplateReader: Sendable {
    
    // MARK: - Core Read Operations
    
    /// 현재 예산 템플릿 조회 (항상 하나만 존재)
    func fetchBudgetTemplate() async throws -> BudgetTemplateDTO?
    
    /// 예산 템플릿 조회 (카테고리별 예산 포함)
    func fetchBudgetTemplateWithCategories() async throws -> BudgetTemplateDTO?
}
