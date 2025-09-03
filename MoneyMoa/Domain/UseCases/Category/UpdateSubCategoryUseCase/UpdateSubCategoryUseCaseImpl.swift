//
//  UpdateSubCategoryUseCaseImpl.swift
//  MoneyMoa
//
//  Created by Claude on 8/25/25.
//

import Foundation

final class UpdateSubCategoryUseCaseImpl: UpdateSubCategoryUseCase {
    private let categoryRepository: CategoryRepository
    
    init(categoryRepository: CategoryRepository) {
        self.categoryRepository = categoryRepository
    }
    
    func execute(_ subCategory: SubCategoryDTO) async throws {
        // 비즈니스 로직 검증: 서브카테고리명 유효성 검사
        let trimmedName = subCategory.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw SubCategoryUpdateError.emptyName
        }
        
        // 같은 카테고리 내에서 이름 중복 검사
        let isNameValid = try await categoryRepository.validateSubCategoryName(
            trimmedName,
            categoryId: subCategory.categoryId,
            excludingId: subCategory.id
        )
        
        guard isNameValid else {
            throw SubCategoryUpdateError.duplicateName
        }
        
        // 서브카테고리 수정 (Repository에서 추가 검증 수행)
        try await categoryRepository.updateSubCategory(subCategory)
    }
}

// MARK: - Error Types

enum SubCategoryUpdateError: Error {
    case emptyName
    case duplicateName
    case subCategoryNotFound
    case categoryNotFound
    case invalidData
}

extension SubCategoryUpdateError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "서브카테고리명을 입력해주세요."
        case .duplicateName:
            return "같은 카테고리에 이미 존재하는 서브카테고리명입니다."
        case .subCategoryNotFound:
            return "수정할 서브카테고리를 찾을 수 없습니다."
        case .categoryNotFound:
            return "상위 카테고리를 찾을 수 없습니다."
        case .invalidData:
            return "유효하지 않은 데이터입니다."
        }
    }
}
