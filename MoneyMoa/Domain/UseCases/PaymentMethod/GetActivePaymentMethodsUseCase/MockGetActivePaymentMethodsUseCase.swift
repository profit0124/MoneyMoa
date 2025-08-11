//
//  MockGetActivePaymentMethodsUseCase.swift
//  MoneyMoa
//
//  Created by profit on 8/11/25.
//

import Foundation

#if DEBUG
final class MockGetActivePaymentMethodsUseCase: GetActivePaymentMethodsUseCase {
    var shouldFail = false
    
    func execute() async throws -> [PaymentMethodDTO] {
        if shouldFail {
            throw NSError(domain: "MockError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        
        return PaymentMethodDTO.mockStandards
    }
}
#endif