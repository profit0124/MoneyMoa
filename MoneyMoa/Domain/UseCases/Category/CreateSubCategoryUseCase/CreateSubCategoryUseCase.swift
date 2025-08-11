//
//  CreateSubCategoryUseCase.swift
//  MoneyMoa
//
//  Created by profit on 8/11/25.
//

import Foundation

public protocol CreateSubCategoryUseCase {
    /// 기존 카테고리에 새로운 서브카테고리를 생성합니다
    /// - Parameter subCategory: 생성할 서브카테고리 정보
    /// - Throws: 중복 이름, 존재하지 않는 상위 카테고리 등의 에러
    func execute(_ subCategory: SubCategoryDTO) async throws
}