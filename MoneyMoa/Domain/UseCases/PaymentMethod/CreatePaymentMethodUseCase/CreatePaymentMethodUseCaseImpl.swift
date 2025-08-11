//
//  CreatePaymentMethodUseCaseImpl.swift
//  MoneyMoa
//
//  Created by profit on 8/11/25.
//

import Foundation

final class CreatePaymentMethodUseCaseImpl: CreatePaymentMethodUseCase {
    private let paymentMethodRepository: PaymentMethodRepository
    
    init(paymentMethodRepository: PaymentMethodRepository) {
        self.paymentMethodRepository = paymentMethodRepository
    }
    
    func execute(_ paymentMethod: PaymentMethodDTO) async throws {
        // 결제수단명 유효성 검사
        guard !paymentMethod.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PaymentMethodCreationError.emptyName
        }
        
        // 중복 이름 검증
        let isNameValid = try await paymentMethodRepository.validatePaymentMethodName(
            paymentMethod.name,
            kind: paymentMethod.kind,
            excludingId: nil
        )
        guard isNameValid else {
            throw PaymentMethodCreationError.duplicateName
        }
        
        // 결제수단 저장
        try await paymentMethodRepository.insertPaymentMethod(paymentMethod)
    }
}

// MARK: - Error Types

enum PaymentMethodCreationError: Error {
    case emptyName
    case duplicateName
}