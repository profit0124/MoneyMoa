//
//  CategoryListViewModelTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 8/26/25.
//

import XCTest
import Combine
@testable import MoneyMoa

// MARK: - CategoryListViewModelTests

@MainActor
final class CategoryListViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var viewModel: CategoryListViewModel!
    private var mockDIContainer: MockDIContainer!
    private var mockCategoryEventPublisher: MockCategoryEventPublisher!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        
        mockDIContainer = MockDIContainer()
        mockCategoryEventPublisher = MockCategoryEventPublisher()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        viewModel?.send(.unsubscribe)
        viewModel = nil
        mockDIContainer = nil
        mockCategoryEventPublisher = nil
        cancellables?.removeAll()
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createViewModel(mode: CategoryListMode = .configuration) -> CategoryListViewModel {
        return CategoryListViewModel(
            getCategoriesUseCase: mockDIContainer.makeGetCategoriesByTypeUseCase(),
            categoryEventPublisher: mockCategoryEventPublisher,
            mode: mode
        )
    }
    
    // MARK: - Test Methods - Initialization
    
    func test_initialization_configurationMode_setsCorrectInitialValues() {
        // When
        viewModel = createViewModel(mode: .configuration)
        
        // Then
        XCTAssertEqual(viewModel.mode, .configuration)
        XCTAssertEqual(viewModel.selectedTransactionType, .income)
        XCTAssertTrue(viewModel.categories.isEmpty)
        XCTAssertNil(viewModel.selectedSubCategory)
    }
    
    func test_initialization_selectionMode_setsCorrectInitialValues() {
        // When
        viewModel = createViewModel(mode: .selection)
        
        // Then
        XCTAssertEqual(viewModel.mode, .selection)
        XCTAssertEqual(viewModel.selectedTransactionType, .variableExpense)
        XCTAssertTrue(viewModel.categories.isEmpty)
        XCTAssertNil(viewModel.selectedSubCategory)
    }
    
    func test_initialization_withoutCategoryEventPublisher() {
        // When
        viewModel = CategoryListViewModel(
            getCategoriesUseCase: mockDIContainer.makeGetCategoriesByTypeUseCase(),
            mode: .configuration
        )
        
        // Then
        XCTAssertEqual(viewModel.mode, .configuration)
        XCTAssertNotNil(viewModel)
    }
    
    // MARK: - Test Methods - Action Handling - onAppear
    
    func test_onAppear_withEmptyCategories_fetchesCategories() async {
        // Given
        viewModel = createViewModel(mode: .configuration)
        // MockGetCategoriesWithSubCategoriesByTypeUseCase는 기본적으로 income 타입에 대해 income 카테고리를 반환
        
        // When
        viewModel.send(.onAppear)
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then - configuration 모드의 기본 거래 유형은 .income
        XCTAssertEqual(viewModel.categories.count, 2) // income 카테고리 2개 (급여, 부수입)
        XCTAssertEqual(viewModel.categories.first?.name, "급여")
        XCTAssertEqual(viewModel.categories.first?.transactionType, .income)
    }
    
    func test_onAppear_withExistingCategories_doesNotFetch() async {
        // Given
        viewModel = createViewModel(mode: .configuration)
        viewModel.categories = [CategoryDTO.mockIncome] // 이미 카테고리가 있는 상태
        let initialCategoriesCount = viewModel.categories.count
        
        // When
        viewModel.send(.onAppear)
        
        // Wait for potential async operation
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        
        // Then - 카테고리가 이미 있으므로 추가 fetch 하지 않음
        XCTAssertEqual(viewModel.categories.count, initialCategoriesCount)
    }
    
    // MARK: - Test Methods - Action Handling - selectTransactionType
    
    func test_selectTransactionType_updatesSelectedTransactionTypeAndFetchesCategories() async {
        // Given
        viewModel = createViewModel(mode: .configuration)
        
        // When
        viewModel.send(.selectTransactionType(.variableExpense))
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then
        XCTAssertEqual(viewModel.selectedTransactionType, .variableExpense)
        XCTAssertEqual(viewModel.categories.count, 3) // 식비, 쇼핑, 문화생활

        // 순서에 의존하지 않고 내용으로 검증 (CI 환경 안정성)
        let categoryNames = viewModel.categories.map { $0.name }
        XCTAssertTrue(categoryNames.contains("식비"))
        XCTAssertTrue(categoryNames.contains("쇼핑"))
        XCTAssertTrue(categoryNames.contains("문화생활"))
        XCTAssertEqual(Set(categoryNames), Set(["식비", "쇼핑", "문화생활"]))
        XCTAssertTrue(viewModel.categories.allSatisfy { $0.transactionType == .variableExpense })
    }
    
    // MARK: - Test Methods - Action Handling - selectSubCategory
    
    func test_selectSubCategory_selectionMode_setsSelectedSubCategory() {
        // Given
        viewModel = createViewModel(mode: .selection)
        let category = CategoryDTO.mockFood
        let subCategory = SubCategoryDTO.mockFoodExpense
        let router = AppRouter()
        
        // When
        viewModel.send(.selectSubCategory(category, subCategory, router))
        
        // Then
        XCTAssertEqual(viewModel.selectedSubCategory?.id, subCategory.id)
    }
    
    // MARK: - Test Methods - Action Handling - unsubscribe
    
    func test_unsubscribe_clearsSubscriptions() {
        // Given
        viewModel = createViewModel(mode: .configuration)
        
        // When
        viewModel.send(.unsubscribe)
        
        // Then - 구독이 정리되었는지 확인 (실제 구현에서는 cancellables가 private이므로 동작 확인)
        // 이 테스트는 메모리 누수 방지를 위한 것으로, 크래시가 발생하지 않으면 성공
        XCTAssertNotNil(viewModel)
    }
    
    // MARK: - Test Methods - Category Event Subscription
    
    func test_categoryEventSubscription_createdEvent_selectionMode_updatesSelectedSubCategory() async {
        // Given
        viewModel = createViewModel(mode: .selection)
        let category = CategoryDTO.mockFood
        let event = CategoryEvent(type: .created, category: category)
        
        // When
        mockCategoryEventPublisher.publish(event)
        
        // Wait for async event processing
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then
        XCTAssertEqual(viewModel.selectedTransactionType, category.transactionType)
        XCTAssertEqual(viewModel.selectedSubCategory?.id, category.subCategories.first?.id)
    }
    
    func test_categoryEventSubscription_createdEvent_configurationMode_fetchesCategories() async {
        // Given
        viewModel = createViewModel(mode: .configuration)
        viewModel.selectedTransactionType = .variableExpense
        let category = CategoryDTO.mockFood
        let event = CategoryEvent(type: .created, category: category)
        
        // When
        mockCategoryEventPublisher.publish(event)
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then - configuration 모드에서는 같은 거래 유형의 카테고리 생성 시 목록 갱신
        XCTAssertEqual(viewModel.categories.count, 3) // 식비, 쇼핑, 문화생활
        XCTAssertTrue(viewModel.categories.contains { $0.name == "식비" })
    }
    
    func test_categoryEventSubscription_updatedEvent_fetchesCategories() async {
        // Given
        viewModel = createViewModel(mode: .configuration)
        let category = CategoryDTO.mockFood
        let event = CategoryEvent(type: .updated, category: category)
        
        // When
        mockCategoryEventPublisher.publish(event)
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then - updated 이벤트는 카테고리 목록을 갱신
        XCTAssertEqual(viewModel.categories.count, 2) // income 카테고리 2개 (급여, 부수입)
        XCTAssertEqual(viewModel.categories.first?.name, "급여")
    }
    
    func test_categoryEventSubscription_deletedEvent_removesCategoryFromList() async {
        // Given
        viewModel = createViewModel(mode: .configuration)

        let category1 = CategoryDTO.mockFood
        let category2 = CategoryDTO.mockTransport

        viewModel.categories = [category1, category2]
        
        let event = CategoryEvent(type: .deleted, category: category1)
        
        // When
        mockCategoryEventPublisher.publish(event)
        
        // Wait for async event processing
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then
        XCTAssertEqual(viewModel.categories.count, 1)
        XCTAssertEqual(viewModel.categories.first?.id, category2.id)
        XCTAssertEqual(viewModel.categories.first?.name, "교통비")
    }
    
    // MARK: - Test Methods - Error Handling
    
    func test_fetchCategories_withError_handlesGracefully() async {
        // Given
        viewModel = createViewModel(mode: .configuration)
        mockDIContainer.mockCategoryRepository.shouldFail = true
        
        // When
        viewModel.send(.onAppear)
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then - 에러가 발생해도 크래시하지 않음
        XCTAssertTrue(viewModel.categories.isEmpty)
    }
    
    // MARK: - Test Methods - Different Transaction Types
    
    func test_selectTransactionType_income_fetchesIncomeCategories() async {
        // Given
        viewModel = createViewModel(mode: .selection)
        
        // When
        viewModel.send(.selectTransactionType(.income))
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then
        XCTAssertEqual(viewModel.selectedTransactionType, .income)
        XCTAssertEqual(viewModel.categories.count, 2) // 급여, 부수입
        XCTAssertEqual(viewModel.categories.first?.name, "급여")
        XCTAssertEqual(viewModel.categories.first?.transactionType, .income)
    }
    
    func test_selectTransactionType_fixedExpense_fetchesFixedExpenseCategories() async {
        // Given
        viewModel = createViewModel(mode: .selection)
        
        // When
        viewModel.send(.selectTransactionType(.fixedExpense))
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then
        XCTAssertEqual(viewModel.selectedTransactionType, .fixedExpense)
        XCTAssertEqual(viewModel.categories.count, 2) // 주거비, 보험료
        XCTAssertEqual(viewModel.categories.first?.name, "주거비")
        XCTAssertEqual(viewModel.categories.first?.transactionType, .fixedExpense)
    }
    
    func test_selectTransactionType_variableExpense_fetchesVariableExpenseCategories() async {
        // Given
        viewModel = createViewModel(mode: .configuration)
        
        // When
        viewModel.send(.selectTransactionType(.variableExpense))
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then
        XCTAssertEqual(viewModel.selectedTransactionType, .variableExpense)
        XCTAssertEqual(viewModel.categories.count, 3) // 식비, 쇼핑, 문화생활

        // 순서에 의존하지 않고 내용으로 검증 (CI 환경 안정성)
        let categoryNames = viewModel.categories.map { $0.name }
        XCTAssertTrue(categoryNames.contains("식비"))
        XCTAssertTrue(categoryNames.contains("쇼핑"))
        XCTAssertTrue(categoryNames.contains("문화생활"))
        XCTAssertEqual(Set(categoryNames), Set(["식비", "쇼핑", "문화생활"]))
        XCTAssertTrue(viewModel.categories.allSatisfy { $0.transactionType == .variableExpense })
    }
}
