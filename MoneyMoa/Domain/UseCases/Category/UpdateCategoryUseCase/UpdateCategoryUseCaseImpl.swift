//
//  UpdateCategoryUseCaseImpl.swift
//  MoneyMoa
//
//  Created by Claude on 8/26/25.
//

import Foundation

final class UpdateCategoryUseCaseImpl: UpdateCategoryUseCase {
    private let categoryRepository: CategoryRepository
    
    init(categoryRepository: CategoryRepository) {
        self.categoryRepository = categoryRepository
    }
    
    func execute(_ category: CategoryDTO) async throws {
        // 비즈니스 로직 검증: 카테고리명 유효성 검사
        let trimmedName = category.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw CategoryUpdateError.emptyName
        }
        
        // 아이콘명 유효성 검사
        guard !category.iconName.isEmpty else {
            throw CategoryUpdateError.emptyIconName
        }
        
        // 같은 거래 유형 내에서 이름 중복 검사 (자기 자신 제외)
        let isNameValid = try await categoryRepository.validateCategoryName(
            trimmedName,
            type: category.transactionType,
            excludingId: category.id
        )
        
        guard isNameValid else {
            throw CategoryUpdateError.duplicateName
        }
        
        // 카테고리 수정 (Repository에서 추가 검증 수행)
        let updatedCategory = CategoryDTO(
            id: category.id,
            name: trimmedName,
            iconName: category.iconName,
            transactionType: category.transactionType,
            isActive: category.isActive,
            orderIndex: category.orderIndex,
            subCategories: category.subCategories
        )
        
        try await categoryRepository.updateCategory(updatedCategory)
    }
}

// MARK: - Error Types

enum CategoryUpdateError: Error {
    case emptyName
    case emptyIconName
    case duplicateName
    case categoryNotFound
    case invalidData
}

extension CategoryUpdateError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "카테고리명을 입력해주세요."
        case .emptyIconName:
            return "아이콘을 선택해주세요."
        case .duplicateName:
            return "같은 거래 유형에 이미 존재하는 카테고리명입니다."
        case .categoryNotFound:
            return "수정할 카테고리를 찾을 수 없습니다."
        case .invalidData:
            return "유효하지 않은 데이터입니다."
        }
    }
}
