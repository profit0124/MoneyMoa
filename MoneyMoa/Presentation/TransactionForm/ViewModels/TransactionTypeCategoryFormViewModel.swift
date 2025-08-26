//
//  TransactionTypeCategoryFormViewModel.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/18/25.
//

import Foundation
import Observation
import Combine

/// 거래 유형 및 카테고리 선택을 관리하는 ViewModel
/// 
/// 주요 기능:
/// - 거래 유형별 카테고리 동적 로딩
/// - 서브카테고리 선택 및 관리  
/// - 카테고리/서브카테고리 동적 생성
/// - 폼 간 데이터 연동
@Observable
final class TransactionTypeCategoryFormViewModel: Identifiable {

    // MARK: - Properties
    
    /// 고유 식별자
    let id = UUID()
    
    /// 카테고리 관리를 위임할 CategoryListViewModel
    var categoryListViewModel: CategoryListViewModel

    // MARK: - Computed Properties (CategoryListViewModel 위임)
    
    /// 거래 유형별 카테고리 목록 (위임)
    var categories: [CategoryDTO] {
        categoryListViewModel.categories
    }
    
    /// 선택된 서브카테고리 (위임)
    var selectedSubCategory: SubCategoryDTO? {
        categoryListViewModel.selectedSubCategory
    }
    
    /// 현재 선택된 거래 유형 (위임)
    var selectedTransactionType: TransactionType {
        get { categoryListViewModel.selectedTransactionType }
        set { categoryListViewModel.send(.selectTransactionType(newValue)) }
    }
    
    /// 카드 요약 정보 생성 (거래 유형, 선택된 서브카테고리)
    var summary: String {
        var result: [String] = []

        result.append(selectedTransactionType.displayName)

        if let subCategory = selectedSubCategory {
            result.append("📂 \(subCategory.name)")
        }

        return result.isEmpty ? "정보 없음" : result.joined(separator: " • ")
    }

    /// 폼 유효성 검증 (서브카테고리 선택 필수)
    var isValid: Bool {
        selectedSubCategory != nil
    }

    public init(categoryListViewModel: CategoryListViewModel) {
        self.categoryListViewModel = categoryListViewModel
    }
}
