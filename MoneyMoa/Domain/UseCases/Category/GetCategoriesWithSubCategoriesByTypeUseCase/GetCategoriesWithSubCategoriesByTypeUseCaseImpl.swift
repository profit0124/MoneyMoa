//
//  GetCategoriesWithSubCategoriesByTypeUseCaseImpl.swift
//  MoneyMoa
//
//  Created by profit on 8/11/25.
//

import Foundation

final class GetCategoriesWithSubCategoriesByTypeUseCaseImpl: GetCategoriesWithSubCategoriesByTypeUseCase {
    private let categoryRepository: CategoryRepository
    private let subCategoryRepository: SubCategoryRepository
    
    init(
        categoryRepository: CategoryRepository,
        subCategoryRepository: SubCategoryRepository
    ) {
        self.categoryRepository = categoryRepository
        self.subCategoryRepository = subCategoryRepository
    }
    
    func execute(_ type: TransactionType) async throws -> [CategoryDTO] {
        // 특정 타입의 활성 카테고리들 조회
        let categories = try await categoryRepository.fetchCategoriesByType(type)
        
        // 각 카테고리의 서브카테고리들을 병렬로 조회
        let categoriesWithSubCategories = try await withThrowingTaskGroup(of: CategoryDTO.self) { group in
            for category in categories {
                group.addTask {
                    let subCategories = try await self.subCategoryRepository.fetchSubCategories(categoryId: category.id)
                    return CategoryDTO(
                        id: category.id,
                        name: category.name,
                        iconName: category.iconName,
                        transactionType: category.transactionType,
                        isActive: category.isActive,
                        orderIndex: category.orderIndex,
                        subCategories: subCategories
                    )
                }
            }
            
            var result: [CategoryDTO] = []
            for try await categoryWithSubCategories in group {
                result.append(categoryWithSubCategories)
            }
            return result.sorted()
        }
        
        return categoriesWithSubCategories
    }
}