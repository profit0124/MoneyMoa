//
//  MockCreateCategoryUseCase.swift
//  MoneyMoa
//
//  Created by profit on 8/11/25.
//

import Foundation

#if DEBUG
final class MockCreateCategoryUseCase: CreateCategoryUseCase {
    var shouldFail = false
    var createdCategories: [CategoryDTO] = []
    var createdSubCategories: [SubCategoryDTO] = []
    
    func execute(_ category: CategoryDTO) async throws {
        if shouldFail {
            throw CategoryCreationError.duplicateName
        }
        
        // Mock에서도 동일한 비즈니스 로직 검증
        guard !category.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CategoryCreationError.emptyName
        }
        
        for subCategory in category.subCategories {
            guard !subCategory.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw CategoryCreationError.emptySubCategoryName
            }
            createdSubCategories.append(subCategory)
        }
        
        createdCategories.append(category)
    }
    
    func reset() {
        shouldFail = false
        createdCategories.removeAll()
        createdSubCategories.removeAll()
    }
}
#endif