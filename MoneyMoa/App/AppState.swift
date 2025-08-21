//
//  AppState.swift
//  MoneyMoa
//
//  Created by Claude on 8/21/25.
//

import Foundation
import Observation

// MARK: - AppState

@MainActor
@Observable
final class AppState {
    var isLoading = true
    var loadingMessage = "데이터를 준비하고 있습니다..."
    
    private let diContainer: DIContainer
    
    init(diContainer: DIContainer) {
        self.diContainer = diContainer
    }
    
    func initializeApp() async {
        isLoading = true
        loadingMessage = "추천 카테고리를 설정하고 있습니다..."
        
        do {
            let hasInitialized = UserDefaults.standard.bool(forKey: "hasInitializedCategories")
            
            if !hasInitialized {
                let importUseCase = diContainer.makeImportRecommendedCategoriesUseCase()
                try await importUseCase.execute()
                UserDefaults.standard.set(true, forKey: "hasInitializedCategories")
            }
        } catch {
            print("추천 카테고리 초기화 실패: \(error)")
        }
        
        isLoading = false
    }
}
