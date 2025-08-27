//
//  UpdateCategoryUseCase.swift
//  MoneyMoa
//
//  Created by Claude on 8/26/25.
//

import Foundation

public protocol UpdateCategoryUseCase {
    /// 기존 카테고리를 수정합니다
    /// - Parameter category: 수정할 카테고리 정보
    /// - Throws: 데이터 검증 실패, 수정 실패 등의 에러
    func execute(_ category: CategoryDTO) async throws
}
