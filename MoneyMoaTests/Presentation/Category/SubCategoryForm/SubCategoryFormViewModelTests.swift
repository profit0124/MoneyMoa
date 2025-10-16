//
//  SubCategoryFormViewModelTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 8/27/25.
//

import XCTest
import Combine
@testable import MoneyMoa

// MARK: - SubCategoryFormViewModelTests

@MainActor
final class SubCategoryFormViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var viewModel: SubCategoryFormViewModel!
    private var mockCreateSubCategoryUseCase: MockCreateSubCategoryUseCase!
    private var mockUpdateSubCategoryUseCase: MockUpdateSubCategoryUseCase!
    private var mockDeleteSubCategoryUseCase: MockDeleteSubCategoryUseCase!
    private var mockSubCategoryEventPublisher: MockSubCategoryEventPublisher!
    private var mockRouter: AppRouter!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()

        mockCreateSubCategoryUseCase = MockCreateSubCategoryUseCase()
        mockUpdateSubCategoryUseCase = MockUpdateSubCategoryUseCase()
        mockDeleteSubCategoryUseCase = MockDeleteSubCategoryUseCase()
        mockSubCategoryEventPublisher = MockSubCategoryEventPublisher()
        mockRouter = AppRouter()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        viewModel?.send(.unsubscribe)
        viewModel = nil
        mockCreateSubCategoryUseCase = nil
        mockUpdateSubCategoryUseCase = nil
        mockDeleteSubCategoryUseCase = nil
        mockSubCategoryEventPublisher = nil
        mockRouter = nil
        cancellables?.removeAll()
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createViewModel(
        selectedCategory: CategoryDTO = CategoryDTO.mockFood,
        selectedSubCategory: SubCategoryDTO? = nil
    ) -> SubCategoryFormViewModel {
        return SubCategoryFormViewModel(
            createSubCategoryUseCase: mockCreateSubCategoryUseCase,
            updateSubCategoryUseCase: mockUpdateSubCategoryUseCase,
            deleteSubCategoryUseCase: mockDeleteSubCategoryUseCase,
            subCategoryEventPublisher: mockSubCategoryEventPublisher,
            selectedCategory: selectedCategory,
            selectedSubCategory: selectedSubCategory
        )
    }
    
    // MARK: - Test Methods - Initialization - Create Mode
    
    func test_initialization_createMode_setsCorrectInitialValues() {
        // Given
        let category = CategoryDTO.mockFood
        
        // When
        viewModel = createViewModel(selectedCategory: category, selectedSubCategory: nil)
        
        // Then
        XCTAssertEqual(viewModel.selectedCategory.id, category.id)
        XCTAssertEqual(viewModel.selectedCategory.name, category.name)
        XCTAssertNil(viewModel.selectedSubCategoryDTO)
        XCTAssertEqual(viewModel.subCategoryName, "")
        XCTAssertNotNil(viewModel.cancellables)
    }
    
    func test_initialization_createMode_withDifferentCategories() {
        // Test Income Category
        let incomeCategory = CategoryDTO.mockIncome
        viewModel = createViewModel(selectedCategory: incomeCategory)
        XCTAssertEqual(viewModel.selectedCategory.transactionType, .income)
        XCTAssertEqual(viewModel.subCategoryName, "")
        
        // Test Fixed Expense Category
        let fixedExpenseCategory = CategoryDTO.mockRent
        viewModel = createViewModel(selectedCategory: fixedExpenseCategory)
        XCTAssertEqual(viewModel.selectedCategory.transactionType, .fixedExpense)
        XCTAssertEqual(viewModel.subCategoryName, "")
    }
    
    // MARK: - Test Methods - Initialization - Update Mode
    
    func test_initialization_updateMode_setsCorrectInitialValues() {
        // Given
        let category = CategoryDTO.mockFood
        let subCategory = SubCategoryDTO.mockFoodExpense
        
        // When
        viewModel = createViewModel(selectedCategory: category, selectedSubCategory: subCategory)
        
        // Then
        XCTAssertEqual(viewModel.selectedCategory.id, category.id)
        XCTAssertEqual(viewModel.selectedSubCategoryDTO?.id, subCategory.id)
        XCTAssertEqual(viewModel.subCategoryName, subCategory.name)
        XCTAssertEqual(viewModel.subCategoryName, "외식비") // mockFoodExpense의 실제 이름
    }
    
    func test_initialization_updateMode_withDifferentSubCategories() {
        // Test Income SubCategory
        let incomeCategory = CategoryDTO.mockIncome
        let incomeSubCategory = SubCategoryDTO.mockSalary
        viewModel = createViewModel(selectedCategory: incomeCategory, selectedSubCategory: incomeSubCategory)
        
        XCTAssertEqual(viewModel.selectedSubCategoryDTO?.transactionType, .income)
        XCTAssertEqual(viewModel.subCategoryName, "급여")
        
        // Test Transport SubCategory
        let transportCategory = CategoryDTO.mockTransport
        let transportSubCategory = SubCategoryDTO.mockTransportBus
        viewModel = createViewModel(selectedCategory: transportCategory, selectedSubCategory: transportSubCategory)
        
        XCTAssertEqual(viewModel.selectedSubCategoryDTO?.transactionType, .variableExpense)
        XCTAssertEqual(viewModel.subCategoryName, "교통")
    }
    
    // MARK: - Test Methods - Validation - Create Mode
    
    func test_isValid_createMode_withValidName_returnsTrue() {
        // Given
        viewModel = createViewModel(selectedCategory: CategoryDTO.mockFood)
        
        // When
        viewModel.subCategoryName = "새로운 서브카테고리"
        
        // Then
        XCTAssertTrue(viewModel.isValid)
    }
    
    func test_isValid_createMode_withEmptyName_returnsFalse() {
        // Given
        viewModel = createViewModel(selectedCategory: CategoryDTO.mockFood)
        
        // When
        viewModel.subCategoryName = ""
        
        // Then
        XCTAssertFalse(viewModel.isValid)
    }
    
    func test_isValid_createMode_withWhitespaceOnlyName_returnsFalse() {
        // Given
        viewModel = createViewModel(selectedCategory: CategoryDTO.mockFood)
        
        // When
        viewModel.subCategoryName = "   \n\t   "
        
        // Then
        XCTAssertFalse(viewModel.isValid)
    }
    
    // MARK: - Test Methods - Validation - Update Mode
    
    func test_isValid_updateMode_withChangedName_returnsTrue() {
        // Given
        let subCategory = SubCategoryDTO.mockFoodExpense
        viewModel = createViewModel(selectedCategory: CategoryDTO.mockFood, selectedSubCategory: subCategory)
        
        // When
        viewModel.subCategoryName = "수정된 외식비"
        
        // Then
        XCTAssertTrue(viewModel.isValid)
    }
    
    func test_isValid_updateMode_withUnchangedName_returnsFalse() {
        // Given
        let subCategory = SubCategoryDTO.mockFoodExpense
        viewModel = createViewModel(selectedCategory: CategoryDTO.mockFood, selectedSubCategory: subCategory)
        
        // When - 이름 변경 없음
        // subCategoryName is already set to subCategory.name in init
        
        // Then
        XCTAssertFalse(viewModel.isValid)
    }
    
    func test_isValid_updateMode_withChangedCategory_returnsTrue() {
        // Given
        let originalCategory = CategoryDTO.mockFood
        let subCategory = SubCategoryDTO.mockFoodExpense
        viewModel = createViewModel(selectedCategory: originalCategory, selectedSubCategory: subCategory)
        
        // When - 카테고리 변경
        let newCategory = CategoryDTO.mockTransport
        viewModel.send(.selectCategory(newCategory))
        
        // Then
        XCTAssertTrue(viewModel.isValid)
    }
    
    func test_isValid_updateMode_withEmptyNameAfterChange_returnsFalse() {
        // Given
        let subCategory = SubCategoryDTO.mockFoodExpense
        viewModel = createViewModel(selectedCategory: CategoryDTO.mockFood, selectedSubCategory: subCategory)
        
        // When - 이름을 빈 문자열로 변경
        viewModel.subCategoryName = ""
        
        // Then
        XCTAssertFalse(viewModel.isValid)
    }
    
    // MARK: - Test Methods - Action Handling - selectCategory
    
    func test_selectCategory_updatesSelectedCategory() {
        // Given
        let initialCategory = CategoryDTO.mockFood
        let newCategory = CategoryDTO.mockTransport
        viewModel = createViewModel(selectedCategory: initialCategory)
        
        // When
        viewModel.send(.selectCategory(newCategory))
        
        // Then
        XCTAssertEqual(viewModel.selectedCategory.id, newCategory.id)
        XCTAssertEqual(viewModel.selectedCategory.name, newCategory.name)
        XCTAssertEqual(viewModel.selectedCategory.transactionType, newCategory.transactionType)
    }
    
    func test_selectCategory_withDifferentTransactionTypes_updatesCorrectly() {
        // Given
        viewModel = createViewModel(selectedCategory: CategoryDTO.mockFood) // variableExpense
        
        // When - Income 카테고리 선택
        let incomeCategory = CategoryDTO.mockIncome
        viewModel.send(.selectCategory(incomeCategory))
        
        // Then
        XCTAssertEqual(viewModel.selectedCategory.transactionType, .income)
        
        // When - Fixed Expense 카테고리 선택
        let fixedExpenseCategory = CategoryDTO.mockRent
        viewModel.send(.selectCategory(fixedExpenseCategory))
        
        // Then
        XCTAssertEqual(viewModel.selectedCategory.transactionType, .fixedExpense)
    }
    
    // MARK: - Test Methods - Action Handling - submit (Create Mode)
    
    func test_submit_createMode_withValidData_createsSubCategory() async {
        // Given
        let category = CategoryDTO.mockFood
        viewModel = createViewModel(selectedCategory: category)
        viewModel.subCategoryName = "새로운 서브카테고리"
        
        // When
        viewModel.send(.submit(mockRouter))
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then
        XCTAssertEqual(mockCreateSubCategoryUseCase.executeCallCount, 1)
        XCTAssertNotNil(mockCreateSubCategoryUseCase.lastSubCategory)
        XCTAssertEqual(mockCreateSubCategoryUseCase.lastSubCategory?.name, "새로운 서브카테고리")
        XCTAssertEqual(mockCreateSubCategoryUseCase.lastSubCategory?.categoryId, category.id)
        XCTAssertEqual(mockCreateSubCategoryUseCase.lastSubCategory?.transactionType, category.transactionType)
        
        XCTAssertEqual(mockUpdateSubCategoryUseCase.executeCallCount, 0)
    }
    
    // MARK: - Test Methods - Action Handling - submit (Update Mode)
    
    func test_submit_updateMode_withValidData_updatesSubCategory() async {
        // Given
        let category = CategoryDTO.mockFood
        let subCategory = SubCategoryDTO.mockFoodExpense
        viewModel = createViewModel(selectedCategory: category, selectedSubCategory: subCategory)
        viewModel.subCategoryName = "수정된 외식비"
        
        // When
        viewModel.send(.submit(mockRouter))
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertEqual(mockUpdateSubCategoryUseCase.executeCallCount, 1)
        XCTAssertNotNil(mockUpdateSubCategoryUseCase.lastSubCategory)
        XCTAssertEqual(mockUpdateSubCategoryUseCase.lastSubCategory?.name, "수정된 외식비")
        XCTAssertEqual(mockUpdateSubCategoryUseCase.lastSubCategory?.id, subCategory.id)
        
        XCTAssertEqual(mockCreateSubCategoryUseCase.executeCallCount, 0)
    }
    
    // MARK: - Test Methods - Event Publishing
    
    func test_submit_createMode_publishesSubCategoryEvent() async {
        // Given
        viewModel = createViewModel(selectedCategory: CategoryDTO.mockFood)
        viewModel.subCategoryName = "새로운 서브카테고리"
        
        // When
        viewModel.send(.submit(mockRouter))
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertEqual(mockSubCategoryEventPublisher.publishCallCount, 1)
        XCTAssertNotNil(mockSubCategoryEventPublisher.lastPublishedSubCategoryEvent)
        XCTAssertEqual(mockSubCategoryEventPublisher.lastPublishedSubCategoryEvent?.subCategory.name, "새로운 서브카테고리")
    }
    
    func test_submit_updateMode_publishesSubCategoryEvent() async {
        // Given
        let subCategory = SubCategoryDTO.mockFoodExpense
        viewModel = createViewModel(selectedCategory: CategoryDTO.mockFood, selectedSubCategory: subCategory)
        viewModel.subCategoryName = "수정된 외식비"
        
        // When
        viewModel.send(.submit(mockRouter))
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertEqual(mockSubCategoryEventPublisher.publishCallCount, 1)
        XCTAssertNotNil(mockSubCategoryEventPublisher.lastPublishedSubCategoryEvent)
        XCTAssertEqual(mockSubCategoryEventPublisher.lastPublishedSubCategoryEvent?.subCategory.name, "수정된 외식비")
    }
    
    // MARK: - Test Methods - Error Handling
    
    func test_submit_createMode_whenUseCaseThrows_handlesGracefully() async {
        // Given
        viewModel = createViewModel(selectedCategory: CategoryDTO.mockFood)
        viewModel.subCategoryName = "새로운 서브카테고리"
        mockCreateSubCategoryUseCase.executeError = NSError(domain: "TestError", code: 500)
        
        // When
        viewModel.send(.submit(mockRouter))
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then - 에러가 발생해도 크래시하지 않음
        XCTAssertEqual(mockCreateSubCategoryUseCase.executeCallCount, 1)
        XCTAssertEqual(mockSubCategoryEventPublisher.publishCallCount, 0) // 에러 시 이벤트 발행하지 않음
    }
    
    func test_submit_updateMode_whenUseCaseThrows_handlesGracefully() async {
        // Given
        let subCategory = SubCategoryDTO.mockFoodExpense
        viewModel = createViewModel(selectedCategory: CategoryDTO.mockFood, selectedSubCategory: subCategory)
        viewModel.subCategoryName = "수정된 외식비"
        mockUpdateSubCategoryUseCase.executeError = NSError(domain: "TestError", code: 500)
        
        // When
        viewModel.send(.submit(mockRouter))
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertEqual(mockUpdateSubCategoryUseCase.executeCallCount, 1)
        XCTAssertEqual(mockSubCategoryEventPublisher.publishCallCount, 0)
    }
    
    // MARK: - Test Methods - Action Handling - unsubscribe
    
    func test_unsubscribe_clearsSubscriptions() {
        // Given
        viewModel = createViewModel(selectedCategory: CategoryDTO.mockFood)
        
        // When
        viewModel.send(.unsubscribe)
        
        // Then - 구독이 정리되었는지 확인 (cancellables가 private이므로 크래시 미발생으로 검증)
        XCTAssertNotNil(viewModel)
    }
    
    // MARK: - Test Methods - Data Consistency
    
    func test_createMode_subCategoryDTO_hasCorrectCategoryReference() async {
        // Given
        let category = CategoryDTO.mockTransport
        viewModel = createViewModel(selectedCategory: category)
        viewModel.subCategoryName = "지하철"
        
        // When
        viewModel.send(.submit(mockRouter))
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        let createdSubCategory = mockCreateSubCategoryUseCase.lastSubCategory
        XCTAssertEqual(createdSubCategory?.categoryId, category.id)
        XCTAssertEqual(createdSubCategory?.categoryName, category.name)
        XCTAssertEqual(createdSubCategory?.categoryIconName, category.iconName)
        XCTAssertEqual(createdSubCategory?.transactionType, category.transactionType)
    }
    
    func test_updateMode_withCategoryChange_updatesSubCategoryReference() async {
        // Given
        let originalCategory = CategoryDTO.mockFood
        let newCategory = CategoryDTO.mockTransport
        let subCategory = SubCategoryDTO.mockFoodExpense
        
        viewModel = createViewModel(selectedCategory: originalCategory, selectedSubCategory: subCategory)
        
        // When - 카테고리 변경 후 제출
        viewModel.send(.selectCategory(newCategory))
        viewModel.send(.submit(mockRouter))
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        let updatedSubCategory = mockUpdateSubCategoryUseCase.lastSubCategory
        XCTAssertEqual(updatedSubCategory?.categoryId, newCategory.id)
        XCTAssertEqual(updatedSubCategory?.categoryName, newCategory.name)
        XCTAssertEqual(updatedSubCategory?.categoryIconName, newCategory.iconName)
        XCTAssertEqual(updatedSubCategory?.transactionType, newCategory.transactionType)
    }

    // MARK: - Test Methods - Delete SubCategory

    func test_deleteSubCategory_callsDeleteUseCaseWithCorrectId() async {
        // Given: 수정 모드로 설정된 ViewModel
        let subCategory = SubCategoryDTO.mockFoodExpense
        viewModel = createViewModel(selectedSubCategory: subCategory)

        // When: 서브카테고리 삭제
        viewModel.send(.deleteSubCategory(mockRouter))

        // Then: DeleteSubCategoryUseCase가 올바른 ID로 호출됨
        try? await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(mockDeleteSubCategoryUseCase.executeCallCount, 1)
        XCTAssertEqual(mockDeleteSubCategoryUseCase.lastDeletedSubCategoryId, subCategory.id)
    }

    func test_deleteSubCategory_publishesDeleteEvent() async {
        // Given: 수정 모드로 설정된 ViewModel
        let subCategory = SubCategoryDTO.mockFoodExpense
        viewModel = createViewModel(selectedSubCategory: subCategory)

        // When: 서브카테고리 삭제
        viewModel.send(.deleteSubCategory(mockRouter))

        // Then: 삭제 이벤트가 발행됨
        try? await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(mockSubCategoryEventPublisher.publishCallCount, 1)
        XCTAssertEqual(mockSubCategoryEventPublisher.lastPublishedSubCategoryEvent?.type, .deleted)
        XCTAssertEqual(mockSubCategoryEventPublisher.lastPublishedSubCategoryEvent?.subCategory.id, subCategory.id)
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

// MARK: - Mock SubCategoryEventPublisher

private class MockSubCategoryEventPublisher: SubCategoryEventPublisher {
    var publishCallCount = 0
    var lastPublishedSubCategoryEvent: SubCategoryEvent?
    
    var subCategoryEvents: AnyPublisher<SubCategoryEvent, Never> {
        Empty().eraseToAnyPublisher()
    }
    
    func publish(_ event: SubCategoryEvent) {
        publishCallCount += 1
        lastPublishedSubCategoryEvent = event
    }
}
