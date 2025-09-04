//
//  CreateCategoryUseCaseImpl.swift
//  MoneyMoa
//
//  Created by profit on 8/11/25.
//

import Foundation

final class CreateCategoryUseCaseImpl: CreateCategoryUseCase {
    private let categoryRepository: CategoryRepository
    
    init(categoryRepository: CategoryRepository) {
        self.categoryRepository = categoryRepository
    }
    
    func execute(_ category: CategoryDTO) async throws {
        // 1. 카테고리명 유효성 검사
        guard !category.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CategoryCreationError.emptyName
        }
        
        // 2. 카테고리 중복 이름 검증
        let isNameValid = try await categoryRepository.validateCategoryName(
            category.name,
            type: category.transactionType,
            excludingId: nil
        )
        guard isNameValid else {
            throw CategoryCreationError.duplicateName
        }
        
        // 3. 입력된 서브카테고리 배열 내 중복 체크
        let subCategoryNames = category.subCategories.map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines) }
        let uniqueNames = Set(subCategoryNames)
        if subCategoryNames.count != uniqueNames.count {
            throw CategoryCreationError.duplicateSubCategoryName
        }
        
        // 4. 포함된 서브카테고리들 유효성 검사
        for subCategory in category.subCategories {
            guard !subCategory.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw CategoryCreationError.emptySubCategoryName
            }
            
            // 서브카테고리 중복 이름 검증 (동일 카테고리 내에서)
            let isSubCategoryNameValid = try await categoryRepository.validateSubCategoryName(
                subCategory.name,
                categoryId: category.id,
                excludingId: nil
            )
            guard isSubCategoryNameValid else {
                throw CategoryCreationError.duplicateSubCategoryName
            }
        }
        
        // 5. 카테고리 저장 (Repository에서 관계 데이터 검증)
        try await categoryRepository.insertCategory(category)
        
        // 6. 포함된 서브카테고리들 저장
        for subCategory in category.subCategories {
            try await categoryRepository.insertSubCategory(subCategory)
        }
    }
}

// MARK: - Error Types

enum CategoryCreationError: Error {
    case emptyName
    case duplicateName
    case emptySubCategoryName
    case duplicateSubCategoryName
}
