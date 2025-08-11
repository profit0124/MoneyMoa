//
//  MockGetCategoriesWithSubCategoriesByTypeUseCase.swift
//  MoneyMoa
//
//  Created by profit on 8/11/25.
//

import Foundation

#if DEBUG
final class MockGetCategoriesWithSubCategoriesByTypeUseCase: GetCategoriesWithSubCategoriesByTypeUseCase {
    var shouldFail = false
    
    func execute(_ type: TransactionType) async throws -> [CategoryDTO] {
        if shouldFail {
            throw NSError(domain: "MockError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        
        switch type {
        case .income:
            return [
                CategoryDTO(
                    id: CategoryDTO.mockIncome.id,
                    name: CategoryDTO.mockIncome.name,
                    iconName: CategoryDTO.mockIncome.iconName,
                    transactionType: .income,
                    subCategories: [.mockIncomeAllowance, .mockSalary]
                )
            ]
        case .variableExpense:
            return [
                CategoryDTO(
                    id: CategoryDTO.mockFood.id,
                    name: CategoryDTO.mockFood.name,
                    iconName: CategoryDTO.mockFood.iconName,
                    transactionType: .variableExpense,
                    subCategories: [.mockFoodExpense]
                ),
                CategoryDTO(
                    id: CategoryDTO.mockTransport.id,
                    name: CategoryDTO.mockTransport.name,
                    iconName: CategoryDTO.mockTransport.iconName,
                    transactionType: .variableExpense,
                    subCategories: [.mockTransportBus]
                )
            ]
        case .fixedExpense:
            return [
                CategoryDTO(
                    id: CategoryDTO.mockRent.id,
                    name: CategoryDTO.mockRent.name,
                    iconName: CategoryDTO.mockRent.iconName,
                    transactionType: .fixedExpense,
                    subCategories: []
                )
            ]
        }
    }
}
#endif