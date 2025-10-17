//
//  DeleteSubCategoryUseCase.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 10/16/25.
//

import Foundation

public protocol DeleteSubCategoryUseCase {
    /// 서브카테고리를 삭제합니다
    /// - Parameter id: 삭제할 서브카테고리 ID
    /// - Note: Transaction이 있으면 soft delete, 없으면 hard delete
    /// - Throws: 서브카테고리를 찾을 수 없는 경우 등의 에러
    func execute(_ id: UUID) async throws
}
