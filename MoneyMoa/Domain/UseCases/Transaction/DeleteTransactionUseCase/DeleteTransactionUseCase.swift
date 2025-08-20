//
//  DeleteTransactionUseCase.swift
//  MoneyMoa
//
//  Created by profit on 8/20/25.
//

import Foundation

public protocol DeleteTransactionUseCase {
    /// 거래내역을 삭제합니다
    /// - Parameter transactionId: 삭제할 거래 ID
    /// - Throws: 존재하지 않는 거래, 삭제 실패 등의 에러
    func execute(transactionId: UUID) async throws
}
