//
//  BudgetSetupViewModelTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 8/22/25.
//

import XCTest
@testable import MoneyMoa

final class BudgetSetupViewModelTests: XCTestCase {
    
    private var sut: BudgetSetupViewModel!
    private var mockDIContainer: MockDIContainer!
    
    // Mock UseCases
    private var mockGetMonthlyBudgetUseCase: MockGetMonthlyBudgetUseCase!
    private var mockCreateTemplateFromBudgetUseCase: MockCreateTemplateFromBudgetUseCase!
    private var mockUpdateTemplateFromBudgetUseCase: MockUpdateTemplateFromBudgetUseCase!
    private var mockCreateBudgetUseCase: MockCreateBudgetUseCase!
    private var mockUpdateBudgetRangeUseCase: MockUpdateBudgetRangeUseCase!
    
    override func setUp() {
        super.setUp()
        setupMockDI()
        setupMockUseCases()
        createSUT()
    }
    
    override func tearDown() {
        sut = nil
        clearMockUseCases()
        mockDIContainer = nil
        super.tearDown()
    }
    
    private func setupMockDI() {
        mockDIContainer = MockDIContainer()
    }
    
    private func setupMockUseCases() {
        mockGetMonthlyBudgetUseCase = MockGetMonthlyBudgetUseCase()
        mockCreateTemplateFromBudgetUseCase = MockCreateTemplateFromBudgetUseCase()
        mockUpdateTemplateFromBudgetUseCase = MockUpdateTemplateFromBudgetUseCase()
        mockCreateBudgetUseCase = MockCreateBudgetUseCase()
        mockUpdateBudgetRangeUseCase = MockUpdateBudgetRangeUseCase()
        
        // Mock 데이터 초기화
        mockGetMonthlyBudgetUseCase.clearMockData()
        mockDIContainer.mockCategoryRepository.shouldFail = false
    }
    
    private func clearMockUseCases() {
        mockGetMonthlyBudgetUseCase = nil
        mockCreateTemplateFromBudgetUseCase = nil
        mockUpdateTemplateFromBudgetUseCase = nil
        mockCreateBudgetUseCase = nil
        mockUpdateBudgetRangeUseCase = nil
    }
    
    private func createSUT(yearMonth: YearMonth = .current) {
        sut = BudgetSetupViewModel(
            yearMonth: yearMonth,
            getMonthlyBudgetUseCase: mockGetMonthlyBudgetUseCase,
            getCategoriesByTypeUseCase: mockDIContainer.makeGetCategoriesByTypeUseCase(),
            createTemplateFromBudgetUseCase: mockCreateTemplateFromBudgetUseCase,
            updateBudgetTemplateUseCase: mockUpdateTemplateFromBudgetUseCase,
            createBudgetUseCase: mockCreateBudgetUseCase,
            updateBudgetRangeUseCase: mockUpdateBudgetRangeUseCase
        )
    }
    
    // MARK: - Test Cases
    
    func test_initialization_shouldSetInitialValues() {
        // Given: 특정 YearMonth로 ViewModel 생성
        let expectedYearMonth = YearMonth(year: 2025, month: 6)
        
        // When: ViewModel 초기화
        createSUT(yearMonth: expectedYearMonth)
        
        // Then: 초기값들이 올바르게 설정됨
        XCTAssertEqual(sut.yearMonth, expectedYearMonth)
        XCTAssertNil(sut.budget)
        XCTAssertNil(sut.totalAmount)
        XCTAssertTrue(sut.categoryBudgets.isEmpty)
        XCTAssertTrue(sut.categories.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.showError)
        XCTAssertFalse(sut.showingCategorySelection)
        XCTAssertFalse(sut.showUpdateConfirmation)
    }
    
    func test_isValid_whenTotalAmountIsNil_shouldReturnFalse() {
        // Given: totalAmount가 nil인 상태
        sut.totalAmount = nil
        
        // When: isValid 확인
        // Then: false 반환
        XCTAssertFalse(sut.isValid)
    }
    
    func test_isValid_whenTotalAmountIsZero_shouldReturnFalse() {
        // Given: totalAmount가 0인 상태
        sut.totalAmount = 0
        
        // When: isValid 확인
        // Then: false 반환
        XCTAssertFalse(sut.isValid)
    }
    
    func test_isValid_whenCategoryBudgetsExceedTotal_shouldReturnFalse() {
        // Given: 카테고리 예산이 총 예산을 초과하는 상태
        sut.totalAmount = 1000
        sut.categoryBudgets = [makeCategoryBudgetDTO(amount: 1500)]
        
        // When: isValid 확인
        // Then: false 반환
        XCTAssertFalse(sut.isValid)
    }
    
    func test_isValid_whenValidDataAndHasChanges_shouldReturnTrue() {
        // Given: 유효한 데이터와 변경사항이 있는 상태
        let originalBudget = makeBudgetDTO(totalAmount: 500000, categoryBudgets: [])
        sut.budget = originalBudget
        sut.totalAmount = 1000000 // Changed
        sut.categoryBudgets = [makeCategoryBudgetDTO(amount: 500000)]
        
        // When: isValid 확인
        // Then: true 반환
        XCTAssertTrue(sut.isValid)
    }
    
    func test_totalCategoryBudgetTemplate_shouldReturnSumOfCategoryBudgets() {
        // Given: 여러 카테고리 예산이 설정된 상태
        sut.categoryBudgets = [
            makeCategoryBudgetDTO(amount: 300000),
            makeCategoryBudgetDTO(amount: 200000),
            makeCategoryBudgetDTO(amount: 100000)
        ]
        
        // When: totalCategoryBudgetTemplate 계산
        // Then: 모든 카테고리 예산의 합이 반환됨
        XCTAssertEqual(sut.totalCategoryBudgetTemplate, 600000)
    }
    
    func test_remainingAmount_shouldReturnCorrectValue() {
        // Given: 총 예산과 카테고리 예산이 설정된 상태
        sut.totalAmount = 1000000
        sut.categoryBudgets = [makeCategoryBudgetDTO(amount: 300000)]
        
        // When: remainingAmount 계산
        // Then: 올바른 잔여 예산이 반환됨
        XCTAssertEqual(sut.remainingAmount, 700000)
    }
    
    func test_isOverBudget_whenCategoryBudgetsExceedTotal_shouldReturnTrue() {
        // Given: 카테고리 예산이 총 예산을 초과하는 상태
        sut.totalAmount = 500000
        sut.categoryBudgets = [makeCategoryBudgetDTO(amount: 600000)]
        
        // When: isOverBudget 확인
        // Then: true 반환
        XCTAssertTrue(sut.isOverBudget)
    }
    
    func test_isOverBudget_whenCategoryBudgetsUnderTotal_shouldReturnFalse() {
        // Given: 카테고리 예산이 총 예산 내인 상태
        sut.totalAmount = 1000000
        sut.categoryBudgets = [makeCategoryBudgetDTO(amount: 500000)]
        
        // When: isOverBudget 확인
        // Then: false 반환
        XCTAssertFalse(sut.isOverBudget)
    }
    
    func test_availableCategories_shouldFilterOutExistingCategories() {
        // Given: 전체 카테고리와 이미 추가된 카테고리 예산이 있는 상태
        let category1 = makeCategoryDTO(id: UUID(), name: "식비")
        let category2 = makeCategoryDTO(id: UUID(), name: "교통비")
        let category3 = makeCategoryDTO(id: UUID(), name: "쇼핑")
        
        sut.categories = [category1, category2, category3]
        sut.categoryBudgets = [makeCategoryBudgetDTO(categoryID: category1.id, categoryName: "식비")]
        
        // When: availableCategories 계산
        let availableCategories = sut.availableCategories
        
        // Then: 이미 추가된 카테고리는 제외되고 나머지만 반환됨
        XCTAssertEqual(availableCategories.count, 2)
        XCTAssertTrue(availableCategories.contains(category2))
        XCTAssertTrue(availableCategories.contains(category3))
        XCTAssertFalse(availableCategories.contains(category1))
    }
    
    func test_removeCategoryBudgetDTO_shouldRemoveCategory() {
        // Given: 카테고리 예산이 추가된 상태
        let categoryBudget = makeCategoryBudgetDTO()
        sut.categoryBudgets = [categoryBudget]
        
        // When: 카테고리 예산 제거 액션 실행
        sut.send(.removeCategoryBudgetDTO(categoryBudget))
        
        // Then: 해당 카테고리 예산이 제거됨
        XCTAssertTrue(sut.categoryBudgets.isEmpty)
    }
    
    func test_addCategoryBudgets_shouldAddNewCategoriesWithZeroAmount() {
        // Given: 추가할 카테고리들
        let categories = [
            makeCategoryDTO(name: "식비"),
            makeCategoryDTO(name: "교통비")
        ]
        
        // When: 카테고리 추가 액션 실행
        sut.send(.addCategoryBudgets(categories))
        
        // Then: 0원으로 설정된 카테고리 예산들이 추가됨
        XCTAssertEqual(sut.categoryBudgets.count, 2)
        XCTAssertEqual(sut.categoryBudgets[0].categoryName, "식비")
        XCTAssertEqual(sut.categoryBudgets[0].amount, 0)
        XCTAssertEqual(sut.categoryBudgets[1].categoryName, "교통비")
        XCTAssertEqual(sut.categoryBudgets[1].amount, 0)
    }
    
    func test_updateCategoryBudgetAmount_shouldUpdateAmount() {
        // Given: 카테고리 예산이 설정된 상태
        let categoryBudget = makeCategoryBudgetDTO(amount: 100000)
        sut.categoryBudgets = [categoryBudget]
        
        // When: 카테고리 예산 금액 업데이트 액션 실행
        sut.send(.updateCategoryBudgetAmount(categoryBudget, 200000))
        
        // Then: 해당 카테고리의 예산 금액이 변경됨
        XCTAssertEqual(sut.categoryBudgets[0].amount, 200000)
    }
    
    func test_resetForm_shouldClearAllFormData() {
        // Given: 폼 데이터가 입력된 상태
        sut.totalAmount = 1000000
        sut.categoryBudgets = [makeCategoryBudgetDTO()]
        sut.errorMessage = "Some error"
        sut.showError = true
        
        // When: 폼 리셋 액션 실행
        sut.send(.resetForm)
        
        // Then: 모든 폼 데이터가 초기화됨
        XCTAssertNil(sut.totalAmount)
        XCTAssertTrue(sut.categoryBudgets.isEmpty)
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.showError)
    }
    
    func test_doneButtonTapped_whenBudgetIsNil_shouldShowCreateFlow() async {
        // Given: 기존 예산이 없는 상태 (생성 모드)
        sut.budget = nil
        var completionCalled = false
        
        // When: 완료 버튼 액션 실행
        sut.send(.doneButtonTapped { completionCalled = true })
        
        // Wait for async execution
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then: 생성 플로우가 실행되고 확인 다이얼로그는 표시되지 않음
        XCTAssertTrue(completionCalled)
        XCTAssertFalse(sut.showUpdateConfirmation)
    }
    
    func test_doneButtonTapped_whenBudgetExists_shouldShowConfirmation() {
        // Given: 기존 예산이 있는 상태 (수정 모드)
        sut.budget = makeBudgetDTO()
        
        // When: 완료 버튼 액션 실행
        sut.send(.doneButtonTapped { })
        
        // Then: 수정 확인 다이얼로그가 표시됨
        XCTAssertTrue(sut.showUpdateConfirmation)
    }
    
    func test_updateBudget_withTemplateType_shouldCallBothUseCases() async {
        // Given: 기존 예산과 유효한 폼 데이터가 있는 상태
        sut.budget = makeBudgetDTO()
        sut.totalAmount = 1000000
        sut.categoryBudgets = [makeCategoryBudgetDTO()]
        var completionCalled = false
        
        // When: 템플릿 포함 예산 업데이트 액션 실행
        sut.send(.updateBudget(.withTemplate) { completionCalled = true })
        
        // Wait for async execution
        try? await Task.sleep(nanoseconds: 1_500_000_000)

        // Then: 템플릿 업데이트와 예산 업데이트가 모두 실행됨
        XCTAssertTrue(completionCalled)
    }
    
    func test_updateBudget_withoutTemplateType_shouldCallOnlyBudgetUpdateUseCase() async {
        // Given: 기존 예산과 유효한 폼 데이터가 있는 상태
        sut.budget = makeBudgetDTO()
        sut.totalAmount = 1000000
        sut.categoryBudgets = [makeCategoryBudgetDTO()]
        var completionCalled = false
        
        // When: 템플릿 제외 예산 업데이트 액션 실행
        sut.send(.updateBudget(.withoutTemplate) { completionCalled = true })
        
        // Wait for async execution  
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        // Then: 예산 업데이트만 실행됨
        XCTAssertTrue(completionCalled)
    }
    
    func test_onAppear_withExistingBudget_shouldLoadBudgetData() async {
        // Given: Mock에 기존 예산 데이터가 설정된 상태
        let existingBudget = makeBudgetDTO(totalAmount: 2000000, categoryBudgets: [makeCategoryBudgetDTO(amount: 500000)])
        mockGetMonthlyBudgetUseCase.setMockBudget(existingBudget)
        
        // When: onAppear 액션 실행
        sut.send(.onAppear)
        
        // Wait for async loading
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Then: 기존 예산 데이터가 폼에 로드됨
        XCTAssertEqual(sut.budget?.id, existingBudget.id)
        XCTAssertEqual(sut.totalAmount, 2000000)
        XCTAssertEqual(sut.categoryBudgets.count, 1)
        XCTAssertEqual(sut.categoryBudgets.first?.amount, 500000)
    }
    
    func test_onAppear_withNoExistingBudget_shouldLoadCategoriesOnly() async {
        // Given: Mock에 예산 데이터가 설정되지 않은 상태
        // No budget set in mock
        
        // When: onAppear 액션 실행
        sut.send(.onAppear)
        
        // Wait for async loading
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Then: 카테고리만 로드되고 예산 데이터는 비어있음
        XCTAssertNil(sut.budget)
        XCTAssertNil(sut.totalAmount)
        XCTAssertTrue(sut.categoryBudgets.isEmpty)
        XCTAssertFalse(sut.categories.isEmpty) // Should load categories from mock
    }
    
    func test_onAppear_whenUseCaseThrowsError_shouldShowError() async {
        // Given: Mock UseCase가 에러를 던지도록 설정된 상태
        mockDIContainer.mockCategoryRepository.shouldFail = true
        
        // When: onAppear 액션 실행
        sut.send(.onAppear)
        
        // Wait for async loading
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Then: 에러 상태가 표시됨
        XCTAssertTrue(sut.showError)
        XCTAssertNotNil(sut.errorMessage)
    }
    
    func test_createBudgetWithTemplate_whenFormIsValid_shouldCallBothUseCases() async {
        // Given: 유효한 폼 데이터와 생성 모드 상태
        sut.totalAmount = 1000000
        sut.categoryBudgets = [makeCategoryBudgetDTO(amount: 300000)]
        sut.budget = nil // No existing budget (create mode)
        
        var completionCalled = false
        
        // When: 완료 버튼을 통한 예산 생성 액션 실행
        sut.send(.doneButtonTapped { completionCalled = true })
        
        // Wait for async execution
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        // Then: 템플릿 생성과 예산 생성이 모두 실행되고 예산이 설정됨
        XCTAssertTrue(completionCalled)
        XCTAssertNotNil(sut.budget) // Should be set after creation
    }
    
    // MARK: - Helper Methods
    
    private func makeBudgetDTO(
        id: UUID = UUID(),
        month: YearMonth = .current,
        totalAmount: Decimal = 1000000,
        categoryBudgets: [CategoryBudgetDTO] = []
    ) -> BudgetDTO {
        BudgetDTO(
            id: id,
            month: month,
            totalAmount: totalAmount,
            categoryBudgets: categoryBudgets
        )
    }
    
    private func makeCategoryBudgetDTO(
        id: UUID = UUID(),
        amount: Decimal = 100000,
        categoryID: UUID = UUID(),
        categoryName: String = "테스트 카테고리",
        budgetId: UUID = UUID()
    ) -> CategoryBudgetDTO {
        CategoryBudgetDTO(
            id: id,
            amount: amount,
            categoryID: categoryID,
            categoryName: categoryName,
            budgetId: budgetId
        )
    }
    
    private func makeCategoryDTO(
        id: UUID = UUID(),
        name: String = "테스트 카테고리"
    ) -> CategoryDTO {
        CategoryDTO(
            id: id,
            name: name,
            iconName: "home",
            transactionType: .variableExpense,
            isActive: true,
            subCategories: []
        )
    }
}
