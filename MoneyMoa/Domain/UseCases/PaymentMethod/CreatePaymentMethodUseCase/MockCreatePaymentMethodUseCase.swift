//
//  MockCreatePaymentMethodUseCase.swift
//  MoneyMoa
//
//  Created by profit on 8/11/25.
//

import Foundation

#if DEBUG
final class MockCreatePaymentMethodUseCase: CreatePaymentMethodUseCase {
    var shouldFail = false
    var createdPaymentMethods: [PaymentMethodDTO] = []
    
    func execute(_ paymentMethod: PaymentMethodDTO) async throws {
        if shouldFail {
            throw PaymentMethodCreationError.duplicateName
        }
        
        createdPaymentMethods.append(paymentMethod)
    }
    
    func reset() {
        shouldFail = false
        createdPaymentMethods.removeAll()
    }
}
#endif
