//
//  CreatePaymentMethodUseCase.swift
//  MoneyMoa
//
//  Created by profit on 8/11/25.
//

import Foundation

public protocol CreatePaymentMethodUseCase {
    /// 새로운 결제수단을 생성합니다
    /// - Parameter paymentMethod: 생성할 결제수단 정보
    /// - Throws: 중복 이름, 유효하지 않은 데이터 등의 에러
    func execute(_ paymentMethod: PaymentMethodDTO) async throws
}
