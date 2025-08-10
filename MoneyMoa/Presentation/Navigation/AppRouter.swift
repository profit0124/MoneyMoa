//
//  AppRouter.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/10/25.
//

import SwiftUI
import Observation

// MARK: - Modal Style

enum ModalStyle {
    case sheet
    case fullScreen
}

// MARK: - Modal Item

struct ModalItem: Identifiable, Equatable {
    let id = UUID()
    let root: AppRoute
    let style: ModalStyle
    
    static func == (lhs: ModalItem, rhs: ModalItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - App Router

@MainActor
@Observable
final class AppRouter {
    // MARK: - Properties
    
    var path: [AppRoute] = []
    var sheet: ModalItem?
    var fullScreen: ModalItem?
    
    // MARK: - Hierarchical Router
    
    weak var parent: AppRouter?
    
    init(parent: AppRouter? = nil) {
        self.parent = parent
    }
    
    // MARK: - Navigation Methods
    
    func push(_ route: AppRoute) {
        path.append(route)
    }
    
    func pop() {
        _ = path.popLast()
    }
    
    func popToRoot() {
        path.removeAll()
    }
    
    func present(_ route: AppRoute, as style: ModalStyle) {
        let modalItem = ModalItem(root: route, style: style)
        
        switch style {
        case .sheet:
            sheet = modalItem
        case .fullScreen:
            fullScreen = modalItem
        }
    }
    
    func dismissModal() {
        if let parent = parent {
            parent.dismissModal()
        } else {
            // Root router - handle local dismissal
            sheet = nil
            fullScreen = nil
        }
    }
    
    func dismissSheet() {
        if let parent = parent {
            parent.dismissSheet()
        } else {
            sheet = nil
        }
    }
    
    func dismissFullScreen() {
        if let parent = parent {
            parent.dismissFullScreen()
        } else {
            fullScreen = nil
        }
    }
}
