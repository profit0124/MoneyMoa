//
//  GetMonthlyTransactionsUseCase.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/30/25.
//

import Foundation

// MARK: - GetMonthlyTransactionsUseCase Protocol

public protocol GetMonthlyTransactionsUseCase {
    /// 특정 연월의 모든 거래 내역을 조회합니다
    /// - Parameter yearMonth: 조회할 연월
    /// - Returns: 해당 월의 거래 내역 배열 (날짜 내림차순 정렬)
    func execute(yearMonth: YearMonth) async throws -> [TransactionDTO]
}

