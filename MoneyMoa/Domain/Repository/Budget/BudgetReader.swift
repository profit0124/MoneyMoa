//
//  BudgetReader.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/28/25.
//

import Foundation

/// Budget 읽기 전용 인터페이스
public protocol BudgetReader: Sendable {
    
    // MARK: - Core Read Operations
    
    /// 특정 월의 예산 조회
    func fetchBudget(for month: YearMonth) async throws -> BudgetDTO?
    
    /// 특정 월의 예산 조회 (카테고리별 예산 포함)
    func fetchBudgetWithCategories(for month: YearMonth) async throws -> BudgetDTO?
    
    /// 현재 월의 예산 조회 (없으면 자동 생성)
    func fetchCurrentBudget() async throws -> BudgetDTO
    
    /// 현재 월의 예산 조회 (카테고리별 예산 포함)
    func fetchCurrentBudgetWithCategories() async throws -> BudgetDTO
    
    /// 최근 N개월의 예산 목록 조회
    func fetchRecentBudgets(months: Int) async throws -> [BudgetDTO]
}
