//
//  MockGetFavoriteTransactionsUseCase.swift
//  MoneyMoa
//
//  Created by profit on 8/11/25.
//

import Foundation

#if DEBUG
final class MockGetFavoriteTransactionsUseCase: GetFavoriteTransactionsUseCase {
    var shouldFail = false
    
    func execute() async throws -> [TransactionDTO] {
        if shouldFail {
            throw NSError(domain: "MockError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        
        return [
            TransactionDTO(
                amount: 15000,
                place: "맥도날드",
                memo: "점심식사",
                transactionType: .variableExpense,
                isFavorite: true,
                subCategory: .mockFoodExpense,
                paymentMethod: .mockCreditCard
            ),
            TransactionDTO(
                amount: 50000,
                place: "부모님",
                memo: "용돈",
                transactionType: .income,
                isFavorite: true,
                subCategory: .mockIncomeAllowance,
                paymentMethod: .mockCash
            )
        ]
    }
}
#endif
