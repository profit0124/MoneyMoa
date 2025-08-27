//
//  CategoryFormViewModelTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 8/27/25.
//

import XCTest
import Combine
@testable import MoneyMoa

// MARK: - CategoryFormViewModelTests

@MainActor
final class CategoryFormViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var viewModel: CategoryFormViewModel!
    private var mockCreateCategoryUseCase: MockCreateCategoryUseCase!
    private var mockCreateSubCategoryUseCase: MockCreateSubCategoryUseCase!
    private var mockUpdateCategoryUseCase: MockUpdateCategoryUseCase!
    private var mockCategoryEventPublisher: MockCategoryEventPublisher!
    private var mockRouter: AppRouter!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        
        mockCreateCategoryUseCase = MockCreateCategoryUseCase()
        mockCreateSubCategoryUseCase = MockCreateSubCategoryUseCase()
        mockUpdateCategoryUseCase = MockUpdateCategoryUseCase()
        mockCategoryEventPublisher = MockCategoryEventPublisher()
        mockRouter = AppRouter()
    }
    
    override func tearDown() {
        viewModel = nil
        mockCreateCategoryUseCase = nil
        mockCreateSubCategoryUseCase = nil
        mockUpdateCategoryUseCase = nil
        mockCategoryEventPublisher = nil
        mockRouter = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createViewModel(
        mode: CategoryListMode = .configuration,
        selectedTransactionType: TransactionType = .income,
        selectedCategory: CategoryDTO? = nil
    ) -> CategoryFormViewModel {
        return CategoryFormViewModel(
            createCategoryUseCase: mockCreateCategoryUseCase,
            createSubCategoryUseCase: mockCreateSubCategoryUseCase,
            updateCategoryUseCase: mockUpdateCategoryUseCase,
            categoryEventPublisher: mockCategoryEventPublisher,
            mode: mode,
            selectedTransactionType: selectedTransactionType,
            selectedCategory: selectedCategory
        )
    }
    
    // MARK: - Test Methods - Initialization
    
    func test_initialization_configurationMode_createMode_setsCorrectInitialValues() {
        // When
        viewModel = createViewModel(mode: .configuration, selectedTransactionType: .variableExpense)
        
        // Then
        XCTAssertEqual(viewModel.mode, .configuration)
        XCTAssertEqual(viewModel.selectedTransactionType, .variableExpense)
        XCTAssertNil(viewModel.selectedCategory)
        XCTAssertEqual(viewModel.categoryName, "")
        XCTAssertEqual(viewModel.categoryIconName, "")
        XCTAssertEqual(viewModel.newSubCategoryName, "")
        XCTAssertTrue(viewModel.subCategories.isEmpty)
        XCTAssertTrue(viewModel.addedSubCategories.isEmpty)
        XCTAssertFalse(viewModel.showingAddSubCategoryAlert)
        XCTAssertNil(viewModel.alertErrorMessage)
        XCTAssertFalse(viewModel.isChanged)
    }
    
    func test_initialization_configurationMode_updateMode_setsCorrectInitialValues() {
        // Given
        let existingCategory = CategoryDTO(
            name: "기존 카테고리",
            iconName: "existing.icon",
            transactionType: .fixedExpense,
            subCategories: [SubCategoryDTO.mockSalary]
        )
        
        // When
        viewModel = createViewModel(mode: .configuration, selectedCategory: existingCategory)
        
        // Then
        XCTAssertEqual(viewModel.mode, .configuration)
        XCTAssertEqual(viewModel.selectedTransactionType, .fixedExpense)
        XCTAssertEqual(viewModel.selectedCategory?.id, existingCategory.id)
        XCTAssertEqual(viewModel.categoryName, "기존 카테고리")
        XCTAssertEqual(viewModel.categoryIconName, "existing.icon")
        XCTAssertEqual(viewModel.subCategories.count, 1)
        XCTAssertEqual(viewModel.subCategories.first?.id, SubCategoryDTO.mockSalary.id)
    }
    
    func test_initialization_selectionMode_setsCorrectInitialValues() {
        // When
        viewModel = createViewModel(mode: .selection, selectedTransactionType: .income)
        
        // Then
        XCTAssertEqual(viewModel.mode, .selection)
        XCTAssertEqual(viewModel.selectedTransactionType, .income)
        XCTAssertNil(viewModel.selectedCategory)
    }
    
    // MARK: - Test Methods - Validation - Configuration Mode
    
    func test_isValid_configurationMode_createMode_withValidData_returnsTrue() {
        // Given
        viewModel = createViewModel(mode: .configuration)
        viewModel.categoryName = "새 카테고리"
        viewModel.categoryIconName = "new.icon"
        
        // When
        let isValid = viewModel.isValid
        
        // Then
        XCTAssertTrue(isValid)
    }
    
    func test_isValid_configurationMode_createMode_withEmptyName_returnsFalse() {
        // Given
        viewModel = createViewModel(mode: .configuration)
        viewModel.categoryName = ""
        viewModel.categoryIconName = "new.icon"
        
        // When
        let isValid = viewModel.isValid
        
        // Then
        XCTAssertFalse(isValid)
    }
    
    func test_isValid_configurationMode_createMode_withWhitespaceOnlyName_returnsFalse() {
        // Given
        viewModel = createViewModel(mode: .configuration)
        viewModel.categoryName = "   \n\t   "
        viewModel.categoryIconName = "new.icon"
        
        // When
        let isValid = viewModel.isValid
        
        // Then
        XCTAssertFalse(isValid)
    }
    
    func test_isValid_configurationMode_createMode_withEmptyIcon_returnsFalse() {
        // Given
        viewModel = createViewModel(mode: .configuration)
        viewModel.categoryName = "새 카테고리"
        viewModel.categoryIconName = ""
        
        // When
        let isValid = viewModel.isValid
        
        // Then
        XCTAssertFalse(isValid)
    }
    
    func test_isValid_configurationMode_updateMode_withoutChanges_returnsFalse() {
        // Given
        let existingCategory = CategoryDTO(
            name: "기존 카테고리",
            iconName: "existing.icon",
            transactionType: .income
        )
        viewModel = createViewModel(mode: .configuration, selectedCategory: existingCategory)
        
        // When - 변경사항 없음
        let isValid = viewModel.isValid
        
        // Then
        XCTAssertFalse(isValid)
    }
    
    func test_isValid_configurationMode_updateMode_withNameChange_returnsTrue() {
        // Given
        let existingCategory = CategoryDTO(
            name: "기존 카테고리",
            iconName: "existing.icon",
            transactionType: .income
        )
        viewModel = createViewModel(mode: .configuration, selectedCategory: existingCategory)
        
        // When - 이름 변경
        viewModel.categoryName = "변경된 카테고리"
        let isValid = viewModel.isValid
        
        // Then
        XCTAssertTrue(isValid)
    }
    
    func test_isValid_configurationMode_updateMode_withIconChange_returnsTrue() {
        // Given
        let existingCategory = CategoryDTO(
            name: "기존 카테고리",
            iconName: "existing.icon",
            transactionType: .income
        )
        viewModel = createViewModel(mode: .configuration, selectedCategory: existingCategory)
        
        // When - 아이콘 변경
        viewModel.categoryIconName = "new.icon"
        let isValid = viewModel.isValid
        
        // Then
        XCTAssertTrue(isValid)
    }
    
    func test_isValid_configurationMode_updateMode_withTransactionTypeChange_returnsTrue() {
        // Given
        let existingCategory = CategoryDTO(
            name: "기존 카테고리",
            iconName: "existing.icon",
            transactionType: .income
        )
        viewModel = createViewModel(mode: .configuration, selectedCategory: existingCategory)
        
        // When - 거래 유형 변경
        viewModel.selectedTransactionType = .variableExpense
        let isValid = viewModel.isValid
        
        // Then
        XCTAssertTrue(isValid)
    }
    
    func test_isValid_configurationMode_updateMode_withAddedSubCategory_returnsTrue() {
        // Given
        let existingCategory = CategoryDTO(
            name: "기존 카테고리",
            iconName: "existing.icon",
            transactionType: .income
        )
        viewModel = createViewModel(mode: .configuration, selectedCategory: existingCategory)
        
        // When - 서브카테고리 추가
        viewModel.addedSubCategories = [SubCategoryDTO.mockSalary]
        let isValid = viewModel.isValid
        
        // Then
        XCTAssertTrue(isValid)
    }
    
    // MARK: - Test Methods - Validation - Selection Mode
    
    func test_isValid_selectionMode_withValidData_returnsTrue() {
        // Given
        viewModel = createViewModel(mode: .selection)
        viewModel.categoryName = "새 카테고리"
        viewModel.categoryIconName = "new.icon"
        viewModel.newSubCategoryName = "새 서브카테고리"
        
        // When
        let isValid = viewModel.isValid
        
        // Then
        XCTAssertTrue(isValid)
    }
    
    func test_isValid_selectionMode_withEmptySubCategoryName_returnsFalse() {
        // Given
        viewModel = createViewModel(mode: .selection)
        viewModel.categoryName = "새 카테고리"
        viewModel.categoryIconName = "new.icon"
        viewModel.newSubCategoryName = ""
        
        // When
        let isValid = viewModel.isValid
        
        // Then
        XCTAssertFalse(isValid)
    }
    
    func test_isValid_selectionMode_withWhitespaceOnlySubCategoryName_returnsFalse() {
        // Given
        viewModel = createViewModel(mode: .selection)
        viewModel.categoryName = "새 카테고리"
        viewModel.categoryIconName = "new.icon"
        viewModel.newSubCategoryName = "   \t\n   "
        
        // When
        let isValid = viewModel.isValid
        
        // Then
        XCTAssertFalse(isValid)
    }
    
    // MARK: - Test Methods - Action Handling - showAddSubCategoryAlert
    
    func test_showAddSubCategoryAlert_setsShowingAddSubCategoryAlertToTrue() {
        // Given
        viewModel = createViewModel(mode: .configuration)
        XCTAssertFalse(viewModel.showingAddSubCategoryAlert)
        
        // When
        viewModel.send(.showAddSubCategoryAlert)
        
        // Then
        XCTAssertTrue(viewModel.showingAddSubCategoryAlert)
    }
    
    // MARK: - Test Methods - Action Handling - addSubCategory
    
    func test_addSubCategory_withValidName_addsSubCategory() {
        // Given
        viewModel = createViewModel(mode: .configuration)
        viewModel.categoryName = "테스트 카테고리"
        viewModel.categoryIconName = "test.icon"
        viewModel.selectedTransactionType = .variableExpense
        viewModel.newSubCategoryName = "새 서브카테고리"
        
        // When
        viewModel.send(.addSubCategory)
        
        // Then
        XCTAssertEqual(viewModel.addedSubCategories.count, 1)
        XCTAssertEqual(viewModel.addedSubCategories.first?.name, "새 서브카테고리")
        XCTAssertEqual(viewModel.addedSubCategories.first?.transactionType, .variableExpense)
        XCTAssertEqual(viewModel.addedSubCategories.first?.categoryName, "테스트 카테고리")
        XCTAssertEqual(viewModel.addedSubCategories.first?.categoryIconName, "test.icon")
        XCTAssertEqual(viewModel.newSubCategoryName, "") // 입력 필드 초기화
        XCTAssertFalse(viewModel.showingAddSubCategoryAlert) // Alert 닫힘
    }
    
    func test_addSubCategory_withEmptyName_setsErrorMessage() {
        // Given
        viewModel = createViewModel(mode: .configuration)
        viewModel.newSubCategoryName = ""
        
        // When
        viewModel.send(.addSubCategory)

        // Then
        XCTAssertTrue(viewModel.addedSubCategories.isEmpty)
        XCTAssertNotNil(viewModel.alertErrorMessage)
    }
    
    func test_addSubCategory_withWhitespaceOnlyName_setsErrorMessage() {
        // Given
        viewModel = createViewModel(mode: .configuration)
        viewModel.newSubCategoryName = "   \n\t   "
        
        // When
        viewModel.send(.addSubCategory)
        
        // Then
        XCTAssertTrue(viewModel.addedSubCategories.isEmpty)
        XCTAssertNotNil(viewModel.alertErrorMessage)
    }
    
    func test_addSubCategory_withDuplicateName_setsErrorMessage() {
        // Given
        let existingSubCategory = SubCategoryDTO(
            name: "기존 서브카테고리",
            transactionType: .variableExpense,
            categoryId: UUID(),
            categoryName: "테스트 카테고리",
            categoryIconName: "test.icon"
        )
        let existingCategory = CategoryDTO(
            name: "테스트 카테고리",
            iconName: "test.icon",
            transactionType: .variableExpense,
            subCategories: [existingSubCategory]
        )
        
        viewModel = createViewModel(mode: .configuration, selectedCategory: existingCategory)
        viewModel.newSubCategoryName = "기존 서브카테고리" // 중복된 이름
        
        // When
        viewModel.send(.addSubCategory)
        
        // Then
        XCTAssertTrue(viewModel.addedSubCategories.isEmpty)
        XCTAssertNotNil(viewModel.alertErrorMessage)
    }
    
    // MARK: - Test Methods - Action Handling - cancelAddSubCategory
    
    func test_cancelAddSubCategory_resetsAlertState() {
        // Given
        viewModel = createViewModel(mode: .configuration)
        viewModel.showingAddSubCategoryAlert = true
        viewModel.newSubCategoryName = "입력된 이름"
        viewModel.alertErrorMessage = "에러 메시지"
        
        // When
        viewModel.send(.cancelAddSubCategory)
        
        // Then
        XCTAssertFalse(viewModel.showingAddSubCategoryAlert)
        XCTAssertEqual(viewModel.newSubCategoryName, "")
        XCTAssertNil(viewModel.alertErrorMessage)
    }
    
    // MARK: - Test Methods - Data Integrity
    
    func test_addedSubCategories_maintainCorrectCategoryReference() {
        // Given
        viewModel = createViewModel(mode: .configuration)
        viewModel.categoryName = "부모 카테고리"
        viewModel.categoryIconName = "parent.icon"
        viewModel.selectedTransactionType = .income
        
        // When
        viewModel.newSubCategoryName = "첫번째 서브카테고리"
        viewModel.send(.addSubCategory)
        
        viewModel.newSubCategoryName = "두번째 서브카테고리"
        viewModel.send(.addSubCategory)
        
        // Then
        XCTAssertEqual(viewModel.addedSubCategories.count, 2)
        
        for subCategory in viewModel.addedSubCategories {
            XCTAssertEqual(subCategory.categoryName, "부모 카테고리")
            XCTAssertEqual(subCategory.categoryIconName, "parent.icon")
            XCTAssertEqual(subCategory.transactionType, .income)
        }
        
        XCTAssertEqual(viewModel.addedSubCategories[0].name, "첫번째 서브카테고리")
        XCTAssertEqual(viewModel.addedSubCategories[1].name, "두번째 서브카테고리")
    }
    
    // MARK: - Test Methods - Different Transaction Types
    
    func test_validation_withDifferentTransactionTypes_worksCorrectly() {
        // Test Income
        viewModel = createViewModel(mode: .configuration, selectedTransactionType: .income)
        viewModel.categoryName = "수입 카테고리"
        viewModel.categoryIconName = "income.icon"
        XCTAssertTrue(viewModel.isValid)
        
        // Test Fixed Expense
        viewModel = createViewModel(mode: .configuration, selectedTransactionType: .fixedExpense)
        viewModel.categoryName = "고정비 카테고리"
        viewModel.categoryIconName = "fixed.icon"
        XCTAssertTrue(viewModel.isValid)
        
        // Test Variable Expense
        viewModel = createViewModel(mode: .configuration, selectedTransactionType: .variableExpense)
        viewModel.categoryName = "변동비 카테고리"
        viewModel.categoryIconName = "variable.icon"
        XCTAssertTrue(viewModel.isValid)
    }
    
    func test_addSubCategory_withDifferentTransactionTypes_setsCorrectTransactionType() {
        // Test Income
        viewModel = createViewModel(mode: .configuration, selectedTransactionType: .income)
        viewModel.categoryName = "수입 카테고리"
        viewModel.categoryIconName = "income.icon"
        viewModel.newSubCategoryName = "수입 서브카테고리"
        viewModel.send(.addSubCategory)
        
        XCTAssertEqual(viewModel.addedSubCategories.first?.transactionType, .income)
        
        // Test Variable Expense
        viewModel = createViewModel(mode: .configuration, selectedTransactionType: .variableExpense)
        viewModel.categoryName = "변동비 카테고리"
        viewModel.categoryIconName = "variable.icon"
        viewModel.newSubCategoryName = "변동비 서브카테고리"
        viewModel.send(.addSubCategory)
        
        XCTAssertEqual(viewModel.addedSubCategories.first?.transactionType, .variableExpense)
    }
}
