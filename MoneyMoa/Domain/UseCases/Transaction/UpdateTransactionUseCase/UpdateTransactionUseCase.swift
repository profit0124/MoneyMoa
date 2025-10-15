//
//  UpdateTransactionUseCase.swift
//  MoneyMoa
//
//  Created by profit on 8/20/25.
//

import Foundation

public protocol UpdateTransactionUseCase {
    /// 기존 거래내역을 수정합니다
    /// - Parameters:
    ///   - transaction: 수정할 거래내역 정보
    ///   - strategy: 연관된 템플릿의 업데이트 전략 (기본값: .none)
    /// - Throws: 데이터 검증 실패, 수정 실패 등의 에러
    func execute(
        _ transaction: TransactionDTO,
        strategy: TemplateUpdateStrategy
    ) async throws
}
