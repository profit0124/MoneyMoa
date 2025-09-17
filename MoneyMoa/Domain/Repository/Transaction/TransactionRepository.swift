//
//  TransactionRepository.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/27/25.
//

import Foundation

// MARK: - Transaction Repository Interfaces

/// 거래 조회 전용 프로토콜 (읽기 작업)
public protocol TransactionReader {
    
    // MARK: - 기본 조회
    
    /// 특정 거래 조회
    /// - Parameter id: 거래 ID
    /// - Returns: 해당 거래 또는 nil
    func fetchTransaction(id: UUID) async throws -> TransactionDTO?
    
    /// 특정 월의 거래 내역 조회 (월별 보기)
    /// - Parameter yearMonth: 조회할 년월
    /// - Returns: 해당 월의 거래 내역 목록
    func fetchTransactions(for yearMonth: YearMonth) async throws -> [TransactionDTO]
    
    /// 특정 기간의 거래 내역 조회 (기간별 조회)
    /// - Parameters:
    ///   - startDate: 시작 날짜
    ///   - endDate: 종료 날짜
    /// - Returns: 해당 기간의 거래 내역 목록
    func fetchTransactions(from startDate: Date, to endDate: Date) async throws -> [TransactionDTO]
    
    /// 즐겨찾기 거래 내역 조회 (빠른 입력용)
    /// - Returns: 즐겨찾기로 설정된 거래 내역 목록
    func fetchFavoriteTransactions() async throws -> [TransactionDTO]
    
    // MARK: - 통계 집계 (Adapter 지원)
    
    /// 특정 기간의 거래 유형별 합계 (통계용)
    /// - Parameters:
    ///   - startDate: 시작 날짜
    ///   - endDate: 종료 날짜
    /// - Returns: 거래 유형별 금액 합계 목록
    func getTotalAmountByType(from startDate: Date, to endDate: Date) async throws -> [(TransactionType, Decimal)]
    
    /// 특정 기간의 서브카테고리별 합계 (통계용)
    /// - Parameters:
    ///   - startDate: 시작 날짜
    ///   - endDate: 종료 날짜
    /// - Returns: 서브카테고리별 금액 합계 목록
    func getTotalAmountBySubCategory(from startDate: Date, to endDate: Date) async throws -> [(SubCategoryDTO, Decimal)]
}

/// 거래 변경 전용 프로토콜 (쓰기 작업)
public protocol TransactionWriter {
    
    // MARK: - 생성/수정
    
    /// 새 거래 생성
    /// - Parameter transaction: 생성할 거래 정보
    /// - Throws: 존재하지 않는 서브카테고리/결제수단, 유효하지 않은 데이터 등의 에러
    func insertTransaction(_ transaction: TransactionDTO, shouldSave: Bool) async throws

//    /// 새 거래 생성
//    /// - Parameter transaction: 생성할 거래 정보
//    ///
//    /// - Throws: 존재하지 않는 서브카테고리/결제수단, 유효하지 않은 데이터 등의 에러
//    func insertTransactionWithTemplate(_ transaction: TransactionDTO, with recurrencePeriod: RecurrencePeriod) async throws

    /// 거래 정보 수정
    /// - Parameter transaction: 수정할 거래 정보
    /// - Throws: 존재하지 않는 거래, 유효하지 않은 데이터 등의 에러
    func updateTransaction(_ transaction: TransactionDTO) async throws
    
    // MARK: - 삭제
    
    /// 거래 삭제
    /// - Parameter id: 삭제할 거래 ID
    /// - Note: 거래는 즉시 삭제됨 (활성/비활성 단계 없음)
    func deleteTransaction(id: UUID) async throws
}

/// 통합 거래 저장소 프로토콜 (읽기 + 쓰기)
public typealias TransactionRepository = TransactionReader & TransactionWriter

// MARK: - Legacy Protocol (호환성 유지)

/// 기존 인터페이스 (단계적 제거 예정)
@available(*, deprecated, message: "Use TransactionReader/TransactionWriter instead")
public protocol LegacyTransactionRepository {
    
    // MARK: - 조회 (Fetch Operations)
    
    // 기존 메서드들... (호환성을 위해 유지하되 새 코드에서는 사용 금지)
    func fetchTransaction(id: UUID) async throws -> TransactionDTO?
    func fetchTransactions(for yearMonth: YearMonth) async throws -> [TransactionDTO]
    func fetchTransactions(from startDate: Date, to endDate: Date) async throws -> [TransactionDTO]
    func fetchFavoriteTransactions() async throws -> [TransactionDTO]
    func getTotalAmountByType(for yearMonth: YearMonth) async throws -> [(TransactionType, Decimal)]
    func getTotalAmountBySubCategory(for yearMonth: YearMonth) async throws -> [(SubCategoryDTO, Decimal)]
    func insertTransaction(_ transaction: TransactionDTO) async throws
    func updateTransaction(_ transaction: TransactionDTO) async throws
    func deleteTransaction(id: UUID) async throws
}
