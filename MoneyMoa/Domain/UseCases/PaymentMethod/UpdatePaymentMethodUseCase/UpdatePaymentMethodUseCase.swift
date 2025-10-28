//
//  UpdatePaymentMethodUseCase.swift
//  MoneyMoa
//
//  Created by Claude on 10/26/25.
//

import Foundation

/// 결제수단 수정 UseCase 프로토콜
public protocol UpdatePaymentMethodUseCase: Sendable {
    /// 결제수단 정보를 수정합니다
    /// - Parameter paymentMethod: 수정할 결제수단 정보
    /// - Throws: Repository 에러 (존재하지 않는 결제수단, 중복 이름 등)
    func execute(_ paymentMethod: PaymentMethodDTO) async throws
}
