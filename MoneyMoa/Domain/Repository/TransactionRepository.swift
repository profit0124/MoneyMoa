//
//  TransactionRepositories.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/27/25.
//

import Foundation

// MARK: - Transaction Repository Protocol

public protocol TransactionRepository {
    
    // MARK: - 조회 (Fetch Operations)
    
    /// 모든 거래 내역 조회 (최신순)
    /// - Returns: 전체 거래 내역 목록 (날짜 내림차순으로 정렬)
    func fetchTransactions() async throws -> [TransactionDTO]
    
    /// 특정 거래 조회
    /// - Parameter id: 거래 ID
    /// - Returns: 해당 거래 또는 nil
    func fetchTransaction(id: UUID) async throws -> TransactionDTO?
    
    /// 특정 기간의 거래 내역 조회 (메인 화면, 월별 보기)
    /// - Parameters:
    ///   - startDate: 시작 날짜
    ///   - endDate: 종료 날짜
    /// - Returns: 해당 기간의 거래 내역 목록
    func fetchTransactions(from startDate: Date, to endDate: Date) async throws -> [TransactionDTO]
    
    /// 특정 서브카테고리의 거래 내역 조회
    /// - Parameter subCategoryId: 서브카테고리 ID
    /// - Returns: 해당 서브카테고리의 거래 내역 목록
    func fetchTransactions(subCategoryId: UUID) async throws -> [TransactionDTO]
    
    /// 특정 결제수단의 거래 내역 조회
    /// - Parameter paymentMethodId: 결제수단 ID
    /// - Returns: 해당 결제수단의 거래 내역 목록
    func fetchTransactions(paymentMethodId: UUID) async throws -> [TransactionDTO]
    
    /// 특정 거래 유형의 거래 내역 조회
    /// - Parameter type: 거래 유형 (수입/고정지출/변동지출)
    /// - Returns: 해당 유형의 거래 내역 목록
    func fetchTransactionsByType(_ type: TransactionType) async throws -> [TransactionDTO]
    
    /// 즐겨찾기 거래 내역 조회 (빠른 입력용)
    /// - Returns: 즐겨찾기로 설정된 거래 내역 목록
    func fetchFavoriteTransactions() async throws -> [TransactionDTO]
    
    /// 거래 내역 검색 (메모 기반)
    /// - Parameter keyword: 검색 키워드
    /// - Returns: 메모에 키워드가 포함된 거래 내역 목록
    func searchTransactions(keyword: String) async throws -> [TransactionDTO]
    
    // MARK: - 집계 및 통계 (Aggregation & Statistics)
    
    /// 특정 기간의 거래 유형별 합계
    /// - Parameters:
    ///   - startDate: 시작 날짜
    ///   - endDate: 종료 날짜
    /// - Returns: 거래 유형별 금액 합계 목록 (정렬 가능)
    func getTotalAmountByType(from startDate: Date, to endDate: Date) async throws -> [(TransactionType, Decimal)]
    
    /// 특정 기간의 서브카테고리별 합계
    /// - Parameters:
    ///   - startDate: 시작 날짜
    ///   - endDate: 종료 날짜
    /// - Returns: 서브카테고리별 금액 합계 목록
    func getTotalAmountBySubCategory(from startDate: Date, to endDate: Date) async throws -> [(SubCategoryDTO, Decimal)]
    
    /// 특정 기간의 일별 합계 (차트용)
    /// - Parameters:
    ///   - startDate: 시작 날짜
    ///   - endDate: 종료 날짜
    ///   - type: 거래 유형 (nil이면 전체)
    /// - Returns: 일별 금액 합계 목록
    func getDailyTotals(from startDate: Date, to endDate: Date, type: TransactionType?) async throws -> [(Date, Decimal)]
    
    // MARK: - 생성/수정 (Create/Update Operations)
    
    /// 새 거래 생성
    /// - Parameter transaction: 생성할 거래 정보
    /// - Throws: 존재하지 않는 서브카테고리/결제수단, 유효하지 않은 데이터 등의 에러
    func insertTransaction(_ transaction: TransactionDTO) async throws
    
    /// 거래 정보 수정
    /// - Parameter transaction: 수정할 거래 정보
    /// - Throws: 존재하지 않는 거래, 유효하지 않은 데이터 등의 에러
    func updateTransaction(_ transaction: TransactionDTO) async throws
    
    /// 거래 즐겨찾기 토글
    /// - Parameter id: 거래 ID
    /// - Throws: 존재하지 않는 거래 등의 에러
    func toggleFavorite(id: UUID) async throws
    
    // MARK: - 삭제 관련 (Delete Operations)
    
    /// 거래 삭제
    /// - Parameter id: 삭제할 거래 ID
    /// - Note: 거래는 즉시 삭제됨 (활성/비활성 단계 없음)
    func deleteTransaction(id: UUID) async throws
    
    /// 여러 거래 일괄 삭제
    /// - Parameter ids: 삭제할 거래 ID 목록
    func deleteTransactions(ids: [UUID]) async throws
    
    // MARK: - 검증 (Validation)
    
    /// 서브카테고리 존재 여부 확인 (거래 입력 시 검증)
    /// - Parameter subCategoryId: 서브카테고리 ID
    /// - Returns: 존재하고 활성 상태이면 true
    func validateSubCategoryExists(id: UUID) async throws -> Bool
    
    /// 결제수단 존재 여부 확인 (거래 입력 시 검증)
    /// - Parameter paymentMethodId: 결제수단 ID
    /// - Returns: 존재하고 활성 상태이면 true
    func validatePaymentMethodExists(id: UUID) async throws -> Bool
}

