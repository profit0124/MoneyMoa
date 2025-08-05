//
//  MoneyMoaApp.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/25/25.
//

import SwiftUI
import SwiftData

@main
struct MoneyMoaApp: App {
    
    // MARK: - Properties
    
    /// SwiftData Database
    private let database: Database?
    
    /// DI 컨테이너
    private let diContainer: DIContainer
    
    // MARK: - Initialization
    
    init() {
        self.database = try? Database(isStoredInMemoryOnly: true)
        self.diContainer = DIContainerFactory.createDefault(database: self.database)
    }
    
    // MARK: - App Body
    
    var body: some Scene {
        WindowGroup {
            ContentView(diContainer: diContainer)
        }
    }
}
