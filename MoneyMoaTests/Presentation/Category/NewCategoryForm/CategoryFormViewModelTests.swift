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
    private var mockDeleteCategoryUseCase: MockDeleteCategoryUseCase!
    private var mockCategoryEventPublisher: MockCategoryEventPublisher!
    private var mockRouter: AppRouter!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()

        mockCreateCategoryUseCase = MockCreateCategoryUseCase()
        mockCreateSubCategoryUseCase = MockCreateSubCategoryUseCase()
        mockUpdateCategoryUseCase = MockUpdateCategoryUseCase()
        mockDeleteCategoryUseCase = MockDeleteCategoryUseCase()
        mockCategoryEventPublisher = MockCategoryEventPublisher()
        mockRouter = AppRouter()
    }

    override func tearDown() {
        viewModel = nil
        mockCreateCategoryUseCase = nil
        mockCreateSubCategoryUseCase = nil
        mockUpdateCategoryUseCase = nil
        mockDeleteCategoryUseCase = nil
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
            deleteCategoryUseCase: mockDeleteCategoryUseCase,
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

    // MARK: - Test Methods - Validation

    func test_isValid_createMode_validatesCorrectly() {
        viewModel = createViewModel(mode: .configuration)

        // Invalid: 빈 이름
        viewModel.categoryName = ""
        viewModel.categoryIconName = "icon"
        XCTAssertFalse(viewModel.isValid)

        // Invalid: 공백만 있는 이름
        viewModel.categoryName = "   \n\t   "
        XCTAssertFalse(viewModel.isValid)

        // Invalid: 빈 아이콘
        viewModel.categoryName = "카테고리"
        viewModel.categoryIconName = ""
        XCTAssertFalse(viewModel.isValid)

        // Valid: 모든 필드 입력
        viewModel.categoryIconName = "icon"
        XCTAssertTrue(viewModel.isValid)
    }

    func test_isValid_updateMode_validatesChanges() {
        let existingCategory = CategoryDTO(name: "기존", iconName: "icon", transactionType: .income)
        viewModel = createViewModel(mode: .configuration, selectedCategory: existingCategory)

        // Invalid: 변경사항 없음
        XCTAssertFalse(viewModel.isValid)

        // Valid: 이름 변경
        viewModel.categoryName = "변경됨"
        XCTAssertTrue(viewModel.isValid)

        // Valid: 아이콘 변경
        viewModel.categoryName = "기존"
        viewModel.categoryIconName = "new.icon"
        XCTAssertTrue(viewModel.isValid)

        // Valid: 거래 유형 변경
        viewModel.categoryIconName = "icon"
        viewModel.selectedTransactionType = .variableExpense
        XCTAssertTrue(viewModel.isValid)

        // Valid: 서브카테고리 추가
        viewModel.selectedTransactionType = .income
        viewModel.addedSubCategories = [SubCategoryDTO.mockSalary]
        XCTAssertTrue(viewModel.isValid)
    }

    func test_isValid_selectionMode_requiresSubCategory() {
        viewModel = createViewModel(mode: .selection)
        viewModel.categoryName = "카테고리"
        viewModel.categoryIconName = "icon"

        // Invalid: 서브카테고리 없음
        viewModel.newSubCategoryName = ""
        XCTAssertFalse(viewModel.isValid)

        // Invalid: 공백만
        viewModel.newSubCategoryName = "   \t\n   "
        XCTAssertFalse(viewModel.isValid)

        // Valid: 서브카테고리 입력
        viewModel.newSubCategoryName = "서브카테고리"
        XCTAssertTrue(viewModel.isValid)
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

    func test_addSubCategory_validation() {
        viewModel = createViewModel(mode: .configuration)

        // Invalid: 빈 이름
        viewModel.newSubCategoryName = ""
        viewModel.send(.addSubCategory)
        XCTAssertTrue(viewModel.addedSubCategories.isEmpty)
        XCTAssertNotNil(viewModel.alertErrorMessage)

        // Invalid: 공백만
        viewModel.newSubCategoryName = "   \n\t   "
        viewModel.send(.addSubCategory)
        XCTAssertTrue(viewModel.addedSubCategories.isEmpty)

        // Invalid: 중복 이름
        let existingCategory = CategoryDTO(
            name: "카테고리",
            iconName: "icon",
            transactionType: .variableExpense,
            subCategories: [SubCategoryDTO(name: "기존", transactionType: .variableExpense, categoryId: UUID(), categoryName: "카테고리", categoryIconName: "icon")]
        )
        viewModel = createViewModel(mode: .configuration, selectedCategory: existingCategory)
        viewModel.newSubCategoryName = "기존"
        viewModel.send(.addSubCategory)
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

    // MARK: - Test Methods - Transaction Type Handling

    func test_transactionType_propagatesToSubCategories() {
        // Income
        viewModel = createViewModel(mode: .configuration, selectedTransactionType: .income)
        viewModel.categoryName = "카테고리"
        viewModel.categoryIconName = "icon"
        viewModel.newSubCategoryName = "서브카테고리"
        viewModel.send(.addSubCategory)
        XCTAssertEqual(viewModel.addedSubCategories.first?.transactionType, .income)

        // Variable Expense
        viewModel = createViewModel(mode: .configuration, selectedTransactionType: .variableExpense)
        viewModel.categoryName = "카테고리"
        viewModel.categoryIconName = "icon"
        viewModel.newSubCategoryName = "서브카테고리"
        viewModel.send(.addSubCategory)
        XCTAssertEqual(viewModel.addedSubCategories.first?.transactionType, .variableExpense)
    }

    // MARK: - Test Methods - Delete Category

    func test_deleteCategory_callsDeleteUseCaseWithCorrectId() async {
        // Given: 수정 모드로 설정된 ViewModel
        let category = CategoryDTO.mockFood
        viewModel = createViewModel(mode: .configuration, selectedCategory: category)

        // When: 카테고리 삭제
        viewModel.send(.deleteCategory(mockRouter))

        // Then: DeleteCategoryUseCase가 올바른 ID로 호출됨
        try? await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(mockDeleteCategoryUseCase.executeCallCount, 1)
        XCTAssertEqual(mockDeleteCategoryUseCase.lastDeletedCategoryId, category.id)
    }

    func test_deleteCategory_publishesDeleteEvent() async {
        // Given: 수정 모드로 설정된 ViewModel
        let category = CategoryDTO.mockFood
        viewModel = createViewModel(mode: .configuration, selectedCategory: category)

        // When: 카테고리 삭제
        viewModel.send(.deleteCategory(mockRouter))

        // Then: 삭제 이벤트가 발행됨
        try? await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(mockCategoryEventPublisher.publishCallCount, 1)
        XCTAssertEqual(mockCategoryEventPublisher.lastEvent?.type, .deleted)
        XCTAssertEqual(mockCategoryEventPublisher.lastEvent?.category.id, category.id)
    }

    func test_showDeleteConfirmation_setsShowingDeleteConfirmationToTrue() {
        // Given: ViewModel 생성
        viewModel = createViewModel()

        // When: 삭제 확인 표시
        viewModel.send(.showDeleteConfirmation)

        // Then: showingDeleteConfirmation이 true로 설정됨
        XCTAssertTrue(viewModel.showingDeleteConfirmation)
    }
}
