import Foundation
@testable import MoneyMoa

@MainActor
final class StubGetActivePaymentMethodsUseCase: GetActivePaymentMethodsUseCase {
    var result: [PaymentMethodDTO]

    init(result: [PaymentMethodDTO] = []) {
        self.result = result
    }

    func execute() async throws -> [PaymentMethodDTO] {
        result
    }
}
