//
//  DeletePaymentMethodUseCase.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 10/20/25.
//

import Foundation

public protocol DeletePaymentMethodUseCase {
    /// 결제수단을 삭제합니다
    /// - Parameter id: 삭제할 결제수단 ID
    /// - Note: Transaction이 있으면 soft delete, 없으면 hard delete
    /// - Throws: 결제수단을 찾을 수 없거나 TransactionTemplate이 있는 경우 등의 에러
    func execute(_ id: UUID) async throws
}
