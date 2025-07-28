//
//  BudgetRepository.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/28/25.
//

import Foundation

// MARK: - Budget Repository Protocol

public protocol BudgetRepository {
    
    // MARK: - Template 관리 (Template Management)
    
    /// 현재 예산 템플릿 조회 (항상 하나만 존재)
    /// - Returns: 현재 예산 템플릿 또는 nil (최초 실행 시)
    func fetchBudgetTemplate() async throws -> BudgetTemplateDTO?
    
    /// 예산 템플릿 조회 (카테고리별 예산 포함)
    /// - Returns: 카테고리별 예산이 포함된 예산 템플릿
    func fetchBudgetTemplateWithCategories() async throws -> BudgetTemplateDTO?
    
    /// 예산 템플릿 생성/업데이트 (하나만 존재, 기존 것을 교체)
    /// - Parameter template: 새로운 예산 템플릿 정보
    func upsertBudgetTemplate(_ template: BudgetTemplateDTO) async throws
    
    /// 카테고리별 예산 템플릿 업데이트
    /// - Parameters:
    ///   - categoryBudgetTemplates: 업데이트할 카테고리별 예산 목록
    func updateCategoryBudgetTemplates(_ categoryBudgetTemplates: [CategoryBudgetTemplateDTO]) async throws
    
    // MARK: - Budget 관리 (Monthly Budget Management)
    
    /// 특정 월의 예산 조회
    /// - Parameter month: 조회할 년월
    /// - Returns: 해당 월의 예산 또는 nil
    func fetchBudget(for month: YearMonth) async throws -> BudgetDTO?
    
    /// 특정 월의 예산 조회 (카테고리별 예산 포함)
    /// - Parameter month: 조회할 년월
    /// - Returns: 카테고리별 예산이 포함된 월별 예산
    func fetchBudgetWithCategories(for month: YearMonth) async throws -> BudgetDTO?
    
    /// 현재 월의 예산 조회 (메인 화면용)
    /// - Returns: 현재 월의 예산 (없으면 자동 생성)
    func fetchCurrentBudget() async throws -> BudgetDTO
    
    /// 현재 월의 예산 조회 (카테고리별 예산 포함, 메인 화면용)
    /// - Returns: 카테고리별 예산이 포함된 현재 월의 예산
    func fetchCurrentBudgetWithCategories() async throws -> BudgetDTO
    
    /// 특정 월의 예산이 없으면 템플릿 기반으로 자동 생성
    /// - Parameter month: 생성할 년월
    /// - Returns: 생성된 월별 예산
    func ensureBudgetExists(for month: YearMonth) async throws -> BudgetDTO
    
    /// 월별 예산 목록 조회 (최근 N개월)
    /// - Parameter months: 조회할 개월 수 (기본값: 12개월)
    /// - Returns: 최근 N개월의 예산 목록 (최신순)
    func fetchRecentBudgets(months: Int) async throws -> [BudgetDTO]
    
    
    // MARK: - 예산 수정 (Budget Updates)
    
    /// 특정 월의 카테고리별 예산 수정
    /// - Parameters:
    ///   - month: 수정할 년월
    ///   - categoryBudgets: 수정할 카테고리별 예산 목록
    func updateCategoryBudgets(for month: YearMonth, categoryBudgets: [CategoryBudgetDTO]) async throws
    
    /// 특정 카테고리의 예산 수정 (해당 월만)
    /// - Parameters:
    ///   - categoryId: 카테고리 ID
    ///   - amount: 새로운 예산 금액
    ///   - month: 수정할 년월
    func updateCategoryBudget(categoryId: UUID, amount: Decimal, for month: YearMonth) async throws
}