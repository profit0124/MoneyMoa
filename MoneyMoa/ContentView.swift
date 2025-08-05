//
//  ContentView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/25/25.
//

import SwiftUI

struct ContentView: View {
    
    // MARK: - Properties
    
    /// DI 컨테이너
    private let diContainer: DIContainer
    
    // MARK: - Initialization
    
    init(diContainer: DIContainer) {
        self.diContainer = diContainer
    }
    
    // MARK: - View Body
    
    var body: some View {
        MainView(viewModel: diContainer.makeMainViewModel())
    }
}

#Preview {
    ContentView(diContainer: MockDIContainer())
}
