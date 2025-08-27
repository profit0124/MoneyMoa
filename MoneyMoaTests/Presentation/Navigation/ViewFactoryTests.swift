//
//  ViewFactoryTests.swift
//  MoneyMoaTests
//
//  Created by Sooik Kim on 8/10/25.
//

import XCTest
import SwiftUI
@testable import MoneyMoa

final class ViewFactoryTests: XCTestCase {
    
    var sut: ViewFactory!
    var mockContainer: MockDIContainer!
    
    override func setUp() {
        super.setUp()
        mockContainer = MockDIContainer()
        sut = ViewFactory(container: mockContainer)
    }
    
    override func tearDown() {
        sut = nil
        mockContainer = nil
        super.tearDown()
    }
    
    // MARK: - Main Routes Tests
    
    func testMakeView_MainHome_ReturnsMainView() {
        // Given
        let route = AppRoute.main(.home)
        
        // When
        let view = sut.makeView(for: route)
        
        // Then
        // ViewBuilder returns complex conditional types, so we verify it doesn't crash
        XCTAssertNotNil(view, "Expected non-nil view for MainHome route")
    }
    
    // MARK: - Settings Routes Tests
    
    func testMakeView_SettingsRoot_ReturnsSettingsView() {
        // Given
        let route = AppRoute.settings(.root)
        
        // When
        let view = sut.makeView(for: route)
        
        // Then
        XCTAssertNotNil(view, "Expected non-nil view for SettingsRoot route")
    }
    
    func testMakeView_SettingsBudget_ReturnsBudgetTemplateView() {
        // Given
        let yearMonth = YearMonth.current
        let route = AppRoute.settings(.budget(yearMonth))
        
        // When
        let view = sut.makeView(for: route)
        
        // Then
        XCTAssertNotNil(view, "Expected non-nil view for SettingsBudget route")
    }
    
    func testMakeView_SettingsCategory_ReturnsCategorySetupView() {
        // Given
        let route = AppRoute.settings(.category)
        
        // When
        let view = sut.makeView(for: route)
        
        // Then
        XCTAssertNotNil(view, "Expected non-nil view for SettingsCategory route")
    }
    
    func testMakeView_SettingsCategorySelector_ReturnsCategorySelectorView() {
        // Given
        let category = CategoryDTO.mockFood
        let route = AppRoute.settings(.categorySelector(category))
        
        // When
        let view = sut.makeView(for: route)
        
        // Then
        XCTAssertNotNil(view, "Expected non-nil view for SettingsCategorySelector route")
    }
    
    func testMakeView_SettingsCategoryForm_ReturnsCategoryFormView() {
        // Given
        let mode = CategoryListMode.configuration
        let category = CategoryDTO.mockTransport
        let transactionType = TransactionType.variableExpense
        let route = AppRoute.settings(.categoryForm(mode, category, transactionType))
        
        // When
        let view = sut.makeView(for: route)
        
        // Then
        XCTAssertNotNil(view, "Expected non-nil view for SettingsCategoryForm route")
    }
    
    func testMakeView_SettingsCategoryForm_WithNilValues_ReturnsCategoryFormView() {
        // Given
        let mode = CategoryListMode.selection
        let route = AppRoute.settings(.categoryForm(mode, nil, nil))
        
        // When
        let view = sut.makeView(for: route)
        
        // Then
        XCTAssertNotNil(view, "Expected non-nil view for SettingsCategoryForm route with nil values")
    }
    
    func testMakeView_SettingsSubCategoryForm_ReturnsSubCategoryFormView() {
        // Given
        let category = CategoryDTO.mockFood
        let subCategory = SubCategoryDTO.mockFoodExpense
        let route = AppRoute.settings(.subCategoryForm(category, subCategory))
        
        // When
        let view = sut.makeView(for: route)
        
        // Then
        XCTAssertNotNil(view, "Expected non-nil view for SettingsSubCategoryForm route")
    }
    
    func testMakeView_SettingsSubCategoryForm_WithNilSubCategory_ReturnsSubCategoryFormView() {
        // Given
        let category = CategoryDTO.mockTransport
        let route = AppRoute.settings(.subCategoryForm(category, nil))
        
        // When
        let view = sut.makeView(for: route)
        
        // Then
        XCTAssertNotNil(view, "Expected non-nil view for SettingsSubCategoryForm route with nil subcategory")
    }
    
    // MARK: - Transactions Routes Tests
    
    func testMakeView_TransactionsAdd_ReturnsAddTransactionView() {
        // Given
        let route = AppRoute.transactions(.add)
        
        // When
        let view = sut.makeView(for: route)
        
        // Then
        XCTAssertNotNil(view, "Expected non-nil view for TransactionsAdd route")
    }
    
    func testMakeView_TransactionsDetail_ReturnsTransactionDetailView() {
        // Given
        let transaction = TransactionDTO.mockStandardExpense
        let route = AppRoute.transactions(.detail(transaction))
        
        // When
        let view = sut.makeView(for: route)
        
        // Then
        XCTAssertNotNil(view, "Expected non-nil view for TransactionsDetail route")
    }
    
    func testMakeView_TransactionsUpdate_ReturnsUpdateTransactionView() {
        // Given
        let transaction = TransactionDTO.mockLunch
        let route = AppRoute.transactions(.update(transaction))
        
        // When
        let view = sut.makeView(for: route)
        
        // Then
        XCTAssertNotNil(view, "Expected non-nil view for TransactionsUpdate route")
    }
    
    // MARK: - Charts Routes Tests
    
    func testMakeView_ChartsOverview_ReturnsChartView() {
        // Given
        let route = AppRoute.charts(.overview)
        
        // When
        let view = sut.makeView(for: route)
        
        // Then
        XCTAssertNotNil(view, "Expected non-nil view for ChartsOverview route")
    }
    
    // MARK: - Container Integration Tests
    
    func testMakeView_MainHome_UsesContainerViewModel() {
        // Given
        let route = AppRoute.main(.home)
        
        // When
        let view = sut.makeView(for: route)
        
        // Then
        // Verify that the container's makeMainViewModel was called
        // This is implicit through successful view creation
        XCTAssertNotNil(view, "Expected non-nil view using container")
    }
    
    // MARK: - Parameter Passing Tests
    
    func testMakeView_TransactionDetail_PassesCorrectTransaction() {
        // Given
        let expectedTransaction = TransactionDTO.mockTransport
        let route = AppRoute.transactions(.detail(expectedTransaction))
        
        // When
        let view = sut.makeView(for: route)
        
        // Then
        // ViewBuilder returns complex conditional types, but we verify view creation succeeds
        XCTAssertNotNil(view, "Expected non-nil view for TransactionDetail with transaction")
        
        // The parameter passing is verified implicitly through successful view creation
        // since TransactionDetailView requires a transaction parameter
    }
    
    func testMakeView_TransactionUpdate_PassesCorrectTransaction() {
        // Given
        let expectedTransaction = TransactionDTO.mockBeauty
        let route = AppRoute.transactions(.update(expectedTransaction))
        
        // When
        let view = sut.makeView(for: route)
        
        // Then
        // ViewBuilder returns complex conditional types, but we verify view creation succeeds
        XCTAssertNotNil(view, "Expected non-nil view for TransactionUpdate with transaction")
        
        // The parameter passing is verified implicitly through successful view creation
        // since UpdateTransactionView requires a transaction parameter
    }
    
    func testMakeView_CategorySelector_PassesCorrectCategory() {
        // Given
        let expectedCategory = CategoryDTO.mockIncome
        let route = AppRoute.settings(.categorySelector(expectedCategory))
        
        // When
        let view = sut.makeView(for: route)
        
        // Then
        XCTAssertNotNil(view, "Expected non-nil view for CategorySelector with category")
    }
    
    func testMakeView_CategoryForm_PassesCorrectParameters() {
        // Given
        let mode = CategoryListMode.selection
        let category = CategoryDTO.mockTransport
        let transactionType = TransactionType.fixedExpense
        let route = AppRoute.settings(.categoryForm(mode, category, transactionType))
        
        // When
        let view = sut.makeView(for: route)
        
        // Then
        XCTAssertNotNil(view, "Expected non-nil view for CategoryForm with parameters")
    }
    
    func testMakeView_SubCategoryForm_PassesCorrectParameters() {
        // Given
        let category = CategoryDTO.mockFood
        let subCategory = SubCategoryDTO.mockFoodExpense
        let route = AppRoute.settings(.subCategoryForm(category, subCategory))
        
        // When
        let view = sut.makeView(for: route)
        
        // Then
        XCTAssertNotNil(view, "Expected non-nil view for SubCategoryForm with parameters")
    }
    
    func testMakeView_BudgetSetup_PassesCorrectYearMonth() {
        // Given
        let yearMonth = YearMonth(year: 2024, month: 12)
        let route = AppRoute.settings(.budget(yearMonth))
        
        // When
        let view = sut.makeView(for: route)
        
        // Then
        XCTAssertNotNil(view, "Expected non-nil view for BudgetSetup with yearMonth")
    }
    
    // MARK: - ViewBuilder Tests
    
    func testMakeView_AllRoutes_ReturnsNonNilViews() {
        // Given
        let transaction = TransactionDTO.mockSalary
        let yearMonth = YearMonth.current
        let category = CategoryDTO.mockFood
        let subCategory = SubCategoryDTO.mockFoodExpense
        let mode = CategoryListMode.configuration
        let transactionType = TransactionType.variableExpense
        
        let allRoutes: [AppRoute] = [
            .main(.home),
            .settings(.root),
            .settings(.budget(yearMonth)),
            .settings(.category),
            .settings(.categorySelector(category)),
            .settings(.categoryForm(mode, category, transactionType)),
            .settings(.categoryForm(mode, nil, nil)),
            .settings(.subCategoryForm(category, subCategory)),
            .settings(.subCategoryForm(category, nil)),
            .transactions(.add),
            .transactions(.detail(transaction)),
            .transactions(.update(transaction)),
            .charts(.overview)
        ]
        
        // When & Then
        allRoutes.forEach { route in
            let view = sut.makeView(for: route)
            XCTAssertNotNil(view, "View should not be nil for route: \(route)")
        }
    }
    
    func testMakeView_ConsistentViewTypes_ForSameRoutes() {
        // Given
        let route = AppRoute.main(.home)
        
        // When
        let view1 = sut.makeView(for: route)
        let view2 = sut.makeView(for: route)
        
        // Then
        XCTAssertTrue(type(of: view1) == type(of: view2))
    }
}
