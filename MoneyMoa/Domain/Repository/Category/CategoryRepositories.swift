//
//  CategoryRepository.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/27/25.
//

import Foundation

// MARK: - Category Repository Interfaces

/// 카테고리 및 서브카테고리 조회 전용 프로토콜 (읽기 작업)
public protocol CategoryReader {
    
    // MARK: - Category 조회 (Fetch Operations)
    
    /// 모든 카테고리 조회 (비활성 포함)
    /// - Returns: 전체 카테고리 목록 (orderIndex 순으로 정렬)
    func fetchCategories() async throws -> [CategoryDTO]

    /// 특정 거래 유형의 카테고리 조회 (거래 입력 시 사용)
    /// - Parameter type: 거래 유형 (수입/고정지출/변동지출)
    /// - Returns: 해당 유형의 활성 카테고리 목록
    func fetchCategoriesByType(_ type: TransactionType) async throws -> [CategoryDTO]
    
    // MARK: - SubCategory 조회 (Fetch Operations)
    
    /// 특정 카테고리의 서브카테고리 조회 (거래 입력 시 사용)
    /// - Parameter categoryId: 상위 카테고리 ID
    /// - Returns: 해당 카테고리의 활성 서브카테고리 목록
    func fetchSubCategories(categoryId: UUID) async throws -> [SubCategoryDTO]
    
    // MARK: - 검증 (Validation)
    
    /// 카테고리명 중복 확인
    /// - Parameters:
    ///   - name: 확인할 카테고리명
    ///   - type: 거래 유형
    ///   - excludingId: 제외할 ID (수정 시 자기 자신 제외)
    /// - Returns: 사용 가능하면 true
    func validateCategoryName(_ name: String, type: TransactionType, excludingId: UUID?) async throws -> Bool
    
    /// 서브카테고리명 중복 확인 (같은 상위 카테고리 내에서)
    /// - Parameters:
    ///   - name: 확인할 서브카테고리명
    ///   - categoryId: 상위 카테고리 ID
    ///   - excludingId: 제외할 ID (수정 시 자기 자신 제외)
    /// - Returns: 사용 가능하면 true
    func validateSubCategoryName(_ name: String, categoryId: UUID, excludingId: UUID?) async throws -> Bool
}

/// 카테고리 및 서브카테고리 변경 전용 프로토콜 (쓰기 작업)
public protocol CategoryWriter {
    
    // MARK: - Category 생성/수정 (Create/Update Operations)
    
    /// 새 카테고리 생성
    /// - Parameter category: 생성할 카테고리 정보
    /// - Throws: 중복 이름, 유효하지 않은 데이터 등의 에러
    func insertCategory(_ category: CategoryDTO) async throws
    
    /// 카테고리 정보 수정
    /// - Parameter category: 수정할 카테고리 정보
    /// - Throws: 존재하지 않는 카테고리, 중복 이름 등의 에러
    func updateCategory(_ category: CategoryDTO) async throws

    // MARK: - SubCategory 생성/수정 (Create/Update Operations)

    /// 새 서브카테고리 생성
    /// - Parameter subCategory: 생성할 서브카테고리 정보
    /// - Throws: 중복 이름, 존재하지 않는 상위 카테고리 등의 에러
    func insertSubCategory(_ subCategory: SubCategoryDTO) async throws
    
    /// 서브카테고리 정보 수정
    /// - Parameter subCategory: 수정할 서브카테고리 정보
    /// - Throws: 존재하지 않는 서브카테고리, 중복 이름 등의 에러
    func updateSubCategory(_ subCategory: SubCategoryDTO) async throws

    // MARK: - Category/SubCategory 삭제 (Delete Operations)

    /// 카테고리 삭제
    /// - Parameter id: 삭제할 카테고리 ID
    /// - Note: SubCategory에 Transaction이 있으면 isActive=false, 없으면 물리 삭제
    /// - Throws: 존재하지 않는 카테고리 등의 에러
    func deleteCategory(_ id: UUID) async throws

    /// 서브카테고리 삭제
    /// - Parameter id: 삭제할 서브카테고리 ID
    /// - Note: Transaction이 있으면 isActive=false, 없으면 물리 삭제
    /// - Throws: 존재하지 않는 서브카테고리 등의 에러
    func deleteSubCategory(_ id: UUID) async throws

}

/// 통합 카테고리 저장소 프로토콜 (읽기 + 쓰기)
public typealias CategoryRepository = CategoryReader & CategoryWriter
