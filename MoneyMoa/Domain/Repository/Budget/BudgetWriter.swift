//
//  BudgetWriter.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/28/25.
//

import Foundation

/// Budget 쓰기 전용 인터페이스
public protocol BudgetWriter: Sendable {

    // MARK: - Core Write Operations

    /// 새로운 예산 생성
    @discardableResult
    func createBudget(_ budget: BudgetDTO) async throws -> BudgetDTO

    /// 특정 월의 예산 생성 (기존 예산 덮어쓰기)
    func createBudget(for month: YearMonth, budget: BudgetDTO) async throws

    /// 특정 월의 예산이 없으면 템플릿 기반으로 자동 생성
    func ensureBudgetExists(for month: YearMonth) async throws -> BudgetDTO

    // MARK: - Update Operations

    /// 특정 월의 예산 전체 정보 수정
    func updateBudget(for month: YearMonth, budget: BudgetDTO) async throws

    /// 특정 월의 예산 총 금액만 수정
    func updateBudgetTotalAmount(for month: YearMonth, totalAmount: Decimal) async throws

    /// 특정 월의 카테고리별 예산 수정
    func updateCategoryBudgets(for month: YearMonth, categoryBudgets: [CategoryBudgetDTO]) async throws

    /// 특정 카테고리의 예산 수정
    func updateCategoryBudget(categoryId: UUID, amount: Decimal, for month: YearMonth) async throws
}
