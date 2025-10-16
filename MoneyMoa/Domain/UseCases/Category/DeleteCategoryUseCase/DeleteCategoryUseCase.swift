//
//  DeleteCategoryUseCase.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 10/16/25.
//

import Foundation

public protocol DeleteCategoryUseCase {
    /// 카테고리를 삭제합니다
    /// - Parameter id: 삭제할 카테고리 ID
    /// - Note: SubCategory에 Transaction이 있으면 soft delete, 없으면 hard delete
    /// - Throws: 카테고리를 찾을 수 없는 경우 등의 에러
    func execute(_ id: UUID) async throws
}
