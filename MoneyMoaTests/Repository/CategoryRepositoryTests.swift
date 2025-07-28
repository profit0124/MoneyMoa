//
//  CategoryRepositoryTests.swift
//  MoneyMoaTests
//
//  Created by Sooik Kim on 7/27/25.
//

import XCTest
import SwiftData
@testable import MoneyMoa

final class CategoryRepositoryTests: XCTestCase {
    
    private var database: Database!
    private var repository: CategoryRepositoryImpl!
    
    override func setUpWithError() throws {
        // 각 테스트마다 새로운 인메모리 데이터베이스 생성
        database = try Database(isStoredInMemoryOnly: true)
        repository = CategoryRepositoryImpl(database: database)
    }
    
    override func tearDownWithError() throws {
        database = nil
        repository = nil
    }
    
    // MARK: - 조회 테스트 (Fetch Operations)
    
    func testFetchCategories_EmptyDatabase() async throws {
        // Given: 빈 데이터베이스
        
        // When: 모든 카테고리 조회
        let categories = try await repository.fetchCategories()
        
        // Then: 빈 배열 반환
        XCTAssertTrue(categories.isEmpty)
    }
    
    func testFetchCategories_WithData() async throws {
        // Given: 테스트 카테고리들 생성
        let category1 = TestDataFactory.createCategory(orderIndex: 1) // 기본값: name="식비", type=.variableExpense
        let category2 = TestDataFactory.createCategory(name: "교통비") // 기본값: orderIndex=0
        let category3 = TestDataFactory.createCategory(name: "급여", type: .income) // 기본값: orderIndex=0
        
        try await repository.insertCategory(category1)
        try await repository.insertCategory(category2)
        try await repository.insertCategory(category3)
        
        // When: 모든 카테고리 조회
        let categories = try await repository.fetchCategories()
        
        // Then: orderIndex 순으로 정렬되어 반환
        XCTAssertEqual(categories.count, 3)
        XCTAssertEqual(categories[0].name, "교통비") // orderIndex: 0
        XCTAssertEqual(categories[1].name, "급여")   // orderIndex: 0, name으로 정렬
        XCTAssertEqual(categories[2].name, "식비")   // orderIndex: 1
    }
    
    func testFetchCategory_ExistingId() async throws {
        // Given: 테스트 카테고리 생성
        let originalCategory = TestDataFactory.createCategory(name: "식비", type: .variableExpense, orderIndex: 0)
        try await repository.insertCategory(originalCategory)
        
        // When: 특정 카테고리 조회
        let category = try await repository.fetchCategory(id: originalCategory.id)
        
        // Then: 해당 카테고리 반환
        XCTAssertNotNil(category)
        XCTAssertEqual(category?.id, originalCategory.id)
        XCTAssertEqual(category?.name, "식비")
        XCTAssertEqual(category?.transactionType, .variableExpense)
        XCTAssertTrue(category?.subCategories.isEmpty ?? false)
    }
    
    func testFetchCategory_NonExistingId() async throws {
        // Given: 빈 데이터베이스
        let nonExistingId = UUID()
        
        // When: 존재하지 않는 ID로 조회
        let category = try await repository.fetchCategory(id: nonExistingId)
        
        // Then: nil 반환
        XCTAssertNil(category)
    }
    
    func testFetchCategoryWithSubCategories() async throws {
        // Given: 카테고리와 서브카테고리 생성
        let category = TestDataFactory.createCategory() // 모든 기본값 사용
        try await repository.insertCategory(category)
        
        // SubCategoryModel는 별도 Repository에서 처리되므로 직접 데이터베이스에 추가
        try await database.withModelContext { context in
            let categoryModel = try context.fetch(FetchDescriptor<CategoryModel>()).first!
            let subCategoryDTO = TestDataFactory.createSubCategory(categoryId: categoryModel.id) // 기본값: name="외식비"
            let subCategory = subCategoryDTO.toModel(parentCategory: categoryModel)
            context.insert(subCategory)
            try context.save()
        }
        
        // When: 서브카테고리 포함 조회
        let result = try await repository.fetchCategoryWithSubCategories(id: category.id)
        
        // Then: 서브카테고리 포함하여 반환
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.subCategories.count, 1)
        XCTAssertEqual(result?.subCategories.first?.name, "외식비")
    }
    
    func testFetchActiveCategories() async throws {
        // Given: 활성/비활성 카테고리들 생성
        let activeCategory = TestDataFactory.createCategory(name: "활성카테고리", type: .variableExpense, isActive: true)
        let inactiveCategory = TestDataFactory.createCategory(name: "비활성카테고리", type: .variableExpense, isActive: false)
        
        try await repository.insertCategory(activeCategory)
        try await repository.insertCategory(inactiveCategory)
        
        // When: 활성 카테고리만 조회
        let categories = try await repository.fetchActiveCategories()
        
        // Then: 활성 카테고리만 반환
        XCTAssertEqual(categories.count, 1)
        XCTAssertEqual(categories.first?.name, "활성카테고리")
        XCTAssertTrue(categories.first?.isActive ?? false)
    }
    
    func testFetchCategoriesByType() async throws {
        // Given: 다양한 유형의 카테고리들 생성
        let incomeCategory = TestDataFactory.createCategory(name: "급여", type: .income)
        let expenseCategory1 = TestDataFactory.createCategory(name: "식비", type: .variableExpense)
        let expenseCategory2 = TestDataFactory.createCategory(name: "교통비", type: .variableExpense)
        let fixedExpenseCategory = TestDataFactory.createCategory(name: "월세", type: .fixedExpense)
        
        try await repository.insertCategory(incomeCategory)
        try await repository.insertCategory(expenseCategory1)
        try await repository.insertCategory(expenseCategory2)
        try await repository.insertCategory(fixedExpenseCategory)
        
        // When: 변동지출 카테고리만 조회
        let categories = try await repository.fetchCategoriesByType(.variableExpense)
        
        // Then: 해당 유형의 카테고리만 반환
        XCTAssertEqual(categories.count, 2)
        XCTAssertTrue(categories.allSatisfy { $0.transactionType == .variableExpense })
    }
    
    // MARK: - 생성/수정 테스트 (Create/Update Operations)
    
    func testInsertCategory_Success() async throws {
        // Given: 새로운 카테고리 DTO
        let category = TestDataFactory.createCategory() // 모든 기본값 사용
        
        // When: 카테고리 삽입
        try await repository.insertCategory(category)
        
        // Then: 데이터베이스에 저장됨
        let categories = try await repository.fetchCategories()
        XCTAssertEqual(categories.count, 1)
        XCTAssertEqual(categories.first?.name, "식비")
        XCTAssertEqual(categories.first?.id, category.id)
    }
    
    func testUpdateCategory_Success() async throws {
        // Given: 기존 카테고리 생성
        let originalCategory = TestDataFactory.createCategory(name: "식비", type: .variableExpense, orderIndex: 0)
        try await repository.insertCategory(originalCategory)
        
        // When: 카테고리 정보 수정
        let updatedCategory = CategoryDTO(
            id: originalCategory.id,
            name: "외식비",
            transactionType: .variableExpense,
            isActive: false,
            orderIndex: 1
        )
        try await repository.updateCategory(updatedCategory)
        
        // Then: 변경사항이 반영됨
        let category = try await repository.fetchCategory(id: originalCategory.id)
        XCTAssertEqual(category?.name, "외식비")
        XCTAssertFalse(category?.isActive ?? true)
        XCTAssertEqual(category?.orderIndex, 1)
    }
    
    func testUpdateCategory_NonExistingCategory() async throws {
        // Given: 존재하지 않는 카테고리 ID
        let nonExistingCategory = TestDataFactory.createCategory(name: "존재하지않음", type: .variableExpense)
        
        // When & Then: 에러 발생
        do {
            try await repository.updateCategory(nonExistingCategory)
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
    
    // MARK: - 활성/비활성 관리 테스트 (Activation Management)
    
    func testDeactivateCategory_Success() async throws {
        // Given: 활성 카테고리 생성
        let category = TestDataFactory.createCategory(name: "식비", type: .variableExpense, isActive: true)
        try await repository.insertCategory(category)
        
        // When: 카테고리 비활성화
        try await repository.deactivateCategory(id: category.id)
        
        // Then: 비활성 상태로 변경됨
        let updatedCategory = try await repository.fetchCategory(id: category.id)
        XCTAssertFalse(updatedCategory?.isActive ?? true)
    }
    
    func testDeactivateCategory_NonExistingCategory() async throws {
        // Given: 존재하지 않는 카테고리 ID
        let nonExistingId = UUID()
        
        // When & Then: 에러 발생
        do {
            try await repository.deactivateCategory(id: nonExistingId)
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
    
    func testActivateCategory_Success() async throws {
        // Given: 비활성 카테고리 생성
        let category = TestDataFactory.createCategory(name: "식비", type: .variableExpense, isActive: false)
        try await repository.insertCategory(category)
        
        // When: 카테고리 활성화
        try await repository.activateCategory(id: category.id)
        
        // Then: 활성 상태로 변경됨
        let updatedCategory = try await repository.fetchCategory(id: category.id)
        XCTAssertTrue(updatedCategory?.isActive ?? false)
    }
    
    func testActivateCategory_NonExistingCategory() async throws {
        // Given: 존재하지 않는 카테고리 ID
        let nonExistingId = UUID()
        
        // When & Then: 에러 발생
        do {
            try await repository.activateCategory(id: nonExistingId)
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
    
    // MARK: - 삭제 테스트 (Delete Operations)
    
    func testDeleteCategory_InactiveCategory_Success() async throws {
        // Given: 비활성 카테고리 생성
        let category = TestDataFactory.createCategory(name: "식비", type: .variableExpense, isActive: false)
        try await repository.insertCategory(category)
        
        // When: 카테고리 삭제
        try await repository.deleteCategory(id: category.id)
        
        // Then: 데이터베이스에서 삭제됨
        let categories = try await repository.fetchCategories()
        XCTAssertTrue(categories.isEmpty)
    }
    
    func testDeleteCategory_ActiveCategory_ThrowsError() async throws {
        // Given: 활성 카테고리 생성
        let category = TestDataFactory.createCategory(name: "식비", type: .variableExpense, isActive: true)
        try await repository.insertCategory(category)
        
        // When & Then: 에러 발생
        do {
            try await repository.deleteCategory(id: category.id)
            XCTFail("Expected error to be thrown")
        } catch {
            switch error {
            case RepositoryError.cannotDeleteActiveCategory:
                break // 예상된 에러
            default:
                XCTFail("Expected cannotDeleteActiveCategory error, but got \(error)")
            }
        }
        
        // 카테고리가 여전히 존재함
        let categories = try await repository.fetchCategories()
        XCTAssertEqual(categories.count, 1)
    }
    
    func testDeleteCategory_NonExistingCategory() async throws {
        // Given: 존재하지 않는 카테고리 ID
        let nonExistingId = UUID()
        
        // When & Then: 에러 발생
        do {
            try await repository.deleteCategory(id: nonExistingId)
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
    
    // MARK: - 검증 테스트 (Validation)
    
    func testValidateCategoryName_AvailableName() async throws {
        // Given: 기존 카테고리 생성
        let existingCategory = TestDataFactory.createCategory(name: "식비", type: .variableExpense)
        try await repository.insertCategory(existingCategory)
        
        // When: 다른 이름으로 검증
        let isValid = try await repository.validateCategoryName("교통비", type: .variableExpense, excludingId: nil)
        
        // Then: 사용 가능
        XCTAssertTrue(isValid)
    }
    
    func testValidateCategoryName_DuplicateName() async throws {
        // Given: 기존 카테고리 생성
        let existingCategory = TestDataFactory.createCategory(name: "식비", type: .variableExpense)
        try await repository.insertCategory(existingCategory)
        
        // When: 동일한 이름으로 검증
        let isValid = try await repository.validateCategoryName("식비", type: .variableExpense, excludingId: nil)
        
        // Then: 사용 불가능
        XCTAssertFalse(isValid)
    }
    
    func testValidateCategoryName_DuplicateNameButDifferentType() async throws {
        // Given: 기존 카테고리 생성 (변동지출)
        let existingCategory = TestDataFactory.createCategory(name: "용돈", type: .variableExpense)
        try await repository.insertCategory(existingCategory)
        
        // When: 동일한 이름이지만 다른 유형으로 검증 (수입)
        let isValid = try await repository.validateCategoryName("용돈", type: .income, excludingId: nil)
        
        // Then: 사용 가능 (다른 거래 유형이므로)
        XCTAssertTrue(isValid)
    }
    
    func testValidateCategoryName_ExcludingSelf() async throws {
        // Given: 기존 카테고리 생성
        let existingCategory = TestDataFactory.createCategory(name: "식비", type: .variableExpense)
        try await repository.insertCategory(existingCategory)
        
        // When: 자기 자신을 제외하고 검증 (수정 시나리오)
        let isValid = try await repository.validateCategoryName("식비", type: .variableExpense, excludingId: existingCategory.id)
        
        // Then: 사용 가능 (자기 자신 제외)
        XCTAssertTrue(isValid)
    }
    
    func testHasTransactions_WithTransactions() async throws {
        // Given: 카테고리, 서브카테고리, 거래 내역 생성
        let category = TestDataFactory.createCategory() // 기본값: name="식비", type=.variableExpense
        try await repository.insertCategory(category)
        
        // 데이터베이스에 직접 서브카테고리와 거래 내역 추가
        try await database.withModelContext { context in
            let categoryModel = try context.fetch(FetchDescriptor<CategoryModel>()).first!
            let subCategoryDTO = TestDataFactory.createSubCategory(categoryId: categoryModel.id) // 기본값: name="외식비"
            let subCategory = subCategoryDTO.toModel(parentCategory: categoryModel)
            context.insert(subCategory)
            
            let paymentMethodDTO = TestDataFactory.createPaymentMethod(name: "현금", kind: .cash)
            let paymentMethod = paymentMethodDTO.toModel()
            context.insert(paymentMethod)
            
            let transactionDTO = TestDataFactory.createTransaction(
                memo: "점심식사", // 기본값: amount=10000
                subCategory: subCategoryDTO,
                paymentMethod: paymentMethodDTO
            )
            let transaction = transactionDTO.toModel(subCategory: subCategory, paymentMethod: paymentMethod)
            context.insert(transaction)
            try context.save()
        }
        
        // When: 거래 내역 존재 여부 확인
        let hasTransactions = try await repository.hasTransactions(categoryId: category.id)
        
        // Then: 거래 내역 존재
        XCTAssertTrue(hasTransactions)
    }
    
    func testHasTransactions_WithoutTransactions() async throws {
        // Given: 카테고리만 생성 (서브카테고리 없음)
        let category = TestDataFactory.createCategory() // 기본값: name="식비", type=.variableExpense
        try await repository.insertCategory(category)
        
        // When: 거래 내역 존재 여부 확인
        let hasTransactions = try await repository.hasTransactions(categoryId: category.id)
        
        // Then: 거래 내역 없음
        XCTAssertFalse(hasTransactions)
    }
    
    func testHasTransactions_WithSubCategoryModelButNoTransactions() async throws {
        // Given: 카테고리와 서브카테고리 생성 (거래 없음)
        let category = TestDataFactory.createCategory() // 기본값: name="식비", type=.variableExpense
        try await repository.insertCategory(category)
        
        try await database.withModelContext { context in
            let categoryModel = try context.fetch(FetchDescriptor<CategoryModel>()).first!
            let subCategoryDTO = TestDataFactory.createSubCategory(categoryId: categoryModel.id) // 기본값: name="외식비"
            let subCategory = subCategoryDTO.toModel(parentCategory: categoryModel)
            context.insert(subCategory)
            try context.save()
        }
        
        // When: 거래 내역 존재 여부 확인
        let hasTransactions = try await repository.hasTransactions(categoryId: category.id)
        
        // Then: 거래 내역 없음
        XCTAssertFalse(hasTransactions)
    }
}
