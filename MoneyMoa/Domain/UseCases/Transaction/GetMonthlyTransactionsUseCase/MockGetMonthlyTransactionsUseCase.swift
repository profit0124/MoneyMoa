//
//  MockGetMonthlyTransactionsUseCase.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/30/25.
//

import Foundation

// MARK: - Mock UseCase for Preview and Testing

public class MockGetMonthlyTransactionsUseCase: GetMonthlyTransactionsUseCase {
    public init() {}
    
    public func execute(yearMonth: YearMonth) async throws -> [TransactionDTO] {
        // Mock data for preview and testing
        return TransactionDTO.mockDatas
    }
}
