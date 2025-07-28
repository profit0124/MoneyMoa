//
//  DTOExtensionTests.swift
//  MoneyMoaTests
//
//  Created by Sooik Kim on 7/27/25.
//

import XCTest
import SwiftData
@testable import MoneyMoa

final class DTOExtensionTests: XCTestCase {
    
    private var database: Database!
    
    override func setUpWithError() throws {
        database = try Database(isStoredInMemoryOnly: true)
    }
    
    override func tearDownWithError() throws {
        database = nil
    }
    
    // MARK: - CategoryDTO Tests
    
    func testCategoryDTO_ToModel() async throws {
        // Given: CategoryDTO 생성
        let categoryDTO = CategoryDTO(
            id: UUID(),
            name: "식비",
            transactionType: .variableExpense,
            isActive: true,
            orderIndex: 1
        )
        
        // When: DTO를 SwiftData 모델로 변환
        let category = categoryDTO.toModel()
        
        // Then: 모든 속성이 올바르게 변환됨
        XCTAssertEqual(category.id, categoryDTO.id)
        XCTAssertEqual(category.name, categoryDTO.name)
        XCTAssertEqual(category.transactionType, categoryDTO.transactionType)
        XCTAssertEqual(category.isActive, categoryDTO.isActive)
        XCTAssertEqual(category.orderIndex, categoryDTO.orderIndex)
    }
    
    func testSubCategoryDTO_ToModel() async throws {
        // Given: 상위 카테고리 모델과 SubCategoryDTO 생성
        let parentCategory = CategoryModel(
            name: "식비",
            transactionType: .variableExpense
        )
        
        let subCategoryDTO = SubCategoryDTO(
            id: UUID(),
            name: "외식비",
            transactionType: .variableExpense,
            isActive: true,
            orderIndex: 0,
            categoryId: parentCategory.id
        )
        
        // When: DTO를 SwiftData 모델로 변환
        let subCategoryModel = subCategoryDTO.toModel(parentCategory: parentCategory)
        
        // Then: 모든 속성이 올바르게 변환됨
        XCTAssertEqual(subCategoryModel.id, subCategoryDTO.id)
        XCTAssertEqual(subCategoryModel.name, subCategoryDTO.name)
        XCTAssertEqual(subCategoryModel.transactionType, subCategoryDTO.transactionType)
        XCTAssertEqual(subCategoryModel.isActive, subCategoryDTO.isActive)
        XCTAssertEqual(subCategoryModel.orderIndex, subCategoryDTO.orderIndex)
        XCTAssertEqual(subCategoryModel.category.id, parentCategory.id)
    }
    
    // MARK: - Model to DTO Tests
    
    func testCategory_ToDTOWithoutSubCategories() async throws {
        // Given: SwiftData CategoryModel 모델 생성
        try await database.withModelContext { context in
            let category = CategoryModel(
                id: UUID(),
                name: "식비",
                transactionType: .variableExpense,
                orderIndex: 1,
                isActive: true
            )
            context.insert(category)
            try context.save()
            
            // When: 모델을 DTO로 변환 (서브카테고리 제외)
            let categoryDTO = category.toDTO(includeSubCategories: false)
            
            // Then: 모든 속성이 올바르게 변환되고 서브카테고리는 빈 배열
            XCTAssertEqual(categoryDTO.id, category.id)
            XCTAssertEqual(categoryDTO.name, category.name)
            XCTAssertEqual(categoryDTO.transactionType, category.transactionType)
            XCTAssertEqual(categoryDTO.isActive, category.isActive)
            XCTAssertEqual(categoryDTO.orderIndex, category.orderIndex)
            XCTAssertTrue(categoryDTO.subCategories.isEmpty)
        }
    }
    
    func testCategory_ToDTOWithSubCategories() async throws {
        // Given: CategoryModel와 SubCategoryModel가 있는 SwiftData 모델 생성
        try await database.withModelContext { context in
            let category = CategoryModel(
                id: UUID(),
                name: "식비",
                transactionType: .variableExpense,
                orderIndex: 0,
                isActive: true
            )
            context.insert(category)
            
            let subCategory1 = SubCategoryModel(
                name: "외식비",
                transactionType: .variableExpense,
                orderIndex: 1,
                category: category,
                isActive: true
            )
            let subCategory2 = SubCategoryModel(
                name: "마트",
                transactionType: .variableExpense,
                orderIndex: 0,
                category: category,
                isActive: true
            )
            
            context.insert(subCategory1)
            context.insert(subCategory2)
            try context.save()
            
            // When: 모델을 DTO로 변환 (서브카테고리 포함)
            let categoryDTO = category.toDTO(includeSubCategories: true)
            
            // Then: 서브카테고리들이 포함됨
            XCTAssertEqual(categoryDTO.id, category.id)
            XCTAssertEqual(categoryDTO.name, category.name)
            XCTAssertEqual(categoryDTO.subCategories.count, 2)
            
            // 서브카테고리들이 orderIndex 순으로 정렬되어 있는지 확인
            XCTAssertEqual(categoryDTO.subCategories[0].name, "마트")   // orderIndex: 0
            XCTAssertEqual(categoryDTO.subCategories[1].name, "외식비") // orderIndex: 1
        }
    }
    
    func testSubCategory_ToDTO() async throws {
        // Given: SubCategoryModel가 있는 SwiftData 모델 생성
        try await database.withModelContext { context in
            let category = CategoryModel(
                name: "식비",
                transactionType: .variableExpense
            )
            context.insert(category)
            
            let subCategory = SubCategoryModel(
                id: UUID(),
                name: "외식비",
                transactionType: .variableExpense,
                orderIndex: 0,
                category: category,
                isActive: true
            )
            context.insert(subCategory)
            try context.save()
            
            // When: 모델을 DTO로 변환
            let subCategoryDTO = subCategory.toDTO()
            
            // Then: 모든 속성이 올바르게 변환됨
            XCTAssertEqual(subCategoryDTO.id, subCategory.id)
            XCTAssertEqual(subCategoryDTO.name, subCategory.name)
            XCTAssertEqual(subCategoryDTO.transactionType, subCategory.transactionType)
            XCTAssertEqual(subCategoryDTO.isActive, subCategory.isActive)
            XCTAssertEqual(subCategoryDTO.orderIndex, subCategory.orderIndex)
            XCTAssertEqual(subCategoryDTO.categoryId, category.id)
        }
    }
    
    // MARK: - Collection Extension Tests
    
    func testCategoryCollection_ToDTOsWithoutSubCategories() async throws {
        // Given: CategoryModel 배열 생성
        try await database.withModelContext { context in
            let category1 = CategoryModel(name: "식비", transactionType: .variableExpense, orderIndex: 1)
            let category2 = CategoryModel(name: "교통비", transactionType: .variableExpense, orderIndex: 0)
            
            context.insert(category1)
            context.insert(category2)
            try context.save()
            
            let categories = [category1, category2]
            
            // When: 배열을 DTO 배열로 변환 (서브카테고리 제외)
            let categoryDTOs = categories.toDTOs(includeSubCategories: false)
            
            // Then: 모든 카테고리가 변환되고 서브카테고리는 빈 배열
            XCTAssertEqual(categoryDTOs.count, 2)
            XCTAssertTrue(categoryDTOs.allSatisfy { $0.subCategories.isEmpty })
            XCTAssertEqual(categoryDTOs[0].name, category1.name)
            XCTAssertEqual(categoryDTOs[1].name, category2.name)
        }
    }
    
    func testCategoryCollection_ToDTOsWithSubCategories() async throws {
        // Given: CategoryModel와 SubCategoryModel가 있는 배열 생성
        try await database.withModelContext { context in
            let category1 = CategoryModel(name: "식비", transactionType: .variableExpense)
            let category2 = CategoryModel(name: "교통비", transactionType: .variableExpense)
            
            context.insert(category1)
            context.insert(category2)
            
            let subCategory1 = SubCategoryModel(
                name: "외식비",
                transactionType: .variableExpense,
                orderIndex: 0,
                category: category1
            )
            let subCategory2 = SubCategoryModel(
                name: "버스비",
                transactionType: .variableExpense,
                orderIndex: 0,
                category: category2
            )
            
            context.insert(subCategory1)
            context.insert(subCategory2)
            try context.save()
            
            let categories = [category1, category2]
            
            // When: 배열을 DTO 배열로 변환 (서브카테고리 포함)
            let categoryDTOs = categories.toDTOs(includeSubCategories: true)
            
            // Then: 각 카테고리의 서브카테고리들이 포함됨
            XCTAssertEqual(categoryDTOs.count, 2)
            XCTAssertEqual(categoryDTOs[0].subCategories.count, 1)
            XCTAssertEqual(categoryDTOs[1].subCategories.count, 1)
            XCTAssertEqual(categoryDTOs[0].subCategories.first?.name, "외식비")
            XCTAssertEqual(categoryDTOs[1].subCategories.first?.name, "버스비")
        }
    }
    
    func testSubCategoryCollection_ToDTOs() async throws {
        // Given: SubCategoryModel 배열 생성
        try await database.withModelContext { context in
            let category = CategoryModel(name: "식비", transactionType: .variableExpense)
            context.insert(category)
            
            let subCategory1 = SubCategoryModel(
                name: "외식비",
                transactionType: .variableExpense,
                orderIndex: 1,
                category: category
            )
            let subCategory2 = SubCategoryModel(
                name: "마트",
                transactionType: .variableExpense,
                orderIndex: 0,
                category: category
            )
            
            context.insert(subCategory1)
            context.insert(subCategory2)
            try context.save()
            
            let subCategories = [subCategory1, subCategory2]
            
            // When: 배열을 DTO 배열로 변환
            let subCategoryDTOs = subCategories.toDTOs()
            
            // Then: 모든 서브카테고리가 변환됨
            XCTAssertEqual(subCategoryDTOs.count, 2)
            XCTAssertEqual(subCategoryDTOs[1].name, subCategory1.name)
            XCTAssertEqual(subCategoryDTOs[0].name, subCategory2.name)
            XCTAssertEqual(subCategoryDTOs[1].categoryId, category.id)
            XCTAssertEqual(subCategoryDTOs[0].categoryId, category.id)
        }
    }
    
    // MARK: - DTO Comparison Tests
    
    func testCategoryDTO_Comparable() {
        // Given: 다양한 orderIndex와 이름을 가진 CategoryDTO들
        let category1 = CategoryDTO(name: "B카테고리", transactionType: .variableExpense, orderIndex: 1)
        let category2 = CategoryDTO(name: "A카테고리", transactionType: .variableExpense, orderIndex: 1)
        let category3 = CategoryDTO(name: "C카테고리", transactionType: .variableExpense, orderIndex: 0)
        
        // When: 정렬
        let sortedCategories = [category1, category2, category3].sorted()
        
        // Then: orderIndex 우선, 같으면 이름순으로 정렬
        XCTAssertEqual(sortedCategories[0].name, "C카테고리") // orderIndex: 0
        XCTAssertEqual(sortedCategories[1].name, "A카테고리") // orderIndex: 1, 이름순
        XCTAssertEqual(sortedCategories[2].name, "B카테고리") // orderIndex: 1, 이름순
    }
    
    func testSubCategoryDTO_Comparable() {
        // Given: 다양한 orderIndex와 이름을 가진 SubCategoryDTO들
        let categoryId = UUID()
        let subCategory1 = SubCategoryDTO(name: "B서브카테고리", transactionType: .variableExpense, orderIndex: 1, categoryId: categoryId)
        let subCategory2 = SubCategoryDTO(name: "A서브카테고리", transactionType: .variableExpense, orderIndex: 1, categoryId: categoryId)
        let subCategory3 = SubCategoryDTO(name: "C서브카테고리", transactionType: .variableExpense, orderIndex: 0, categoryId: categoryId)
        
        // When: 정렬
        let sortedSubCategories = [subCategory1, subCategory2, subCategory3].sorted()
        
        // Then: orderIndex 우선, 같으면 이름순으로 정렬
        XCTAssertEqual(sortedSubCategories[0].name, "C서브카테고리") // orderIndex: 0
        XCTAssertEqual(sortedSubCategories[1].name, "A서브카테고리") // orderIndex: 1, 이름순
        XCTAssertEqual(sortedSubCategories[2].name, "B서브카테고리") // orderIndex: 1, 이름순
    }
    
    // MARK: - Edge Case Tests
    
    func testCategory_ToDTOWithEmptySubCategories() async throws {
        // Given: 서브카테고리가 없는 CategoryModel
        try await database.withModelContext { context in
            let category = CategoryModel(
                name: "식비",
                transactionType: .variableExpense
            )
            context.insert(category)
            try context.save()
            
            // When: 서브카테고리 포함 모드로 변환
            let categoryDTO = category.toDTO(includeSubCategories: true)
            
            // Then: 서브카테고리 배열이 비어있음
            XCTAssertTrue(categoryDTO.subCategories.isEmpty)
        }
    }
    
    func testEmptyCollections_ToDTOs() {
        // Given: 빈 배열들
        let emptyCategories: [CategoryModel] = []
        let emptySubCategories: [SubCategoryModel] = []
        
        // When: DTO로 변환
        let categoryDTOs = emptyCategories.toDTOs(includeSubCategories: false)
        let subCategoryDTOs = emptySubCategories.toDTOs()
        
        // Then: 빈 배열 반환
        XCTAssertTrue(categoryDTOs.isEmpty)
        XCTAssertTrue(subCategoryDTOs.isEmpty)
    }
}
