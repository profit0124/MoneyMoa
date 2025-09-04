//
//  GetCategoriesByTypeUseCase.swift
//  MoneyMoa
//
//  Created by profit on 8/11/25.
//

import Foundation

public protocol GetCategoriesByTypeUseCase {
    /// 특정 거래 유형의 활성 카테고리들을 서브카테고리 포함하여 조회합니다
    /// - Parameter type: 거래 유형
    /// - Returns: 해당 유형의 활성 카테고리 목록 (서브카테고리 포함)
    func execute(_ type: TransactionType) async throws -> [CategoryDTO]
}
