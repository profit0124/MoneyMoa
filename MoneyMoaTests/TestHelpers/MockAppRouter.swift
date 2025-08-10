//
//  MockAppRouter.swift
//  MoneyMoaTests
//
//  Created by Sooik Kim on 8/10/25.
//

import Foundation
import Observation
@testable import MoneyMoa

@MainActor
@Observable
final class MockAppRouter {
    
    // MARK: - Tracking Properties
    
    private(set) var pushCallCount = 0
    private(set) var popCallCount = 0
    private(set) var popToRootCallCount = 0
    private(set) var presentCallCount = 0
    private(set) var dismissModalCallCount = 0
    private(set) var dismissSheetCallCount = 0
    private(set) var dismissFullScreenCallCount = 0
    
    private(set) var lastPushedRoute: AppRoute?
    private(set) var lastPresentedRoute: AppRoute?
    private(set) var lastPresentationStyle: ModalStyle?
    
    private(set) var pushedRoutes: [AppRoute] = []
    private(set) var presentedRoutes: [(route: AppRoute, style: ModalStyle)] = []
    
    // MARK: - Mock AppRouter Properties
    
    var path: [AppRoute] = []
    var sheet: ModalItem?
    var fullScreen: ModalItem?
    var parent: MockAppRouter?
    
    // MARK: - Mock Methods
    
    func push(_ route: AppRoute) {
        pushCallCount += 1
        lastPushedRoute = route
        pushedRoutes.append(route)
        path.append(route)
    }
    
    func pop() {
        popCallCount += 1
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    func popToRoot() {
        popToRootCallCount += 1
        path.removeAll()
    }
    
    func present(_ route: AppRoute, as style: ModalStyle) {
        presentCallCount += 1
        lastPresentedRoute = route
        lastPresentationStyle = style
        presentedRoutes.append((route: route, style: style))
        
        let modalItem = ModalItem(root: route, style: style)
        switch style {
        case .sheet:
            sheet = modalItem
        case .fullScreen:
            fullScreen = modalItem
        }
    }
    
    func dismissModal() {
        dismissModalCallCount += 1
        sheet = nil
        fullScreen = nil
    }
    
    func dismissSheet() {
        dismissSheetCallCount += 1
        sheet = nil
    }
    
    func dismissFullScreen() {
        dismissFullScreenCallCount += 1
        fullScreen = nil
    }
    
    // MARK: - Reset Method
    
    func reset() {
        pushCallCount = 0
        popCallCount = 0
        popToRootCallCount = 0
        presentCallCount = 0
        dismissModalCallCount = 0
        dismissSheetCallCount = 0
        dismissFullScreenCallCount = 0
        
        lastPushedRoute = nil
        lastPresentedRoute = nil
        lastPresentationStyle = nil
        
        pushedRoutes.removeAll()
        presentedRoutes.removeAll()
        
        // Reset mock router state
        path.removeAll()
        sheet = nil
        fullScreen = nil
    }
    
    // MARK: - Verification Helpers
    
    func verifyPushCalled(with route: AppRoute, file: StaticString = #file, line: UInt = #line) -> Bool {
        guard pushCallCount > 0 else {
            return false
        }
        return lastPushedRoute == route
    }
    
    func verifyPresentCalled(with route: AppRoute, style: ModalStyle, file: StaticString = #file, line: UInt = #line) -> Bool {
        guard presentCallCount > 0 else {
            return false
        }
        return lastPresentedRoute == route && lastPresentationStyle == style
    }
    
    func verifyNoCalls() -> Bool {
        return pushCallCount == 0 &&
               popCallCount == 0 &&
               popToRootCallCount == 0 &&
               presentCallCount == 0 &&
               dismissModalCallCount == 0 &&
               dismissSheetCallCount == 0 &&
               dismissFullScreenCallCount == 0
    }
}
