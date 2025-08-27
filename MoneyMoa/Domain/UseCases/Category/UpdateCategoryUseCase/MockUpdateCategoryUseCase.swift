//
//  MockUpdateCategoryUseCase.swift
//  MoneyMoa
//
//  Created by Claude on 8/26/25.
//

import Foundation

#if DEBUG
final class MockUpdateCategoryUseCase: UpdateCategoryUseCase {
    var shouldFail = false
    var shouldFailWithNotFound = false
    var shouldFailWithDuplicateName = false
    var updatedCategories: [CategoryDTO] = []
    
    func execute(_ category: CategoryDTO) async throws {
        if shouldFailWithNotFound {
            throw CategoryUpdateError.categoryNotFound
        }
        
        if shouldFailWithDuplicateName {
            throw CategoryUpdateError.duplicateName
        }
        
        if shouldFail {
            throw CategoryUpdateError.invalidData
        }
        
        // Mock에서도 동일한 비즈니스 로직 검증
        let trimmedName = category.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw CategoryUpdateError.emptyName
        }
        
        guard !category.iconName.isEmpty else {
            throw CategoryUpdateError.emptyIconName
        }
        
        // 성공 시 업데이트된 카테고리 저장
        updatedCategories.append(category)
        print("Mock: Updated category - \(category.name) (\(category.transactionType.displayName))")
    }
    
    func reset() {
        shouldFail = false
        shouldFailWithNotFound = false
        shouldFailWithDuplicateName = false
        updatedCategories.removeAll()
    }
}
#endif
