//
//  CreateTransactionUseCase.swift
//  MoneyMoa
//
//  Created by profit on 8/11/25.
//

import Foundation

// MARK: - Use Case Protocol

public protocol CreateTransactionUseCase {
    /// 새로운 거래내역을 생성합니다
    /// - Parameters:
    ///   - transaction: 생성할 거래내역 정보
    ///   - templateConfig: 템플릿 생성 설정 (nil이면 템플릿 생성하지 않음)
    /// - Throws: 데이터 검증 실패, 저장 실패 등의 에러
    func execute(_ transaction: TransactionDTO, with recurrencePeriod: RecurrencePeriod?) async throws
}
