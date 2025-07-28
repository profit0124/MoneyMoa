//
//  CategoryRepository.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/27/25.
//

import Foundation

// MARK: - Category Repository Protocol

public protocol CategoryRepository {
    
    // MARK: - 조회 (Fetch Operations)
    
    /// 모든 카테고리 조회 (비활성 포함)
    /// - Returns: 전체 카테고리 목록 (orderIndex 순으로 정렬)
    func fetchCategories() async throws -> [CategoryDTO]
    
    /// 특정 카테고리 조회
    /// - Parameter id: 카테고리 ID
    /// - Returns: 해당 카테고리 또는 nil
    func fetchCategory(id: UUID) async throws -> CategoryDTO?
    
    /// 특정 카테고리 조회 (서브카테고리 포함)
    /// - Parameter id: 카테고리 ID
    /// - Returns: 해당 카테고리와 서브카테고리들 또는 nil
    func fetchCategoryWithSubCategories(id: UUID) async throws -> CategoryDTO?
    
    /// 활성 카테고리만 조회 (UI 표시용)
    /// - Returns: 활성 상태인 카테고리 목록
    func fetchActiveCategories() async throws -> [CategoryDTO]
    
    /// 특정 거래 유형의 카테고리 조회 (거래 입력 시 사용)
    /// - Parameter type: 거래 유형 (수입/고정지출/변동지출)
    /// - Returns: 해당 유형의 활성 카테고리 목록
    func fetchCategoriesByType(_ type: TransactionType) async throws -> [CategoryDTO]
    
    // MARK: - 생성/수정 (Create/Update Operations)
    
    /// 새 카테고리 생성
    /// - Parameter category: 생성할 카테고리 정보
    /// - Throws: 중복 이름, 유효하지 않은 데이터 등의 에러
    func insertCategory(_ category: CategoryDTO) async throws
    
    /// 카테고리 정보 수정
    /// - Parameter category: 수정할 카테고리 정보
    /// - Throws: 존재하지 않는 카테고리, 중복 이름 등의 에러
    func updateCategory(_ category: CategoryDTO) async throws
    
    // MARK: - 활성/비활성 관리 (Activation Management)
    
    /// 카테고리 비활성화 (1단계: 활성 → 비활성)
    /// - Parameter id: 비활성화할 카테고리 ID
    /// - Note: 비활성화된 카테고리는 UI에서 숨겨지지만 데이터는 보존됨
    func deactivateCategory(id: UUID) async throws
    
    /// 카테고리 활성화 (비활성 → 활성 복구)
    /// - Parameter id: 활성화할 카테고리 ID
    func activateCategory(id: UUID) async throws
    
    // MARK: - 삭제 관련 (Delete Operations)
    
    /// 카테고리 완전 삭제 (2단계: 비활성 → 삭제)
    /// - Parameter id: 삭제할 카테고리 ID
    /// - Warning: 비활성 상태인 카테고리만 삭제 가능. 관련된 모든 거래 내역과 서브카테고리도 함께 삭제됨
    /// - Throws: 활성 상태 카테고리 삭제 시도 시 에러
    func deleteCategory(id: UUID) async throws
    
    // MARK: - 검증 (Validation)
    
    /// 카테고리명 중복 확인
    /// - Parameters:
    ///   - name: 확인할 카테고리명
    ///   - type: 거래 유형
    ///   - excludingId: 제외할 ID (수정 시 자기 자신 제외)
    /// - Returns: 사용 가능하면 true
    func validateCategoryName(_ name: String, type: TransactionType, excludingId: UUID?) async throws -> Bool
    
    /// 카테고리에 거래 내역 존재 여부 확인
    /// - Parameter id: 확인할 카테고리 ID
    /// - Returns: 거래 내역이 있으면 true
    func hasTransactions(categoryId: UUID) async throws -> Bool
}

// MARK: - SubCategory Repository Protocol

public protocol SubCategoryRepository {
    
    // MARK: - 조회 (Fetch Operations)
    
    /// 모든 서브카테고리 조회
    /// - Returns: 전체 서브카테고리 목록
    func fetchSubCategories() async throws -> [SubCategoryDTO]
    
    /// 특정 서브카테고리 조회
    /// - Parameter id: 서브카테고리 ID
    /// - Returns: 해당 서브카테고리 또는 nil
    func fetchSubCategory(id: UUID) async throws -> SubCategoryDTO?
    
    /// 특정 카테고리의 서브카테고리 조회 (거래 입력 시 사용)
    /// - Parameter categoryId: 상위 카테고리 ID
    /// - Returns: 해당 카테고리의 활성 서브카테고리 목록
    func fetchSubCategories(categoryId: UUID) async throws -> [SubCategoryDTO]
    
    /// 활성 서브카테고리만 조회
    /// - Returns: 활성 상태인 서브카테고리 목록
    func fetchActiveSubCategories() async throws -> [SubCategoryDTO]
    
    /// 특정 거래 유형의 서브카테고리 조회
    /// - Parameter type: 거래 유형
    /// - Returns: 해당 유형의 활성 서브카테고리 목록
    func fetchSubCategoriesByType(_ type: TransactionType) async throws -> [SubCategoryDTO]
    
    // MARK: - 생성/수정 (Create/Update Operations)
    
    /// 새 서브카테고리 생성
    /// - Parameter subCategory: 생성할 서브카테고리 정보
    /// - Throws: 중복 이름, 존재하지 않는 상위 카테고리 등의 에러
    func insertSubCategory(_ subCategory: SubCategoryDTO) async throws
    
    /// 서브카테고리 정보 수정
    /// - Parameter subCategory: 수정할 서브카테고리 정보
    /// - Throws: 존재하지 않는 서브카테고리, 중복 이름 등의 에러
    func updateSubCategory(_ subCategory: SubCategoryDTO) async throws
    
    // MARK: - 활성/비활성 관리 (Activation Management)
    
    /// 서브카테고리 비활성화 (1단계: 활성 → 비활성)
    /// - Parameter id: 비활성화할 서브카테고리 ID
    /// - Note: 비활성화된 서브카테고리는 UI에서 숨겨지지만 데이터는 보존됨
    func deactivateSubCategory(id: UUID) async throws
    
    /// 서브카테고리 활성화 (비활성 → 활성 복구)
    /// - Parameter id: 활성화할 서브카테고리 ID
    func activateSubCategory(id: UUID) async throws
    
    // MARK: - 삭제 관련 (Delete Operations)
    
    /// 서브카테고리 완전 삭제 (2단계: 비활성 → 삭제)
    /// - Parameter id: 삭제할 서브카테고리 ID
    /// - Warning: 비활성 상태인 서브카테고리만 삭제 가능. 관련된 모든 거래 내역도 함께 삭제됨
    /// - Throws: 활성 상태 서브카테고리 삭제 시도 시 에러
    func deleteSubCategory(id: UUID) async throws
    
    // MARK: - 검증 (Validation)
    
    /// 서브카테고리명 중복 확인 (같은 상위 카테고리 내에서)
    /// - Parameters:
    ///   - name: 확인할 서브카테고리명
    ///   - categoryId: 상위 카테고리 ID
    ///   - excludingId: 제외할 ID (수정 시 자기 자신 제외)
    /// - Returns: 사용 가능하면 true
    func validateSubCategoryName(_ name: String, categoryId: UUID, excludingId: UUID?) async throws -> Bool
    
    /// 서브카테고리에 거래 내역 존재 여부 확인
    /// - Parameter id: 확인할 서브카테고리 ID
    /// - Returns: 거래 내역이 있으면 true
    func hasTransactions(subCategoryId: UUID) async throws -> Bool
}
