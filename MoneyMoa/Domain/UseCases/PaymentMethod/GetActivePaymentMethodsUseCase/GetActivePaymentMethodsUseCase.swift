//
//  GetActivePaymentMethodsUseCase.swift
//  MoneyMoa
//
//  Created by profit on 8/11/25.
//

import Foundation

public protocol GetActivePaymentMethodsUseCase {
    /// 활성화된 모든 결제수단을 조회합니다
    /// - Returns: 활성화된 결제수단 목록 (정렬된 상태)
    func execute() async throws -> [PaymentMethodDTO]
}
