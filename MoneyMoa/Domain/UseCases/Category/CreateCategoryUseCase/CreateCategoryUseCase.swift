//
//  CreateCategoryUseCase.swift
//  MoneyMoa
//
//  Created by profit on 8/11/25.
//

import Foundation

public protocol CreateCategoryUseCase {
    /// 새로운 카테고리를 생성합니다
    /// - Parameter category: 생성할 카테고리 정보
    /// - Throws: 중복 이름, 유효하지 않은 데이터 등의 에러
    func execute(_ category: CategoryDTO) async throws
}