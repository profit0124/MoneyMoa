//
//  CreateSubCategoryUseCaseImpl.swift
//  MoneyMoa
//
//  Created by profit on 8/11/25.
//

import Foundation

final class CreateSubCategoryUseCaseImpl: CreateSubCategoryUseCase {
    private let subCategoryRepository: SubCategoryRepository
    
    init(subCategoryRepository: SubCategoryRepository) {
        self.subCategoryRepository = subCategoryRepository
    }
    
    func execute(_ subCategory: SubCategoryDTO) async throws {
        // 비즈니스 로직 검증: 이름 유효성 검사
        guard !subCategory.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SubCategoryCreationError.emptyName
        }
        
        // 이름 중복 검증 (Repository의 검증 기능 활용)
        let isNameValid = try await subCategoryRepository.validateSubCategoryName(
            subCategory.name,
            categoryId: subCategory.categoryId,
            excludingId: nil
        )
        guard isNameValid else {
            throw SubCategoryCreationError.duplicateName
        }
        
        // 서브카테고리 저장 (Repository에서 상위 카테고리 존재 검증 수행)
        try await subCategoryRepository.insertSubCategory(subCategory)
    }
}

// MARK: - Error Types

enum SubCategoryCreationError: Error {
    case emptyName
    case duplicateName
    // Repository에서 RepositoryError.categoryNotFound 던짐 (상위 카테고리 존재 검증)
}