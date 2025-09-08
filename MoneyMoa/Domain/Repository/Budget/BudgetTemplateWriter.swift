//
//  BudgetTemplateWriter.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/28/25.
//

import Foundation

/// BudgetTemplate 쓰기 전용 인터페이스
public protocol BudgetTemplateWriter: Sendable {
    
    // MARK: - Core Write Operations
    
    /// 새로운 예산 템플릿 생성
    @discardableResult
    func createBudgetTemplate(_ template: BudgetTemplateDTO) async throws -> BudgetTemplateDTO
    
    /// 기존 예산 템플릿 업데이트
    @discardableResult
    func updateBudgetTemplate(_ template: BudgetTemplateDTO) async throws -> BudgetTemplateDTO
    
    /// 카테고리별 예산 템플릿 업데이트
    func updateCategoryBudgetTemplates(_ categoryBudgetTemplates: [CategoryBudgetTemplateDTO]) async throws
}
