//
//  MockCreateSubCategoryUseCase.swift
//  MoneyMoa
//
//  Created by profit on 8/11/25.
//

import Foundation

#if DEBUG
final class MockCreateSubCategoryUseCase: CreateSubCategoryUseCase {
    var shouldFail = false
    var createdSubCategories: [SubCategoryDTO] = []
    
    func execute(_ subCategory: SubCategoryDTO) async throws {
        if shouldFail {
            throw SubCategoryCreationError.duplicateName
        }
        
        createdSubCategories.append(subCategory)
    }
    
    func reset() {
        shouldFail = false
        createdSubCategories.removeAll()
    }
}
#endif