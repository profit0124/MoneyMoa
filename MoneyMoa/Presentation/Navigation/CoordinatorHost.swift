//
//  CoordinatorHost.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/10/25.
//

import SwiftUI

// MARK: - Coordinator Host

struct CoordinatorHost: View {
    @State private var router: AppRouter
    let container: DIContainer
    let start: AppRoute
    
    init(container: DIContainer, start: AppRoute, parent: AppRouter? = nil) {
        self.container = container
        self.start = start
        self._router = State(wrappedValue: AppRouter(parent: parent))
    }
    
    var body: some View {
        let factory = ViewFactory(container: container)
        
        NavigationStack(path: $router.path) {
            factory.makeView(for: start)
                .navigationDestination(for: AppRoute.self) { route in
                    factory.makeView(for: route)
                }
        }
        .sheet(item: $router.sheet) { item in
            CoordinatorHost(container: container, start: item.root, parent: router)
        }
        .fullScreenCover(item: $router.fullScreen) { item in
            CoordinatorHost(container: container, start: item.root, parent: router)
        }
        .environment(router)
    }
}

// MARK: - Preview

#Preview {
    let mockContainer = MockDIContainer()
    
    CoordinatorHost(
        container: mockContainer,
        start: .mainHome
    )
}
