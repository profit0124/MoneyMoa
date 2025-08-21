//
//  ImportRecommendedCategoriesUseCase.swift
//  MoneyMoa
//
//  Created by Claude on 8/21/25.
//

import Foundation

// MARK: - ImportRecommendedCategoriesUseCase

public protocol ImportRecommendedCategoriesUseCase {
    func execute() async throws
}