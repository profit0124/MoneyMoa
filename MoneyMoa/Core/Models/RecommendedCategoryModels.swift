//
//  RecommendedCategoryModels.swift
//  MoneyMoa
//
//  Created by Claude on 8/21/25.
//

import Foundation

// MARK: - JSON 파싱용 모델

struct RecommendedCategoryData: Codable {
    let transactionType: String
    let categories: [RecommendedCategory]
}

struct RecommendedCategory: Codable {
    let name: String
    let iconName: String
    let subCategories: [RecommendedSubCategory]
}

struct RecommendedSubCategory: Codable {
    let name: String
}

// MARK: - 변환 확장

extension RecommendedCategoryData {
    var transactionTypeEnum: TransactionType {
        TransactionType(rawValue: transactionType) ?? .variableExpense
    }
}
