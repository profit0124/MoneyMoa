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
final class TransactionTypeCategoryFormVMTests: XCTestCase {
    
    // MARK: - Properties
    
    private var viewModel: TransactionTypeCategoryFormViewModel!
    private var mockContainer: MockDIContainer!
    private var mockCategoryListViewModel: CategoryListViewModel!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        
        mockContainer = MockDIContainer()
        mockCategoryListViewModel = mockContainer.makeCategoryListViewModel(mode: .selection)
        viewModel = TransactionTypeCategoryFormViewModel(categoryListViewModel: mockCategoryListViewModel)
    }
    
    override func tearDown() {
        viewModel = nil
        mockCategoryListViewModel = nil
        mockContainer = nil
        super.tearDown()
    }
    
    // MARK: - Test Methods - Initialization
    
    func test_initialization_hasValidId() {
        // Then
        XCTAssertNotNil(viewModel.id)
    }
    
    func test_initialization_hasCategoryListViewModel() {
        // Then
        XCTAssertNotNil(viewModel.categoryListViewModel)
        XCTAssertEqual(viewModel.categoryListViewModel.mode, .selection)
    }
    
    // MARK: - Test Methods - Composition Pattern (Delegation)
    
    func test_categories_delegatedToCategoryListViewModel() {
        // Given - CategoryListViewModel에 카테고리 추가
        mockCategoryListViewModel.categories = [CategoryDTO.mockFood, CategoryDTO.mockTransport]
        
        // When
        let categories = viewModel.categories
        
        // Then - TransactionTypeCategoryFormViewModel이 CategoryListViewModel의 categories를 반환
        XCTAssertEqual(categories.count, 2)
        XCTAssertEqual(categories, mockCategoryListViewModel.categories)
    }
    
    func test_selectedSubCategory_delegatedToCategoryListViewModel() {
        // Given
        let testSubCategory = SubCategoryDTO.mockFoodExpense
        mockCategoryListViewModel.selectedSubCategory = testSubCategory
        
        // When
        let selectedSubCategory = viewModel.selectedSubCategory
        
        // Then
        XCTAssertEqual(selectedSubCategory?.id, testSubCategory.id)
        XCTAssertEqual(selectedSubCategory, mockCategoryListViewModel.selectedSubCategory)
    }
    
    func test_selectedTransactionType_getter_delegatedToCategoryListViewModel() {
        // Given
        mockCategoryListViewModel.selectedTransactionType = .income
        
        // When
        let transactionType = viewModel.selectedTransactionType
        
        // Then
        XCTAssertEqual(transactionType, .income)
        XCTAssertEqual(transactionType, mockCategoryListViewModel.selectedTransactionType)
    }
    
    func test_selectedTransactionType_setter_delegatedToCategoryListViewModel() {
        // Given
        XCTAssertEqual(mockCategoryListViewModel.selectedTransactionType, .variableExpense) // 초기값
        
        // When
        viewModel.selectedTransactionType = .income
        
        // Then
        XCTAssertEqual(mockCategoryListViewModel.selectedTransactionType, .income)
        XCTAssertEqual(viewModel.selectedTransactionType, .income)
    }
    
    // MARK: - Test Methods - Summary Generation
    
    func test_summary_withoutSubCategory_showsTransactionTypeOnly() {
        // Given
        viewModel.selectedTransactionType = .income
        mockCategoryListViewModel.selectedSubCategory = nil
        
        // When
        let summary = viewModel.summary
        
        // Then
        XCTAssertEqual(summary, "수입")
        XCTAssertFalse(summary.contains("📂"))
    }
    
    func test_summary_withSubCategory_showsTransactionTypeAndSubCategory() {
        // Given
        viewModel.selectedTransactionType = .variableExpense
        mockCategoryListViewModel.selectedSubCategory = SubCategoryDTO.mockFoodExpense
        
        // When
        let summary = viewModel.summary
        
        // Then
        XCTAssertTrue(summary.contains("변동지출"))
        XCTAssertTrue(summary.contains("📂 외식비")) // mockFoodExpense.name = "외식비"
        XCTAssertTrue(summary.contains(" • "))
    }
    
    func test_summary_withDifferentTransactionTypes() {
        // Test Income
        viewModel.selectedTransactionType = .income
        mockCategoryListViewModel.selectedSubCategory = SubCategoryDTO.mockSalary
        XCTAssertTrue(viewModel.summary.contains("수입"))
        XCTAssertTrue(viewModel.summary.contains("📂 급여"))
        
//        // Test Fixed Expense
//        viewModel.selectedTransactionType = .fixedExpense
//        mockCategoryListViewModel.selectedSubCategory = SubCategoryDTO.mockRent
//        XCTAssertTrue(viewModel.summary.contains("고정비"))
//        XCTAssertTrue(viewModel.summary.contains("📂 월세"))
        
        // Test Variable Expense
        viewModel.selectedTransactionType = .variableExpense
        mockCategoryListViewModel.selectedSubCategory = SubCategoryDTO.mockFoodExpense
        XCTAssertTrue(viewModel.summary.contains("변동지출"))
        XCTAssertTrue(viewModel.summary.contains("📂 외식비")) // mockFoodExpense.name = "외식비"
    }
    
    // MARK: - Test Methods - Validation
    
    func test_isValid_withoutSubCategory_returnsFalse() {
        // Given
        mockCategoryListViewModel.selectedSubCategory = nil
        
        // When
        let isValid = viewModel.isValid
        
        // Then
        XCTAssertFalse(isValid)
    }
    
    func test_isValid_withSubCategory_returnsTrue() {
        // Given
        mockCategoryListViewModel.selectedSubCategory = SubCategoryDTO.mockFoodExpense
        
        // When
        let isValid = viewModel.isValid
        
        // Then
        XCTAssertTrue(isValid)
    }
    
    // MARK: - Test Methods - CategoryListViewModel Integration
    
    func test_categoryListViewModel_actionDelegation() {
        // Given
        let initialType = mockCategoryListViewModel.selectedTransactionType
        
        // When - CategoryListViewModel의 action을 통해 거래 유형 변경
        mockCategoryListViewModel.send(.selectTransactionType(.income))
        
        // Then - TransactionTypeCategoryFormViewModel에서도 변경된 값 확인 가능
        XCTAssertNotEqual(viewModel.selectedTransactionType, initialType)
        XCTAssertEqual(viewModel.selectedTransactionType, .income)
    }
    
    func test_categoryListViewModel_modeIsSelection() {
        // Then
        XCTAssertEqual(viewModel.categoryListViewModel.mode, .selection)
    }
    
    // MARK: - Test Methods - Factory Integration
    
    func test_factoryCreation_createsValidViewModel() {
        // Given
        let factoryViewModel = mockContainer.makeTransactionTypeCategoryFormViewModel()
        
        // Then
        XCTAssertNotNil(factoryViewModel.categoryListViewModel)
        XCTAssertEqual(factoryViewModel.categoryListViewModel.mode, .selection)
        XCTAssertEqual(factoryViewModel.selectedTransactionType, .variableExpense) // 기본값
    }
    
    func test_factoryCreation_withInitialValues() {
        // Given
        let testSubCategory = SubCategoryDTO.mockFoodExpense
        let factoryViewModel = mockContainer.makeTransactionTypeCategoryFormViewModel(
            transactionType: .income,
            subCategory: testSubCategory
        )
        
        // Then
        XCTAssertEqual(factoryViewModel.selectedTransactionType, .income)
        XCTAssertEqual(factoryViewModel.selectedSubCategory?.id, testSubCategory.id)
    }
}
