//
//  GetActivePaymentMethodsUseCaseImpl.swift
//  MoneyMoa
//
//  Created by profit on 8/11/25.
//

import Foundation

final class GetActivePaymentMethodsUseCaseImpl: GetActivePaymentMethodsUseCase {
    private let paymentMethodReader: PaymentMethodReader
    
    init(paymentMethodRepository: PaymentMethodRepository) {
        self.paymentMethodReader = paymentMethodRepository
    }
    
    func execute() async throws -> [PaymentMethodDTO] {
        return try await paymentMethodReader.fetchActivePaymentMethods()
    }
}
