//
//  DeleteCategoryUseCaseImpl.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 10/16/25.
//

import Foundation

final class DeleteCategoryUseCaseImpl: DeleteCategoryUseCase {
    private let categoryRepository: CategoryRepository

    init(categoryRepository: CategoryRepository) {
        self.categoryRepository = categoryRepository
    }

    func execute(_ id: UUID) async throws {
        // Repository에서 삭제 로직 처리 (Transaction 확인 후 soft/hard delete)
        try await categoryRepository.deleteCategory(id)
    }
}
