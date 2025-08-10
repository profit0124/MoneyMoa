//
//  AppRouterTests.swift
//  MoneyMoaTests
//
//  Created by Sooik Kim on 8/10/25.
//

import XCTest
@testable import MoneyMoa

@MainActor
final class AppRouterTests: XCTestCase {
    
    var sut: AppRouter!
    
    override func setUp() {
        super.setUp()
        sut = AppRouter()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInit_WithoutParent_SetsParentToNil() {
        // Given & When
        let router = AppRouter()
        
        // Then
        XCTAssertNil(router.parent)
    }
    
    func testInit_WithParent_SetsParentCorrectly() {
        // Given
        let parentRouter = AppRouter()
        
        // When
        let childRouter = AppRouter(parent: parentRouter)
        
        // Then
        XCTAssertNotNil(childRouter.parent)
        XCTAssertIdentical(childRouter.parent, parentRouter)
    }
    
    // MARK: - Navigation Tests
    
    func testPush_AddsRouteToPath() {
        // Given
        let route = AppRoute.mainHome
        
        // When
        sut.push(route)
        
        // Then
        XCTAssertEqual(sut.path.count, 1)
        XCTAssertEqual(sut.path.first, route)
    }
    
    func testPush_MultipleRoutes_AddsAllToPath() {
        // Given
        let routes: [AppRoute] = [.mainHome, .settingsRoot, .chartsOverview]
        
        // When
        routes.forEach { sut.push($0) }
        
        // Then
        XCTAssertEqual(sut.path.count, 3)
        XCTAssertEqual(Array(sut.path), routes)
    }
    
    func testPop_WithItemsInPath_RemovesLastItem() {
        // Given
        sut.push(.mainHome)
        sut.push(.settingsRoot)
        
        // When
        sut.pop()
        
        // Then
        XCTAssertEqual(sut.path.count, 1)
        XCTAssertEqual(sut.path.first, .mainHome)
    }
    
    func testPop_WithEmptyPath_DoesNotCrash() {
        // Given
        XCTAssertTrue(sut.path.isEmpty)
        
        // When & Then
        XCTAssertNoThrow(sut.pop())
        XCTAssertTrue(sut.path.isEmpty)
    }
    
    func testPopToRoot_ClearsAllItems() {
        // Given
        sut.push(.mainHome)
        sut.push(.settingsRoot)
        sut.push(.chartsOverview)
        
        // When
        sut.popToRoot()
        
        // Then
        XCTAssertTrue(sut.path.isEmpty)
    }
    
    // MARK: - Modal Presentation Tests
    
    func testPresent_AsSheet_SetsSheetItem() {
        // Given
        let route = AppRoute.transactionsAdd
        
        // When
        sut.present(route, as: .sheet)
        
        // Then
        XCTAssertNotNil(sut.sheet)
        XCTAssertEqual(sut.sheet?.root, route)
        XCTAssertEqual(sut.sheet?.style, .sheet)
        XCTAssertNil(sut.fullScreen)
    }
    
    func testPresent_AsFullScreen_SetsFullScreenItem() {
        // Given
        let route = AppRoute.settingsRoot
        
        // When
        sut.present(route, as: .fullScreen)
        
        // Then
        XCTAssertNotNil(sut.fullScreen)
        XCTAssertEqual(sut.fullScreen?.root, route)
        XCTAssertEqual(sut.fullScreen?.style, .fullScreen)
        XCTAssertNil(sut.sheet)
    }
    
    func testPresent_MultipleTimes_ReplacesExistingModal() {
        // Given
        sut.present(.transactionsAdd, as: .sheet)
        let firstSheetId = sut.sheet?.id
        
        // When
        sut.present(.settingsRoot, as: .sheet)
        
        // Then
        XCTAssertNotNil(sut.sheet)
        XCTAssertEqual(sut.sheet?.root, .settingsRoot)
        XCTAssertNotEqual(sut.sheet?.id, firstSheetId)
    }
    
    // MARK: - Dismiss Tests
    
    func testDismissModal_WithoutParent_ClearsBothModals() {
        // Given
        sut.present(.transactionsAdd, as: .sheet)
        sut.present(.settingsRoot, as: .fullScreen)
        
        // When
        sut.dismissModal()
        
        // Then
        XCTAssertNil(sut.sheet)
        XCTAssertNil(sut.fullScreen)
    }
    
    func testDismissModal_WithParent_DelegatesToParent() {
        // Given
        let parentRouter = AppRouter()
        let childRouter = AppRouter(parent: parentRouter)
        parentRouter.present(.settingsRoot, as: .fullScreen)
        
        // When
        childRouter.dismissModal()
        
        // Then
        XCTAssertNil(parentRouter.sheet)
        XCTAssertNil(parentRouter.fullScreen)
    }
    
    func testDismissSheet_WithoutParent_ClearsSheetOnly() {
        // Given
        sut.present(.transactionsAdd, as: .sheet)
        sut.present(.settingsRoot, as: .fullScreen)
        
        // When
        sut.dismissSheet()
        
        // Then
        XCTAssertNil(sut.sheet)
        XCTAssertNotNil(sut.fullScreen)
    }
    
    func testDismissSheet_WithParent_DelegatesToParent() {
        // Given
        let parentRouter = AppRouter()
        let childRouter = AppRouter(parent: parentRouter)
        parentRouter.present(.transactionsAdd, as: .sheet)
        
        // When
        childRouter.dismissSheet()
        
        // Then
        XCTAssertNil(parentRouter.sheet)
    }
    
    func testDismissFullScreen_WithoutParent_ClearsFullScreenOnly() {
        // Given
        sut.present(.transactionsAdd, as: .sheet)
        sut.present(.settingsRoot, as: .fullScreen)
        
        // When
        sut.dismissFullScreen()
        
        // Then
        XCTAssertNotNil(sut.sheet)
        XCTAssertNil(sut.fullScreen)
    }
    
    func testDismissFullScreen_WithParent_DelegatesToParent() {
        // Given
        let parentRouter = AppRouter()
        let childRouter = AppRouter(parent: parentRouter)
        parentRouter.present(.settingsRoot, as: .fullScreen)
        
        // When
        childRouter.dismissFullScreen()
        
        // Then
        XCTAssertNil(parentRouter.fullScreen)
    }
}

// MARK: - ModalItem Tests

extension AppRouterTests {
    
    func testModalItem_Equality_ComparesByID() {
        // Given
        let item1 = ModalItem(root: .mainHome, style: .sheet)
        let item2 = ModalItem(root: .mainHome, style: .sheet)
        
        // Then
        XCTAssertNotEqual(item1, item2) // Different IDs
        XCTAssertEqual(item1, item1) // Same instance
    }
    
    func testModalItem_IdentifiableID_IsUnique() {
        // Given
        let item1 = ModalItem(root: .mainHome, style: .sheet)
        let item2 = ModalItem(root: .mainHome, style: .sheet)
        
        // Then
        XCTAssertNotEqual(item1.id, item2.id)
    }
}
