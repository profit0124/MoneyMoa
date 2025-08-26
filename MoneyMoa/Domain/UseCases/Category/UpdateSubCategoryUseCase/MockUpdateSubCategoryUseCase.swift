//
//  MockUpdateSubCategoryUseCase.swift
//  MoneyMoa
//
//  Created by Claude on 8/25/25.
//

import Foundation

#if DEBUG
final class MockUpdateSubCategoryUseCase: UpdateSubCategoryUseCase {
    var shouldFail = false
    var shouldFailWithNotFound = false
    var shouldFailWithDuplicateName = false
    var updatedSubCategories: [SubCategoryDTO] = []
    
    func execute(_ subCategory: SubCategoryDTO) async throws {
        if shouldFailWithNotFound {
            throw SubCategoryUpdateError.subCategoryNotFound
        }
        
        if shouldFailWithDuplicateName {
            throw SubCategoryUpdateError.duplicateName
        }
        
        if shouldFail {
            throw SubCategoryUpdateError.invalidData
        }
        
        // Mock에서도 동일한 비즈니스 로직 검증
        let trimmedName = subCategory.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw SubCategoryUpdateError.emptyName
        }
        
        // 성공 시 업데이트된 서브카테고리 저장
        updatedSubCategories.append(subCategory)
        print("Mock: Updated subCategory - \(subCategory.name) in category \(subCategory.categoryName)")
    }
    
    func reset() {
        shouldFail = false
        shouldFailWithNotFound = false
        shouldFailWithDuplicateName = false
        updatedSubCategories.removeAll()
    }
}
#endif
