//
//  DeletePaymentMethodUseCaseImpl.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 10/20/25.
//

import Foundation

final class DeletePaymentMethodUseCaseImpl: DeletePaymentMethodUseCase {
    private let paymentMethodRepository: PaymentMethodRepository

    init(paymentMethodRepository: PaymentMethodRepository) {
        self.paymentMethodRepository = paymentMethodRepository
    }

    func execute(_ id: UUID) async throws {
        // Repository에서 삭제 로직 처리 (Transaction 확인 후 soft/hard delete)
        try await paymentMethodRepository.deletePaymentMethod(id: id)
    }
}
