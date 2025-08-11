//
//  GetActivePaymentMethodsUseCaseImpl.swift
//  MoneyMoa
//
//  Created by profit on 8/11/25.
//

import Foundation

final class GetActivePaymentMethodsUseCaseImpl: GetActivePaymentMethodsUseCase {
    private let paymentMethodRepository: PaymentMethodRepository
    
    init(paymentMethodRepository: PaymentMethodRepository) {
        self.paymentMethodRepository = paymentMethodRepository
    }
    
    func execute() async throws -> [PaymentMethodDTO] {
        return try await paymentMethodRepository.fetchActivePaymentMethods()
    }
}