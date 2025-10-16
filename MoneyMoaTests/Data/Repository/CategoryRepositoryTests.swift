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
        let category2 = TestDataFactory.createCategory(name: "교통비", iconName: "car.fill") // 기본값: orderIndex=0
        let category3 = TestDataFactory.createCategory(name: "급여", iconName: "dollarsign.circle.fill", type: .income) // 기본값: orderIndex=0
        
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
    
    func testFetchCategoriesByType() async throws {
        // Given: 다양한 타입의 카테고리들 생성
        let incomeCategory = TestDataFactory.createCategory(name: "급여", type: .income)
        let fixedExpenseCategory = TestDataFactory.createCategory(name: "월세", type: .fixedExpense)
        let variableExpenseCategory = TestDataFactory.createCategory(name: "식비", type: .variableExpense)
        
        try await repository.insertCategory(incomeCategory)
        try await repository.insertCategory(fixedExpenseCategory)
        try await repository.insertCategory(variableExpenseCategory)
        
        // When: 수입 타입 카테고리만 조회
        let incomeCategories = try await repository.fetchCategoriesByType(.income)
        
        // Then: 수입 카테고리만 반환
        XCTAssertEqual(incomeCategories.count, 1)
        XCTAssertEqual(incomeCategories[0].name, "급여")
        XCTAssertEqual(incomeCategories[0].transactionType, .income)
    }
    
    func testFetchSubCategories_WithCategoryId() async throws {
        // Given: 카테고리와 서브카테고리 생성
        let category = TestDataFactory.createCategory()
        try await repository.insertCategory(category)
        
        let subCategory1 = TestDataFactory.createSubCategory(name: "외식비", categoryId: category.id)
        let subCategory2 = TestDataFactory.createSubCategory(name: "마트", categoryId: category.id)
        
        try await repository.insertSubCategory(subCategory1)
        try await repository.insertSubCategory(subCategory2)
        
        // When: 특정 카테고리의 서브카테고리 조회
        let subCategories = try await repository.fetchSubCategories(categoryId: category.id)
        
        // Then: 해당 카테고리의 활성 서브카테고리들 반환
        XCTAssertEqual(subCategories.count, 2)
    }
    
    // MARK: - 생성/수정 테스트 (Create/Update Operations)
    
    func testInsertCategory_Success() async throws {
        // Given: 새 카테고리 생성
        let newCategory = TestDataFactory.createCategory(name: "의료비", iconName: "cross.circle.fill", type: .variableExpense)
        
        // When: 카테고리 삽입
        try await repository.insertCategory(newCategory)
        
        // Then: 카테고리가 정상적으로 저장됨
        let categories = try await repository.fetchCategories()
        XCTAssertEqual(categories.count, 1)
        XCTAssertEqual(categories[0].name, "의료비")
        XCTAssertEqual(categories[0].transactionType, .variableExpense)
    }
    
    func testUpdateCategory_Success() async throws {
        // Given: 기존 카테고리 생성
        let originalCategory = TestDataFactory.createCategory()
        try await repository.insertCategory(originalCategory)
        
        // When: 카테고리 정보 수정 (name만 수정)
        let updatedCategory = CategoryDTO(
            id: originalCategory.id,
            name: "수정된 식비",
            iconName: originalCategory.iconName,
            transactionType: originalCategory.transactionType,
            isActive: originalCategory.isActive,
            orderIndex: 5,
            subCategories: []
        )
        try await repository.updateCategory(updatedCategory)
        
        // Then: 카테고리가 정상적으로 수정됨
        let categories = try await repository.fetchCategories()
        XCTAssertEqual(categories.count, 1)
        XCTAssertEqual(categories[0].name, "수정된 식비")
        XCTAssertEqual(categories[0].orderIndex, 5)
    }
    
    func testInsertSubCategory_Success() async throws {
        // Given: 상위 카테고리 생성
        let category = TestDataFactory.createCategory()
        try await repository.insertCategory(category)
        
        // When: 서브카테고리 삽입
        let subCategory = TestDataFactory.createSubCategory(categoryId: category.id)
        try await repository.insertSubCategory(subCategory)
        
        // Then: 서브카테고리가 정상적으로 저장됨
        let subCategories = try await repository.fetchSubCategories(categoryId: category.id)
        XCTAssertEqual(subCategories.count, 1)
        XCTAssertEqual(subCategories[0].name, "외식비")
    }
    
    func testUpdateSubCategory_Success() async throws {
        // Given: 카테고리와 서브카테고리 생성
        let category = TestDataFactory.createCategory()
        try await repository.insertCategory(category)
        
        let originalSubCategory = TestDataFactory.createSubCategory(categoryId: category.id)
        try await repository.insertSubCategory(originalSubCategory)
        
        // When: 서브카테고리 정보 수정
        let updatedSubCategory = SubCategoryDTO(
            id: originalSubCategory.id,
            name: "수정된 외식비",
            transactionType: .variableExpense,
            isActive: true,
            orderIndex: 5,
            categoryId: category.id,
            categoryName: category.name,
            categoryIconName: category.iconName
        )
        try await repository.updateSubCategory(updatedSubCategory)
        
        // Then: 서브카테고리가 정상적으로 수정됨
        let subCategories = try await repository.fetchSubCategories(categoryId: category.id)
        XCTAssertEqual(subCategories.count, 1)
        XCTAssertEqual(subCategories[0].name, "수정된 외식비")
        XCTAssertEqual(subCategories[0].orderIndex, 5)
    }
    
    // MARK: - 검증 테스트 (Validation)
    
    func testValidateCategoryName_AvailableName() async throws {
        // Given: 기존 카테고리 생성
        let existingCategory = TestDataFactory.createCategory(name: "식비", type: .variableExpense)
        try await repository.insertCategory(existingCategory)
        
        // When: 다른 이름으로 검증
        let isValid = try await repository.validateCategoryName("교통비", type: .variableExpense, excludingId: nil)
        
        // Then: 사용 가능한 이름으로 판단
        XCTAssertTrue(isValid)
    }
    
    func testValidateCategoryName_DuplicateName() async throws {
        // Given: 기존 카테고리 생성
        let existingCategory = TestDataFactory.createCategory(name: "식비", type: .variableExpense)
        try await repository.insertCategory(existingCategory)
        
        // When: 같은 이름으로 검증
        let isValid = try await repository.validateCategoryName("식비", type: .variableExpense, excludingId: nil)
        
        // Then: 중복된 이름으로 판단
        XCTAssertFalse(isValid)
    }
    
    func testValidateSubCategoryName_AvailableName() async throws {
        // Given: 카테고리와 서브카테고리 생성
        let category = TestDataFactory.createCategory()
        try await repository.insertCategory(category)
        
        let existingSubCategory = TestDataFactory.createSubCategory(name: "외식비", categoryId: category.id)
        try await repository.insertSubCategory(existingSubCategory)
        
        // When: 다른 이름으로 검증
        let isValid = try await repository.validateSubCategoryName("마트", categoryId: category.id, excludingId: nil)
        
        // Then: 사용 가능한 이름으로 판단
        XCTAssertTrue(isValid)
    }
    
    func testValidateSubCategoryName_DuplicateName() async throws {
        // Given: 카테고리와 서브카테고리 생성
        let category = TestDataFactory.createCategory()
        try await repository.insertCategory(category)

        let existingSubCategory = TestDataFactory.createSubCategory(name: "외식비", categoryId: category.id)
        try await repository.insertSubCategory(existingSubCategory)

        // When: 같은 이름으로 검증
        let isValid = try await repository.validateSubCategoryName("외식비", categoryId: category.id, excludingId: nil)

        // Then: 중복된 이름으로 판단
        XCTAssertFalse(isValid)
    }

    // MARK: - 삭제 테스트 (Delete Operations)

    func testDeleteCategory_WithoutTransactions_ShouldHardDelete() async throws {
        // Given: Transaction이 없는 Category와 SubCategory
        let category = TestDataFactory.createCategory(name: "식비")
        try await repository.insertCategory(category)

        let subCategory = TestDataFactory.createSubCategory(name: "외식비", categoryId: category.id)
        try await repository.insertSubCategory(subCategory)

        // When: Category 삭제
        try await repository.deleteCategory(category.id)

        // Then: Category와 SubCategory가 물리적으로 삭제됨
        let categories = try await repository.fetchCategories()
        XCTAssertTrue(categories.isEmpty)
    }

    func testDeleteCategory_WithTransactions_ShouldSoftDelete() async throws {
        // Given: Transaction이 있는 Category와 SubCategory
        let category = TestDataFactory.createCategory(name: "식비")
        try await repository.insertCategory(category)

        let subCategory = TestDataFactory.createSubCategory(name: "외식비", categoryId: category.id)
        try await repository.insertSubCategory(subCategory)

        let paymentMethod = TestDataFactory.createPaymentMethod()
        let paymentMethodRepository = PaymentMethodRepositoryImpl(database: database)
        try await paymentMethodRepository.insertPaymentMethod(paymentMethod)

        let transaction = TestDataFactory.createTransaction(
            amount: 10000,
            subCategory: subCategory,
            paymentMethod: paymentMethod
        )
        let transactionRepository = TransactionRepositoryImpl(database: database)
        try await transactionRepository.insertTransaction(transaction)

        // When: Category 삭제
        try await repository.deleteCategory(category.id)

        // Then: Category와 SubCategory의 isActive가 false로 변경됨
        let categories = try await repository.fetchCategories()
        XCTAssertEqual(categories.count, 1)
        XCTAssertFalse(categories[0].isActive)

        let subCategories = try await database.withModelContext { context in
            let descriptor = FetchDescriptor<SubCategory>()
            return try context.fetch(descriptor).toDTOs()
        }
        XCTAssertEqual(subCategories.count, 1)
        XCTAssertFalse(subCategories[0].isActive)
    }

    func testDeleteCategory_NotFound_ShouldThrowError() async throws {
        // Given: 존재하지 않는 Category ID
        let nonExistentId = UUID()

        // When/Then: 에러 발생
        do {
            try await repository.deleteCategory(nonExistentId)
            XCTFail("Should throw categoryNotFound error")
        } catch let error as RepositoryError {
            switch error {
            case .categoryNotFound:
                break // Expected error
            default:
                XCTFail("Unexpected error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testDeleteSubCategory_WithoutTransactions_ShouldHardDelete() async throws {
        // Given: Transaction이 없는 SubCategory
        let category = TestDataFactory.createCategory(name: "식비")
        try await repository.insertCategory(category)

        let subCategory = TestDataFactory.createSubCategory(name: "외식비", categoryId: category.id)
        try await repository.insertSubCategory(subCategory)

        // When: SubCategory 삭제
        try await repository.deleteSubCategory(subCategory.id)

        // Then: SubCategory가 물리적으로 삭제됨
        let subCategories = try await repository.fetchSubCategories(categoryId: category.id)
        XCTAssertTrue(subCategories.isEmpty)
    }

    func testDeleteSubCategory_WithTransactions_ShouldSoftDelete() async throws {
        // Given: Transaction이 있는 SubCategory
        let category = TestDataFactory.createCategory(name: "식비")
        try await repository.insertCategory(category)

        let subCategory = TestDataFactory.createSubCategory(name: "외식비", categoryId: category.id)
        try await repository.insertSubCategory(subCategory)

        let paymentMethod = TestDataFactory.createPaymentMethod()
        let paymentMethodRepository = PaymentMethodRepositoryImpl(database: database)
        try await paymentMethodRepository.insertPaymentMethod(paymentMethod)

        let transaction = TestDataFactory.createTransaction(
            amount: 10000,
            subCategory: subCategory,
            paymentMethod: paymentMethod
        )
        let transactionRepository = TransactionRepositoryImpl(database: database)
        try await transactionRepository.insertTransaction(transaction)

        // When: SubCategory 삭제
        try await repository.deleteSubCategory(subCategory.id)

        // Then: SubCategory의 isActive가 false로 변경됨
        let subCategories = try await database.withModelContext { context in
            let descriptor = FetchDescriptor<SubCategory>()
            return try context.fetch(descriptor).toDTOs()
        }
        XCTAssertEqual(subCategories.count, 1)
        XCTAssertFalse(subCategories[0].isActive)
    }

    func testDeleteSubCategory_NotFound_ShouldThrowError() async throws {
        // Given: 존재하지 않는 SubCategory ID
        let nonExistentId = UUID()

        // When/Then: 에러 발생
        do {
            try await repository.deleteSubCategory(nonExistentId)
            XCTFail("Should throw subCategoryNotFound error")
        } catch let error as RepositoryError {
            switch error {
            case .subCategoryNotFound:
                break // Expected error
            default:
                XCTFail("Unexpected error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testDeleteCategory_WithMultipleSubCategories_OnlyOneHasTransactions() async throws {
        // Given: 여러 SubCategory 중 하나만 Transaction을 가진 경우
        let category = TestDataFactory.createCategory(name: "식비")
        try await repository.insertCategory(category)

        let subCategory1 = TestDataFactory.createSubCategory(name: "외식비", categoryId: category.id)
        let subCategory2 = TestDataFactory.createSubCategory(name: "마트", categoryId: category.id)
        try await repository.insertSubCategory(subCategory1)
        try await repository.insertSubCategory(subCategory2)

        let paymentMethod = TestDataFactory.createPaymentMethod()
        let paymentMethodRepository = PaymentMethodRepositoryImpl(database: database)
        try await paymentMethodRepository.insertPaymentMethod(paymentMethod)

        // subCategory1에만 Transaction 추가
        let transaction = TestDataFactory.createTransaction(
            amount: 10000,
            subCategory: subCategory1,
            paymentMethod: paymentMethod
        )
        let transactionRepository = TransactionRepositoryImpl(database: database)
        try await transactionRepository.insertTransaction(transaction)

        // When: Category 삭제
        try await repository.deleteCategory(category.id)

        // Then: Category와 모든 SubCategory가 soft delete됨
        let categories = try await repository.fetchCategories()
        XCTAssertEqual(categories.count, 1)
        XCTAssertFalse(categories[0].isActive)

        let allSubCategories = try await database.withModelContext { context in
            let descriptor = FetchDescriptor<SubCategory>()
            return try context.fetch(descriptor).toDTOs()
        }
        XCTAssertEqual(allSubCategories.count, 2)
        XCTAssertTrue(allSubCategories.allSatisfy { !$0.isActive })
    }
}
