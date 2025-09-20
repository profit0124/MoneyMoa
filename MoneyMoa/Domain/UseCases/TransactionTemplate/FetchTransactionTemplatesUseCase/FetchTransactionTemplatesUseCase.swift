//
//  FetchTransactionTemplatesUseCase.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/18/25.
//

import Foundation

public protocol FetchTransactionTemplatesUseCase {
    /// 거래 템플릿을 조회합니다
    /// - Parameter period: 반복 주기 필터 (nil이면 모든 템플릿 조회)
    /// - Returns: 템플릿 배열 (생성일 내림차순 정렬)
    func execute(with period: RecurrencePeriod?) async throws -> [TransactionTemplateDTO]
}
