//
//  GetAllPaymentMethodsUseCase.swift
//  MoneyMoa
//
//  Created by Claude on 10/26/25.
//

import Foundation

/// 모든 결제수단 조회 UseCase 프로토콜
public protocol GetAllPaymentMethodsUseCase: Sendable {
    /// 모든 결제수단을 조회합니다 (비활성 포함)
    /// - Returns: 전체 결제수단 목록 (orderIndex 순으로 정렬)
    func execute() async throws -> [PaymentMethodDTO]
}
