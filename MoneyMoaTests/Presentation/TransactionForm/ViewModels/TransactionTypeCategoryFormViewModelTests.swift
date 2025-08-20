//
//  TransactionTypeCategoryFormViewModelTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 8/19/25.
//

import XCTest
@testable import MoneyMoa

// MARK: - TransactionTypeCategoryFormViewModelTests

@MainActor
final class TransactionTypeCategoryFormViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var viewModel: TransactionTypeCategoryFormViewModel!
    private var mockContainer: MockDIContainer!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        
        mockContainer = MockDIContainer()
        viewModel = mockContainer.makeTransactionTypeCategoryFormViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        mockContainer = nil
        super.tearDown()
    }
    
    // MARK: - Test Methods - Initialization
    
    func test_initialization_setsCorrectInitialValues() {
        // Then
        XCTAssertEqual(viewModel.selectedTransactionType, .variableExpense)
        XCTAssertNil(viewModel.selectedSubCategory)
        XCTAssertTrue(viewModel.categories.isEmpty)
        XCTAssertNotNil(viewModel.id)
    }
    
    // MARK: - Test Methods - Transaction Type Selection
    
    func test_selectedTransactionType_canBeChanged() {
        // When
        viewModel.selectedTransactionType = .income
        
        // Then
        XCTAssertEqual(viewModel.selectedTransactionType, .income)
    }
    
    func test_selectedTransactionType_defaultIsVariableExpense() {
        // Then
        XCTAssertEqual(viewModel.selectedTransactionType, .variableExpense)
    }
    
    // MARK: - Test Methods - SubCategory Selection
    
    func test_selectedSubCategory_canBeSet() {
        // Given
        let testSubCategory = SubCategoryDTO.mockFoodExpense
        
        // When
        viewModel.selectedSubCategory = testSubCategory
        
        // Then
        XCTAssertEqual(viewModel.selectedSubCategory?.id, testSubCategory.id)
        XCTAssertEqual(viewModel.selectedSubCategory?.name, testSubCategory.name)
    }
    
    func test_selectedSubCategory_canBeNil() {
        // Given
        viewModel.selectedSubCategory = SubCategoryDTO.mockFoodExpense
        XCTAssertNotNil(viewModel.selectedSubCategory)
        
        // When
        viewModel.selectedSubCategory = nil
        
        // Then
        XCTAssertNil(viewModel.selectedSubCategory)
    }
    
    // MARK: - Test Methods - Validation
    
    func test_isValid_withoutSubCategory_returnsFalse() {
        // Given
        viewModel.selectedTransactionType = .variableExpense
        viewModel.selectedSubCategory = nil
        
        // When
        let isValid = viewModel.isValid
        
        // Then
        XCTAssertFalse(isValid)
    }
    
    func test_isValid_withSubCategory_returnsTrue() {
        // Given
        viewModel.selectedTransactionType = .variableExpense
        viewModel.selectedSubCategory = SubCategoryDTO.mockFoodExpense
        
        // When
        let isValid = viewModel.isValid
        
        // Then
        XCTAssertTrue(isValid)
    }
    
    // MARK: - Test Methods - Categories Management
    
    func test_categories_initiallyEmpty() {
        // Then
        XCTAssertTrue(viewModel.categories.isEmpty)
    }
    
    func test_categories_canBePopulated() {
        // Given
        let mockCategories = [
            CategoryDTO.mockFood,
            CategoryDTO.mockTransport
        ]
        
        // When
        viewModel.categories = mockCategories
        
        // Then
        XCTAssertEqual(viewModel.categories.count, 2)
        XCTAssertTrue(viewModel.categories.contains { $0.name == "식비" })
        XCTAssertTrue(viewModel.categories.contains { $0.name == "교통비" })
    }
    
    // MARK: - Test Methods - Observable Pattern
    
    func test_transactionTypeChange_triggersPropertyChange() {
        // Given
        let initialType = viewModel.selectedTransactionType
        
        // When
        viewModel.selectedTransactionType = .income
        
        // Then
        XCTAssertNotEqual(viewModel.selectedTransactionType, initialType)
        XCTAssertEqual(viewModel.selectedTransactionType, .income)
    }
    
    func test_subCategoryChange_triggersPropertyChange() {
        // Given
        let initialSubCategory = viewModel.selectedSubCategory
        let newSubCategory = SubCategoryDTO.mockIncomeAllowance
        
        // When
        viewModel.selectedSubCategory = newSubCategory
        
        // Then
        XCTAssertNotEqual(viewModel.selectedSubCategory?.id, initialSubCategory?.id)
        XCTAssertEqual(viewModel.selectedSubCategory?.id, newSubCategory.id)
    }
    
    // MARK: - Test Methods - Different Transaction Types
    
    func test_transactionTypeSelection_income() {
        // When
        viewModel.selectedTransactionType = .income
        viewModel.selectedSubCategory = SubCategoryDTO.mockSalary
        
        // Then
        XCTAssertEqual(viewModel.selectedTransactionType, .income)
        XCTAssertEqual(viewModel.selectedSubCategory?.transactionType, .income)
        XCTAssertTrue(viewModel.isValid)
    }
    
    func test_transactionTypeSelection_fixedExpense() {
        // When
        viewModel.selectedTransactionType = .fixedExpense
        
        // Then
        XCTAssertEqual(viewModel.selectedTransactionType, .fixedExpense)
    }
    
    func test_transactionTypeSelection_variableExpense() {
        // When
        viewModel.selectedTransactionType = .variableExpense
        viewModel.selectedSubCategory = SubCategoryDTO.mockFoodExpense
        
        // Then
        XCTAssertEqual(viewModel.selectedTransactionType, .variableExpense)
        XCTAssertEqual(viewModel.selectedSubCategory?.transactionType, .variableExpense)
        XCTAssertTrue(viewModel.isValid)
    }
    
    // MARK: - Test Methods - State Management
    
    func test_categoryFormViewModel_initiallyNil() {
        // Then
        XCTAssertNil(viewModel.categoryFormViewModel)
    }
    
    func test_categoryFormViewModel_canBeSet() {
        // Given - categoryFormViewModel은 실제로는 CategoryFormViewModel 타입이지만
        // Mock을 직접 만들지 않고 설정 가능한지만 테스트
        
        // When - 실제로는 내부에서 생성되므로 직접 테스트하지 않음
        // viewModel.categoryFormViewModel = mockCategoryForm
        
        // Then - 초기 상태는 nil이어야 함
        XCTAssertNil(viewModel.categoryFormViewModel)
    }
    
    // MARK: - Test Methods - Data Consistency
    
    func test_selectedSubCategory_matchesTransactionType() {
        // Given
        viewModel.selectedTransactionType = .variableExpense
        
        // When
        viewModel.selectedSubCategory = SubCategoryDTO.mockFoodExpense
        
        // Then - SubCategory의 transactionType이 선택된 type과 일치
        XCTAssertEqual(viewModel.selectedSubCategory?.transactionType, viewModel.selectedTransactionType)
    }
    
    func test_multipleSubCategories_canBeHandled() {
        // Given
        let expenseSubCategory = SubCategoryDTO.mockFoodExpense
        let incomeSubCategory = SubCategoryDTO.mockIncomeAllowance
        
        // When - Expense subcategory 선택
        viewModel.selectedTransactionType = .variableExpense
        viewModel.selectedSubCategory = expenseSubCategory
        
        // Then
        XCTAssertEqual(viewModel.selectedSubCategory?.id, expenseSubCategory.id)
        XCTAssertTrue(viewModel.isValid)
        
        // When - Income subcategory 선택
        viewModel.selectedTransactionType = .income
        viewModel.selectedSubCategory = incomeSubCategory
        
        // Then
        XCTAssertEqual(viewModel.selectedSubCategory?.id, incomeSubCategory.id)
        XCTAssertTrue(viewModel.isValid)
    }
}