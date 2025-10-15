//
//  TransactionTemplateRepository.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/15/25.
//

import Foundation

// MARK: - TransactionTemplate Repository Interfaces

/// 거래 템플릿 조회 전용 프로토콜 (읽기 작업)
public protocol TransactionTemplateReader {

    // MARK: - 기본 조회

    /// 특정 거래 템플릿 조회
    /// - Parameter id: 템플릿 ID
    /// - Returns: 해당 템플릿 또는 nil
    func fetchTemplate(id: UUID) async throws -> TransactionTemplateDTO?

    /// 모든 거래 템플릿 조회
    /// - Returns: 모든 템플릿 목록
    func fetchAllTemplates() async throws -> [TransactionTemplateDTO]

    /// 다음 처리 예정인 템플릿 조회 (반복 거래 자동 생성용)
    /// - Parameter date: 기준 날짜
    /// - Returns: nextDueDate가 기준 날짜 이전인 템플릿 목록
    func fetchTemplatesDueForProcessing(before date: Date) async throws -> [TransactionTemplateDTO]

    /// 반복 주기에 따른 템플릿 조회 
    /// - Parameter period: none, weekly 등 반복주기
    /// - Returns: nextDueDate가 기준 날짜 이전인 템플릿 목록
    func fetchTemplatesByRecurrencePeriod(_ period: RecurrencePeriod) async throws -> [TransactionTemplateDTO]
}

/// 거래 템플릿 변경 전용 프로토콜 (쓰기 작업)
public protocol TransactionTemplateWriter {

    // MARK: - 생성/수정

    /// 새 거래 템플릿 생성
    /// - Parameter template: 생성할 템플릿 정보
    /// - Throws: 존재하지 않는 서브카테고리/결제수단, 유효하지 않은 데이터 등의 에러
    func insertTemplate(_ template: TransactionTemplateDTO, shouldSave: Bool) async throws

    /// 거래 템플릿 정보 수정
    /// - Parameter template: 수정할 템플릿 정보
    /// - Throws: 존재하지 않는 템플릿, 유효하지 않은 데이터 등의 에러
    func updateTemplate(_ template: TransactionTemplateDTO) async throws

    /// 템플릿 처리 상태 업데이트 (실행 상태, 마지막 추가 시점 등)
    /// - Parameters:
    ///   - id: 템플릿 ID
    ///   - executionState: 템플릿 실행 상태
    ///   - lastAddedAt: 마지막 처리 시점
    ///   - nextDueDate: 다음 예정일
    func updateTemplateProcessing(
        id: UUID,
        executionState: TemplateExecutionState,
        lastAddedAt: Date,
        nextDueDate: Date?
    ) async throws

    // MARK: - 삭제

    /// 거래 템플릿 삭제
    /// - Parameter id: 삭제할 템플릿 ID
    /// - Note: 템플릿 삭제 시 연결된 거래는 유지됨 (nullify)
    func deleteTemplate(id: UUID) async throws

}

/// 통합 거래 템플릿 저장소 프로토콜 (읽기 + 쓰기)
public typealias TransactionTemplateRepository = TransactionTemplateReader & TransactionTemplateWriter
