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

            await checkInitialCategories()
            await checkCurrentMonthBudget()
            await processDueTransactionTemplates()

            isLoading = false
            initializationTask = nil
        }

        initializationTask = task
        await task.value
    }

    private func checkInitialCategories() async {
        loadingMessage = "추천 카테고리를 설정하고 있습니다..."

        let hasInitialized = UserDefaults.standard.bool(
            forKey: "hasInitializedCategories"
        )

        if !hasInitialized {
            do {
                let importUseCase =
                    diContainer.makeImportRecommendedCategoriesUseCase()
                try await importUseCase.execute()
                #if !DEBUG
                    UserDefaults.standard.set(
                        true,
                        forKey: "hasInitializedCategories"
                    )
                #endif
            } catch {
                print("error")
            }
        }
    }

    private func checkCurrentMonthBudget() async {
        loadingMessage = "예산을 확인하고 있습니다..."

        do {
            let currentYearMonth = YearMonth.current
            let getBudgetUseCase = diContainer.makeGetMonthlyBudgetUseCase()

            // 현재 월 예산 확인
            let existingBudget = try await getBudgetUseCase.execute(
                yearMonth: currentYearMonth
            )

            // 예산이 이미 있으면 종료
            guard existingBudget == nil else { return }

            // 템플릿 확인
            let getBudgetTemplateUseCase =
                diContainer.makeGetBudgetTemplateUseCase()
            guard let templateDTO = try await getBudgetTemplateUseCase.execute()
            else {
                print("예산 템플릿이 없습니다.")
                return
            }

            // 템플릿으로 현재 월 예산 생성
            loadingMessage = "이번 달 예산을 생성하고 있습니다..."
            let createBudgetUseCase =
                diContainer.makeCreateBudgetFromTemplateUseCase()
            try await createBudgetUseCase.execute(
                template: templateDTO,
                yearMonth: currentYearMonth
            )

            print("현재 월 예산이 템플릿으로부터 생성되었습니다.")
        } catch {
            print("예산 확인/생성 실패: \(error)")
            // 예산 생성 실패해도 앱은 계속 진행
        }
    }

    private func processDueTransactionTemplates() async {
        loadingMessage = "반복 거래를 처리하고 있습니다..."

        do {
            let templateProcessingUseCase = diContainer.makeTransactionTemplateProcessingUseCase()
            let processedCount = try await templateProcessingUseCase.execute(upToDate: Date())

            if processedCount > 0 {
                print("처리된 반복 거래: \(processedCount)개")
            }
        } catch {
            print("반복 거래 처리 실패: \(error)")
            // 반복 거래 처리 실패해도 앱은 계속 진행
        }
    }
}
