//
//  CreateTransactionUseCase.swift
//  MoneyMoa
//
//  Created by profit on 8/11/25.
//

import Foundation

public protocol CreateTransactionUseCase {
    /// 새로운 거래내역을 생성합니다
    /// - Parameter transaction: 생성할 거래내역 정보
    /// - Throws: 데이터 검증 실패, 저장 실패 등의 에러
    func execute(_ transaction: TransactionDTO) async throws
}
