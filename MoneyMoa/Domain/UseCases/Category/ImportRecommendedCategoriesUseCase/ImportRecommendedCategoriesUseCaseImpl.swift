//
//  ImportRecommendedCategoriesUseCaseImpl.swift
//  MoneyMoa
//
//  Created by Claude on 8/21/25.
//

import Foundation

// MARK: - ImportRecommendedCategoriesUseCaseImpl

public final class ImportRecommendedCategoriesUseCaseImpl: ImportRecommendedCategoriesUseCase {
    private let categoryRepository: CategoryRepository
    private let subCategoryRepository: SubCategoryRepository
    
    public init(
        categoryRepository: CategoryRepository,
        subCategoryRepository: SubCategoryRepository
    ) {
        self.categoryRepository = categoryRepository
        self.subCategoryRepository = subCategoryRepository
    }
    
    public func execute() async throws {
        let recommendedData = try loadRecommendedCategories()
        
        for data in recommendedData {
            let transactionType = data.transactionTypeEnum
            
            for (categoryIndex, category) in data.categories.enumerated() {
                // 1. Category DTO 생성 및 저장
                let categoryDTO = CategoryDTO(
                    id: UUID(),
                    name: category.name,
                    iconName: category.iconName,
                    transactionType: transactionType,
                    isActive: true,
                    orderIndex: categoryIndex,
                    subCategories: []
                )
                
                try await categoryRepository.insertCategory(categoryDTO)
                
                // 2. SubCategory들 저장
                for (subIndex, subCategory) in category.subCategories.enumerated() {
                    let subCategoryDTO = SubCategoryDTO(
                        id: UUID(),
                        name: subCategory.name,
                        transactionType: transactionType,
                        isActive: true,
                        orderIndex: subIndex,
                        categoryId: categoryDTO.id,
                        categoryName: categoryDTO.name,
                        categoryIconName: categoryDTO.iconName
                    )
                    
                    try await subCategoryRepository.insertSubCategory(subCategoryDTO)
                }
            }
        }
    }
    
    private func loadRecommendedCategories() throws -> [RecommendedCategoryData] {
        guard let url = Bundle.main.url(forResource: "recommended_categories", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            throw RepositoryError.custom("추천 카테고리 파일을 찾을 수 없습니다")
        }
        
        return try JSONDecoder().decode([RecommendedCategoryData].self, from: data)
    }
}