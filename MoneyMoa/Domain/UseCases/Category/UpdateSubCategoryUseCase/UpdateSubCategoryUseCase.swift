//
//  UpdateSubCategoryUseCase.swift
//  MoneyMoa
//
//  Created by Claude on 8/25/25.
//

import Foundation

public protocol UpdateSubCategoryUseCase {
    /// 기존 서브카테고리를 수정합니다
    /// - Parameter subCategory: 수정할 서브카테고리 정보
    /// - Throws: 데이터 검증 실패, 수정 실패 등의 에러
    func execute(_ subCategory: SubCategoryDTO) async throws
}
