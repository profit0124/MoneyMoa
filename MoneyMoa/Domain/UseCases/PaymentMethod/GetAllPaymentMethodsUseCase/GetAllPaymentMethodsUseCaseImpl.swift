//
//  GetAllPaymentMethodsUseCaseImpl.swift
//  MoneyMoa
//
//  Created by Claude on 10/26/25.
//

import Foundation

/// 모든 결제수단 조회 UseCase 구현체
public struct GetAllPaymentMethodsUseCaseImpl: GetAllPaymentMethodsUseCase {
    private let repository: PaymentMethodRepository

    public init(repository: PaymentMethodRepository) {
        self.repository = repository
    }

    public func execute() async throws -> [PaymentMethodDTO] {
        return try await repository.fetchPaymentMethods()
    }
}
