//
//  UpdatePaymentMethodUseCaseImpl.swift
//  MoneyMoa
//
//  Created by Claude on 10/26/25.
//

import Foundation

/// 결제수단 수정 UseCase 구현체
public struct UpdatePaymentMethodUseCaseImpl: UpdatePaymentMethodUseCase {
    private let repository: PaymentMethodRepository

    public init(repository: PaymentMethodRepository) {
        self.repository = repository
    }

    public func execute(_ paymentMethod: PaymentMethodDTO) async throws {
        // 결제수단명 유효성 검사
        guard !paymentMethod.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PaymentMethodUpdateError.emptyName
        }

        // 이름 유효성 검증 (같은 종류 내에서 중복 확인, 자기 자신 제외)
        let isValid = try await repository.validatePaymentMethodName(
            paymentMethod.name,
            kind: paymentMethod.kind,
            excludingId: paymentMethod.id
        )

        guard isValid else {
            throw PaymentMethodUpdateError.duplicateName
        }

        // 결제수단 업데이트
        try await repository.updatePaymentMethod(paymentMethod)
    }
}

// MARK: - Error Types

enum PaymentMethodUpdateError: Error {
    case emptyName
    case duplicateName
}
