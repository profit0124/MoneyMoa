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
    private var initializationTask: Task<Void, Never>?
    
    init(diContainer: DIContainer) {
        self.diContainer = diContainer
    }
    
    func initializeApp() async {
        // 이미 초기화가 진행 중이면 해당 태스크를 기다림
        if let existingTask = initializationTask {
            await existingTask.value
            return
        }
        
        // 새로운 초기화 태스크 생성
        let task = Task { @MainActor in
            isLoading = true
            loadingMessage = "추천 카테고리를 설정하고 있습니다..."
            
            do {
                let hasInitialized = UserDefaults.standard.bool(forKey: "hasInitializedCategories")
                
                if !hasInitialized {
                    let importUseCase = diContainer.makeImportRecommendedCategoriesUseCase()
                    try await importUseCase.execute()
                    #if !DEBUG
                    UserDefaults.standard.set(true, forKey: "hasInitializedCategories")
                    #endif
                }
            } catch {
                print("추천 카테고리 초기화 실패: \(error)")
            }
            
            isLoading = false
            initializationTask = nil
        }
        
        initializationTask = task
        await task.value
    }
}
