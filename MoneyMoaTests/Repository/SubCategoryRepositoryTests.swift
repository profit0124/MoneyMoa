//
//  SubCategoryRepositoryTests.swift
//  MoneyMoaTests
//
//  Created by Sooik Kim on 7/27/25.
//

import XCTest
import SwiftData
@testable import MoneyMoa

final class SubCategoryRepositoryTests: XCTestCase {
    
    private var database: Database!
    private var repository: SubCategoryRepositoryImpl!
    private var parentCategoryId: UUID!
    
    override func setUpWithError() throws {
        // 각 테스트마다 새로운 인메모리 데이터베이스 생성
        database = try Database(isStoredInMemoryOnly: true)
        repository = SubCategoryRepositoryImpl(database: database)
        
        // 테스트용 상위 카테고리 ID 생성 (실제 생성은 각 테스트에서)
        parentCategoryId = UUID()
    }
    
    override func tearDownWithError() throws {
        database = nil
        repository = nil
        parentCategoryId = nil
    }
    
    // MARK: - Helper Methods
    
    private func createParentCategory(id: UUID, name: String, type: TransactionType) async throws {
        try await database.withModelContext { context in
            let category = CategoryModel(
                id: id,
                name: name,
                transactionType: type
            )
            context.insert(category)
            try context.save()
        }
    }
    
    private func setupParentCategory() async throws {
        try await createParentCategory(id: parentCategoryId, name: "식비", type: .variableExpense)
    }
    
    private func createParentCategories() async throws -> (UUID, UUID) {
        let categoryId1 = UUID()
        let categoryId2 = UUID()
        
        try await database.withModelContext { context in
            let category1 = CategoryModel(id: categoryId1, name: "식비", transactionType: .variableExpense)
            let category2 = CategoryModel(id: categoryId2, name: "급여", transactionType: .income)
            
            context.insert(category1)
            context.insert(category2)
            try context.save()
        }
        
        return (categoryId1, categoryId2)
    }
    
    // MARK: - 조회 테스트 (Fetch Operations)
    
    func testFetchSubCategories_EmptyDatabase() async throws {
        // Given: 빈 데이터베이스 (상위 카테고리만 존재)
        try await setupParentCategory()
        
        // When: 모든 서브카테고리 조회
        let subCategories = try await repository.fetchSubCategories()
        
        // Then: 빈 배열 반환
        XCTAssertTrue(subCategories.isEmpty)
    }
    
    func testFetchSubCategories_WithData() async throws {
        // Given: 상위 카테고리 설정 및 테스트 서브카테고리들 생성
        try await setupParentCategory()
        
        let subCategory1 = SubCategoryDTO(name: "외식비", transactionType: .variableExpense, orderIndex: 1, categoryId: parentCategoryId)
        let subCategory2 = SubCategoryDTO(name: "마트", transactionType: .variableExpense, orderIndex: 0, categoryId: parentCategoryId)
        
        try await repository.insertSubCategory(subCategory1)
        try await repository.insertSubCategory(subCategory2)
        
        // When: 모든 서브카테고리 조회
        let subCategories = try await repository.fetchSubCategories()
        
        // Then: orderIndex 순으로 정렬되어 반환
        XCTAssertEqual(subCategories.count, 2)
        XCTAssertEqual(subCategories[0].name, "마트")   // orderIndex: 0
        XCTAssertEqual(subCategories[1].name, "외식비") // orderIndex: 1
    }
    
    func testFetchSubCategory_ExistingId() async throws {
        // Given: 상위 카테고리 설정 및 테스트 서브카테고리 생성
        try await setupParentCategory()
        
        let originalSubCategory = SubCategoryDTO(name: "외식비", transactionType: .variableExpense, categoryId: parentCategoryId)
        try await repository.insertSubCategory(originalSubCategory)
        
        // When: 특정 서브카테고리 조회
        let subCategory = try await repository.fetchSubCategory(id: originalSubCategory.id)
        
        // Then: 해당 서브카테고리 반환
        XCTAssertNotNil(subCategory)
        XCTAssertEqual(subCategory?.id, originalSubCategory.id)
        XCTAssertEqual(subCategory?.name, "외식비")
        XCTAssertEqual(subCategory?.transactionType, .variableExpense)
        XCTAssertEqual(subCategory?.categoryId, parentCategoryId)
    }
    
    func testFetchSubCategory_NonExistingId() async throws {
        // Given: 빈 데이터베이스
        let nonExistingId = UUID()
        
        // When: 존재하지 않는 ID로 조회
        let subCategory = try await repository.fetchSubCategory(id: nonExistingId)
        
        // Then: nil 반환
        XCTAssertNil(subCategory)
    }
    
    func testFetchSubCategories_ByCategoryId() async throws {
        // Given: 두 개의 카테고리와 각각의 서브카테고리들 생성
        let (categoryId1, categoryId2) = try await createParentCategories()
        
        let subCategory1 = SubCategoryDTO(name: "외식비", transactionType: .variableExpense, categoryId: categoryId1)
        let subCategory2 = SubCategoryDTO(name: "마트", transactionType: .variableExpense, categoryId: categoryId1)
        let subCategory3 = SubCategoryDTO(name: "본급", transactionType: .income, categoryId: categoryId2)
        let inactiveSubCategory = SubCategoryDTO(name: "비활성", transactionType: .variableExpense, isActive: false, categoryId: categoryId1)
        
        try await repository.insertSubCategory(subCategory1)
        try await repository.insertSubCategory(subCategory2)
        try await repository.insertSubCategory(subCategory3)
        try await repository.insertSubCategory(inactiveSubCategory)
        
        // When: 특정 카테고리의 서브카테고리만 조회
        let subCategories = try await repository.fetchSubCategories(categoryId: categoryId1)
        
        // Then: 해당 카테고리의 활성 서브카테고리만 반환
        XCTAssertEqual(subCategories.count, 2)
        XCTAssertTrue(subCategories.allSatisfy { $0.categoryId == categoryId1 })
        XCTAssertTrue(subCategories.allSatisfy { $0.isActive })
    }
    
    func testFetchActiveSubCategories() async throws {
        // Given: 상위 카테고리 설정 및 활성/비활성 서브카테고리들 생성
        try await setupParentCategory()
        
        let activeSubCategory = SubCategoryDTO(name: "활성서브카테고리", transactionType: .variableExpense, isActive: true, categoryId: parentCategoryId)
        let inactiveSubCategory = SubCategoryDTO(name: "비활성서브카테고리", transactionType: .variableExpense, isActive: false, categoryId: parentCategoryId)
        
        try await repository.insertSubCategory(activeSubCategory)
        try await repository.insertSubCategory(inactiveSubCategory)
        
        // When: 활성 서브카테고리만 조회
        let subCategories = try await repository.fetchActiveSubCategories()
        
        // Then: 활성 서브카테고리만 반환
        XCTAssertEqual(subCategories.count, 1)
        XCTAssertEqual(subCategories.first?.name, "활성서브카테고리")
        XCTAssertTrue(subCategories.first?.isActive ?? false)
    }
    
    func testFetchSubCategoriesByType() async throws {
        // Given: 다양한 유형의 서브카테고리들 생성
        let (categoryId1, categoryId2) = try await createParentCategories()
        
        let expenseSubCategory1 = SubCategoryDTO(name: "외식비", transactionType: .variableExpense, categoryId: categoryId1)
        let expenseSubCategory2 = SubCategoryDTO(name: "마트", transactionType: .variableExpense, categoryId: categoryId1)
        let incomeSubCategory = SubCategoryDTO(name: "본급", transactionType: .income, categoryId: categoryId2)
        
        try await repository.insertSubCategory(expenseSubCategory1)
        try await repository.insertSubCategory(expenseSubCategory2)
        try await repository.insertSubCategory(incomeSubCategory)
        
        // When: 변동지출 서브카테고리만 조회
        let subCategories = try await repository.fetchSubCategoriesByType(.variableExpense)
        
        // Then: 해당 유형의 서브카테고리만 반환
        XCTAssertEqual(subCategories.count, 2)
        XCTAssertTrue(subCategories.allSatisfy { $0.transactionType == .variableExpense })
    }
    
    // MARK: - 생성/수정 테스트 (Create/Update Operations)
    
    func testInsertSubCategory_Success() async throws {
        // Given: 상위 카테고리 설정 및 새로운 서브카테고리 DTO
        try await setupParentCategory()
        
        let subCategory = SubCategoryDTO(name: "외식비", transactionType: .variableExpense, categoryId: parentCategoryId)
        
        // When: 서브카테고리 삽입
        try await repository.insertSubCategory(subCategory)
        
        // Then: 데이터베이스에 저장됨
        let subCategories = try await repository.fetchSubCategories()
        XCTAssertEqual(subCategories.count, 1)
        XCTAssertEqual(subCategories.first?.name, "외식비")
        XCTAssertEqual(subCategories.first?.id, subCategory.id)
        XCTAssertEqual(subCategories.first?.categoryId, parentCategoryId)
    }
    
    func testInsertSubCategory_NonExistingParentCategory() async throws {
        // Given: 존재하지 않는 상위 카테고리 ID
        let nonExistingCategoryId = UUID()
        let subCategory = SubCategoryDTO(name: "외식비", transactionType: .variableExpense, categoryId: nonExistingCategoryId)
        
        // When & Then: 에러 발생
        do {
            try await repository.insertSubCategory(subCategory)
            XCTFail("Expected error to be thrown")
        } catch {
            switch error {
            case RepositoryError.categoryNotFound:
                break // 예상된 에러
            default:
                XCTFail("Expected categoryNotFound error, but got \(error)")
            }
        }
    }
    
    func testUpdateSubCategory_Success() async throws {
        // Given: 상위 카테고리 설정 및 기존 서브카테고리 생성
        try await setupParentCategory()
        
        let originalSubCategory = SubCategoryDTO(name: "외식비", transactionType: .variableExpense, categoryId: parentCategoryId)
        try await repository.insertSubCategory(originalSubCategory)
        
        // When: 서브카테고리 정보 수정
        let updatedSubCategory = SubCategoryDTO(
            id: originalSubCategory.id,
            name: "배달음식",
            transactionType: .variableExpense,
            isActive: false,
            orderIndex: 1,
            categoryId: parentCategoryId
        )
        try await repository.updateSubCategory(updatedSubCategory)
        
        // Then: 변경사항이 반영됨
        let subCategory = try await repository.fetchSubCategory(id: originalSubCategory.id)
        XCTAssertEqual(subCategory?.name, "배달음식")
        XCTAssertFalse(subCategory?.isActive ?? true)
        XCTAssertEqual(subCategory?.orderIndex, 1)
    }
    
    func testUpdateSubCategory_NonExistingSubCategory() async throws {
        // Given: 존재하지 않는 서브카테고리 ID
        let nonExistingSubCategory = SubCategoryDTO(name: "존재하지않음", transactionType: .variableExpense, categoryId: parentCategoryId)
        
        // When & Then: 에러 발생
        do {
            try await repository.updateSubCategory(nonExistingSubCategory)
            XCTFail("Expected error to be thrown")
        } catch {
            switch error {
            case RepositoryError.subCategoryNotFound:
                break // 예상된 에러
            default:
                XCTFail("Expected subCategoryNotFound error, but got \(error)")
            }
        }
    }
    
    // MARK: - 활성/비활성 관리 테스트 (Activation Management)
    
    func testDeactivateSubCategory_Success() async throws {
        // Given: 상위 카테고리 설정 및 활성 서브카테고리 생성
        try await setupParentCategory()
        
        let subCategory = SubCategoryDTO(name: "외식비", transactionType: .variableExpense, isActive: true, categoryId: parentCategoryId)
        try await repository.insertSubCategory(subCategory)
        
        // When: 서브카테고리 비활성화
        try await repository.deactivateSubCategory(id: subCategory.id)
        
        // Then: 비활성 상태로 변경됨
        let updatedSubCategory = try await repository.fetchSubCategory(id: subCategory.id)
        XCTAssertFalse(updatedSubCategory?.isActive ?? true)
    }
    
    func testDeactivateSubCategory_NonExistingSubCategory() async throws {
        // Given: 존재하지 않는 서브카테고리 ID
        let nonExistingId = UUID()
        
        // When & Then: 에러 발생
        do {
            try await repository.deactivateSubCategory(id: nonExistingId)
            XCTFail("Expected error to be thrown")
        } catch {
            switch error {
            case RepositoryError.subCategoryNotFound:
                break // 예상된 에러
            default:
                XCTFail("Expected subCategoryNotFound error, but got \(error)")
            }
        }
    }
    
    func testActivateSubCategory_Success() async throws {
        // Given: 상위 카테고리 설정 및 비활성 서브카테고리 생성
        try await setupParentCategory()
        
        let subCategory = SubCategoryDTO(name: "외식비", transactionType: .variableExpense, isActive: false, categoryId: parentCategoryId)
        try await repository.insertSubCategory(subCategory)
        
        // When: 서브카테고리 활성화
        try await repository.activateSubCategory(id: subCategory.id)
        
        // Then: 활성 상태로 변경됨
        let updatedSubCategory = try await repository.fetchSubCategory(id: subCategory.id)
        XCTAssertTrue(updatedSubCategory?.isActive ?? false)
    }
    
    // MARK: - 삭제 테스트 (Delete Operations)
    
    func testDeleteSubCategory_InactiveSubCategory_Success() async throws {
        // Given: 상위 카테고리 설정 및 비활성 서브카테고리 생성
        try await setupParentCategory()
        
        let subCategory = SubCategoryDTO(name: "외식비", transactionType: .variableExpense, isActive: false, categoryId: parentCategoryId)
        try await repository.insertSubCategory(subCategory)
        
        // When: 서브카테고리 삭제
        try await repository.deleteSubCategory(id: subCategory.id)
        
        // Then: 데이터베이스에서 삭제됨
        let subCategories = try await repository.fetchSubCategories()
        XCTAssertTrue(subCategories.isEmpty)
    }
    
    func testDeleteSubCategory_ActiveSubCategory_ThrowsError() async throws {
        // Given: 상위 카테고리 설정 및 활성 서브카테고리 생성
        try await setupParentCategory()
        
        let subCategory = SubCategoryDTO(name: "외식비", transactionType: .variableExpense, isActive: true, categoryId: parentCategoryId)
        try await repository.insertSubCategory(subCategory)
        
        // When & Then: 에러 발생
        do {
            try await repository.deleteSubCategory(id: subCategory.id)
            XCTFail("Expected error to be thrown")
        } catch {
            switch error {
            case RepositoryError.cannotDeleteActiveSubCategory:
                break // 예상된 에러
            default:
                XCTFail("Expected cannotDeleteActiveSubCategory error, but got \(error)")
            }
        }
        
        // 서브카테고리가 여전히 존재함
        let subCategories = try await repository.fetchSubCategories()
        XCTAssertEqual(subCategories.count, 1)
    }
    
    // MARK: - 검증 테스트 (Validation)
    
    func testValidateSubCategoryName_AvailableName() async throws {
        // Given: 상위 카테고리 설정 및 기존 서브카테고리 생성
        try await setupParentCategory()
        
        let existingSubCategory = SubCategoryDTO(name: "외식비", transactionType: .variableExpense, categoryId: parentCategoryId)
        try await repository.insertSubCategory(existingSubCategory)
        
        // When: 다른 이름으로 검증
        let isValid = try await repository.validateSubCategoryName("마트", categoryId: parentCategoryId, excludingId: nil)
        
        // Then: 사용 가능
        XCTAssertTrue(isValid)
    }
    
    func testValidateSubCategoryName_DuplicateNameSameCategory() async throws {
        // Given: 상위 카테고리 설정 및 기존 서브카테고리 생성
        try await setupParentCategory()
        
        let existingSubCategory = SubCategoryDTO(name: "외식비", transactionType: .variableExpense, categoryId: parentCategoryId)
        try await repository.insertSubCategory(existingSubCategory)
        
        // When: 같은 카테고리 내에서 동일한 이름으로 검증
        let isValid = try await repository.validateSubCategoryName("외식비", categoryId: parentCategoryId, excludingId: nil)
        
        // Then: 사용 불가능
        XCTAssertFalse(isValid)
    }
    
    func testValidateSubCategoryName_ExcludingSelf() async throws {
        // Given: 상위 카테고리 설정 및 기존 서브카테고리 생성
        try await setupParentCategory()
        
        let existingSubCategory = SubCategoryDTO(name: "외식비", transactionType: .variableExpense, categoryId: parentCategoryId)
        try await repository.insertSubCategory(existingSubCategory)
        
        // When: 자기 자신을 제외하고 검증 (수정 시나리오)
        let isValid = try await repository.validateSubCategoryName("외식비", categoryId: parentCategoryId, excludingId: existingSubCategory.id)
        
        // Then: 사용 가능 (자기 자신 제외)
        XCTAssertTrue(isValid)
    }
    
    func testHasTransactions_WithTransactions() async throws {
        // Given: 상위 카테고리 설정 및 서브카테고리와 거래 내역 생성
        try await setupParentCategory()
        
        let subCategory = SubCategoryDTO(name: "외식비", transactionType: .variableExpense, categoryId: parentCategoryId)
        try await repository.insertSubCategory(subCategory)
        
        // 데이터베이스에 직접 거래 내역 추가
        try await database.withModelContext { context in
            let subCategoryModel = try context.fetch(FetchDescriptor<SubCategoryModel>()).first!
            
            let paymentMethod = PaymentMethodModel(name: "현금", kind: .cash)
            context.insert(paymentMethod)
            
            let transaction = TransactionModel(
                amount: 10000,
                date: Date(),
                memo: "점심식사",
                transactionType: .fixedExpense,
                subCategory: subCategoryModel,
                paymentMethod: paymentMethod
            )
            context.insert(transaction)
            try context.save()
        }
        
        // When: 거래 내역 존재 여부 확인
        let hasTransactions = try await repository.hasTransactions(subCategoryId: subCategory.id)
        
        // Then: 거래 내역 존재
        XCTAssertTrue(hasTransactions)
    }
    
    func testHasTransactions_WithoutTransactions() async throws {
        // Given: 상위 카테고리 설정 및 서브카테고리만 생성 (거래 없음)
        try await setupParentCategory()
        
        let subCategory = SubCategoryDTO(name: "외식비", transactionType: .variableExpense, categoryId: parentCategoryId)
        try await repository.insertSubCategory(subCategory)
        
        // When: 거래 내역 존재 여부 확인
        let hasTransactions = try await repository.hasTransactions(subCategoryId: subCategory.id)
        
        // Then: 거래 내역 없음
        XCTAssertFalse(hasTransactions)
    }
}
