//
//  DTOExtensionTests.swift
//  MoneyMoaTests
//
//  Created by Sooik Kim on 7/27/25.
//

import XCTest
@testable import MoneyMoa

final class DTOExtensionTests: XCTestCase {
    
    // MARK: - CategoryDTO Tests
    
    func testCategoryDTO_ToModel() {
        // Given: CategoryDTO 생성
        let categoryDTO = CategoryDTO(
            name: "식비",
            iconName: "fork.knife",
            transactionType: .variableExpense,
            isActive: true,
            orderIndex: 1
        )
        
        // When: DTO를 SwiftData 모델로 변환
        let category = categoryDTO.toModel()
        
        // Then: 모든 속성이 올바르게 변환됨
        XCTAssertEqual(category.id, categoryDTO.id)
        XCTAssertEqual(category.name, categoryDTO.name)
        XCTAssertEqual(category.iconName, categoryDTO.iconName)
        XCTAssertEqual(category.transactionType, categoryDTO.transactionType)
        XCTAssertEqual(category.isActive, categoryDTO.isActive)
        XCTAssertEqual(category.orderIndex, categoryDTO.orderIndex)
    }
    
    func testSubCategoryDTO_ToModel() {
        // Given: 상위 카테고리 모델과 SubCategoryDTO 생성
        let parentCategory = Category(
            name: "식비",
            iconName: "fork.knife",
            transactionType: .variableExpense
        )
        
        let subCategoryDTO = SubCategoryDTO(
            name: "외식비",
            transactionType: .variableExpense,
            isActive: true,
            orderIndex: 0,
            categoryId: parentCategory.id,
            categoryIconName: "fork.knife"
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
    
    // MARK: - PaymentMethodDTO Tests
    
    func testPaymentMethodDTO_ToModel() {
        // Given: PaymentMethodDTO 생성
        let paymentMethodDTO = PaymentMethodDTO(
            name: "신용카드",
            kind: .credit,
            iconName: "creditcard.fill",
            orderIndex: 0,
            isActive: true
        )
        
        // When: DTO를 SwiftData 모델로 변환
        let paymentMethod = paymentMethodDTO.toModel()
        
        // Then: 모든 속성이 올바르게 변환됨
        XCTAssertEqual(paymentMethod.id, paymentMethodDTO.id)
        XCTAssertEqual(paymentMethod.name, paymentMethodDTO.name)
        XCTAssertEqual(paymentMethod.kind, paymentMethodDTO.kind)
        XCTAssertEqual(paymentMethod.iconName, paymentMethodDTO.iconName)
        XCTAssertEqual(paymentMethod.orderIndex, paymentMethodDTO.orderIndex)
        XCTAssertEqual(paymentMethod.isActive, paymentMethodDTO.isActive)
    }
    
    // MARK: - Sorting Tests
    
    func testCategoryDTO_Sorting() {
        // Given: 다른 orderIndex를 가진 CategoryDTO들
        let category1 = CategoryDTO(name: "B카테고리", iconName: "icon1", transactionType: .variableExpense, orderIndex: 2)
        let category2 = CategoryDTO(name: "A카테고리", iconName: "icon2", transactionType: .variableExpense, orderIndex: 1)
        let category3 = CategoryDTO(name: "C카테고리", iconName: "icon3", transactionType: .variableExpense, orderIndex: 1)
        
        // When: 정렬
        let sortedCategories = [category1, category2, category3].sorted()
        
        // Then: orderIndex 우선, 같으면 이름순으로 정렬
        XCTAssertEqual(sortedCategories[0].name, "A카테고리") // orderIndex: 1, name: A
        XCTAssertEqual(sortedCategories[1].name, "C카테고리") // orderIndex: 1, name: C
        XCTAssertEqual(sortedCategories[2].name, "B카테고리") // orderIndex: 2
    }
    
    func testSubCategoryDTO_Sorting() {
        // Given: 다른 orderIndex를 가진 SubCategoryDTO들
        let categoryId = UUID()
        let subCategory1 = SubCategoryDTO(name: "B서브카테고리", transactionType: .variableExpense, orderIndex: 1, categoryId: categoryId, categoryIconName: "icon")
        let subCategory2 = SubCategoryDTO(name: "A서브카테고리", transactionType: .variableExpense, orderIndex: 1, categoryId: categoryId, categoryIconName: "icon")
        let subCategory3 = SubCategoryDTO(name: "C서브카테고리", transactionType: .variableExpense, orderIndex: 0, categoryId: categoryId, categoryIconName: "icon")
        
        // When: 정렬
        let sortedSubCategories = [subCategory1, subCategory2, subCategory3].sorted()
        
        // Then: orderIndex 우선, 같으면 이름순으로 정렬
        XCTAssertEqual(sortedSubCategories[0].name, "C서브카테고리") // orderIndex: 0
        XCTAssertEqual(sortedSubCategories[1].name, "A서브카테고리") // orderIndex: 1, name: A
        XCTAssertEqual(sortedSubCategories[2].name, "B서브카테고리") // orderIndex: 1, name: B
    }
}
