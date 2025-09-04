//
//  PaymentMethodRepository.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/28/25.
//

import Foundation

// MARK: - PaymentMethod Reader Protocol

public protocol PaymentMethodReader: Sendable {
    
    // MARK: - 조회 (Fetch Operations)
    
    /// 모든 결제수단 조회 (비활성 포함)
    /// - Returns: 전체 결제수단 목록 (orderIndex 순으로 정렬)
    func fetchPaymentMethods() async throws -> [PaymentMethodDTO]
    
    /// 특정 결제수단 조회
    /// - Parameter id: 결제수단 ID
    /// - Returns: 해당 결제수단 또는 nil
    func fetchPaymentMethod(id: UUID) async throws -> PaymentMethodDTO?
    
    /// 활성 결제수단만 조회 (거래 입력 시 사용)
    /// - Returns: 활성 상태인 결제수단 목록
    func fetchActivePaymentMethods() async throws -> [PaymentMethodDTO]
    
    /// 특정 결제수단 종류의 결제수단 조회
    /// - Parameter kind: 결제수단 종류 (현금/이체/신용카드/체크카드)
    /// - Returns: 해당 종류의 활성 결제수단 목록
    func fetchPaymentMethodsByKind(_ kind: PaymentMethodKind) async throws -> [PaymentMethodDTO]
    
    // MARK: - 검증 (Validation)
    
    /// 결제수단명 중복 확인 (같은 종류 내에서)
    /// - Parameters:
    ///   - name: 확인할 결제수단명
    ///   - kind: 결제수단 종류 (같은 종류 내에서만 중복 확인)
    ///   - excludingId: 제외할 ID (수정 시 자기 자신 제외)
    /// - Returns: 사용 가능하면 true
    /// - Note: 같은 이름이라도 종류가 다르면 허용 (예: "국민은행" 신용카드 + "국민은행" 체크카드)
    func validatePaymentMethodName(_ name: String, kind: PaymentMethodKind, excludingId: UUID?) async throws -> Bool
    
    /// 결제수단에 거래 내역 존재 여부 확인
    /// - Parameter id: 확인할 결제수단 ID
    /// - Returns: 거래 내역이 있으면 true
    func hasTransactions(paymentMethodId: UUID) async throws -> Bool
    
    // MARK: - 통계 (Statistics)
    
    /// 결제수단별 사용 횟수 조회 (최근 사용한 순서로 정렬)
    /// - Parameter limit: 조회할 개수 제한 (기본값: 10)
    /// - Returns: 결제수단별 사용 횟수 정보
    func fetchPaymentMethodUsageStats(limit: Int) async throws -> [(paymentMethod: PaymentMethodDTO, usageCount: Int)]
    
    /// 특정 기간 내 결제수단별 거래 금액 합계
    /// - Parameters:
    ///   - startDate: 시작일
    ///   - endDate: 종료일
    /// - Returns: 결제수단별 거래 금액 합계
    func fetchPaymentMethodAmountSummary(startDate: Date, endDate: Date) async throws -> [(paymentMethod: PaymentMethodDTO, totalAmount: Decimal)]
}

// MARK: - PaymentMethod Writer Protocol

public protocol PaymentMethodWriter: Sendable {
    
    // MARK: - 생성/수정 (Create/Update Operations)
    
    /// 새 결제수단 생성
    /// - Parameter paymentMethod: 생성할 결제수단 정보
    /// - Throws: 중복 이름, 유효하지 않은 데이터 등의 에러
    func insertPaymentMethod(_ paymentMethod: PaymentMethodDTO) async throws
    
    /// 결제수단 정보 수정
    /// - Parameter paymentMethod: 수정할 결제수단 정보
    /// - Throws: 존재하지 않는 결제수단, 중복 이름 등의 에러
    func updatePaymentMethod(_ paymentMethod: PaymentMethodDTO) async throws
    
    /// 결제수단 순서 변경
    /// - Parameter paymentMethods: 새로운 순서의 결제수단 목록
    /// - Note: orderIndex를 기준으로 순서를 업데이트
    func updatePaymentMethodOrder(_ paymentMethods: [PaymentMethodDTO]) async throws
    
    // MARK: - 활성/비활성 관리 (Activation Management)
    
    /// 결제수단 비활성화 (1단계: 활성 → 비활성)
    /// - Parameter id: 비활성화할 결제수단 ID
    /// - Note: 비활성화된 결제수단은 거래 입력 시 선택할 수 없지만 기존 거래의 데이터는 보존됨
    func deactivatePaymentMethod(id: UUID) async throws
    
    /// 결제수단 활성화 (비활성 → 활성 복구)
    /// - Parameter id: 활성화할 결제수단 ID
    func activatePaymentMethod(id: UUID) async throws
    
    // MARK: - 삭제 관련 (Delete Operations)
    
    /// 결제수단 완전 삭제 (2단계: 비활성 → 삭제)
    /// - Parameter id: 삭제할 결제수단 ID
    /// - Warning: 비활성 상태인 결제수단만 삭제 가능. 해당 결제수단을 사용한 거래가 있으면 삭제 불가
    /// - Throws: 활성 상태 결제수단 삭제 시도 시 에러, 거래 내역이 있을 때 에러
    func deletePaymentMethod(id: UUID) async throws
}

// MARK: - PaymentMethod Repository Protocol

/// PaymentMethodReader와 PaymentMethodWriter를 결합한 통합 프로토콜
public typealias PaymentMethodRepository = PaymentMethodReader & PaymentMethodWriter
