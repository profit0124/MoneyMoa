//
//  GetTransactionByIdUseCase.swift
//  MoneyMoa
//
//  Created by profit on 8/20/25.
//

import Foundation

public protocol GetTransactionByIdUseCase {
    /// ID로 특정 거래내역을 조회합니다
    /// - Parameter id: 조회할 거래내역 ID
    /// - Returns: 해당 거래내역 또는 nil
    /// - Throws: 데이터 조회 실패 등의 에러
    func execute(id: UUID) async throws -> TransactionDTO?
}
