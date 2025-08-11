//
//  GetFavoriteTransactionsUseCase.swift
//  MoneyMoa
//
//  Created by profit on 8/11/25.
//

import Foundation

public protocol GetFavoriteTransactionsUseCase {
    /// 즐겨찾기로 설정된 거래내역들을 조회합니다
    /// - Returns: 즐겨찾기 거래내역 목록 (빠른 입력용)
    func execute() async throws -> [TransactionDTO]
}