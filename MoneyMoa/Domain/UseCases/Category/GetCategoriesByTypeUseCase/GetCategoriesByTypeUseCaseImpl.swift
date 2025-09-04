//
//  GetCategoriesByTypeUseCaseImpl.swift
//  MoneyMoa
//
//  Created by profit on 8/11/25.
//

import Foundation

final class GetCategoriesByTypeUseCaseImpl: GetCategoriesByTypeUseCase {
    private let categoryRepository: CategoryRepository
    
    init(categoryRepository: CategoryRepository) {
        self.categoryRepository = categoryRepository
    }
    
    func execute(_ type: TransactionType) async throws -> [CategoryDTO] {
        // Repository의 fetchCategoriesByType이 이미 서브카테고리를 포함하여 반환하므로
        // 중복 조회 없이 바로 반환
        return try await categoryRepository.fetchCategoriesByType(type)
    }
}
