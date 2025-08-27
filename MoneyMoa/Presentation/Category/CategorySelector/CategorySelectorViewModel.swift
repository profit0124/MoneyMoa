//
//  CategorySelectorViewModel.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/25/25.
//

import Foundation

@Observable
final class CategorySelectorViewModel: Identifiable {

    private let getCategoriesByTypeUseCase: GetCategoriesByTypeUseCase

    let id: UUID = UUID()
    var selectedCategory: CategoryDTO
    var categories: [CategoryDTO] = []
    var isLoading = false
    private var selectCategoryPublisher: SelectCategoryEventPublisher
    
    var categoriesByTransactionType: [TransactionType: [CategoryDTO]] {
        Dictionary(grouping: categories, by: \.transactionType)
    }

    init(
        getCategoriesByTypeUseCase: GetCategoriesByTypeUseCase,
        selectedCategory: CategoryDTO,
        selectCategoryPublisher: SelectCategoryEventPublisher
    ) {
        self.getCategoriesByTypeUseCase = getCategoriesByTypeUseCase
        self.selectedCategory = selectedCategory
        self.selectCategoryPublisher = selectCategoryPublisher
    }

    enum Action {
        case onAppear
        case selectCategory(CategoryDTO, AppRouter)
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear:
            fetchCategories()

        case .selectCategory(let category, let router):
            selectCategory(category, router)
        }
    }

    private func fetchCategories() {
        guard !isLoading else { return }
        
        Task {
            do {
                isLoading = true
                var allCategories: [CategoryDTO] = []
                
                // 모든 TransactionType에 대해 카테고리 조회
                for transactionType in TransactionType.allCases {
                    let categoriesForType = try await getCategoriesByTypeUseCase.execute(transactionType)
                    allCategories.append(contentsOf: categoriesForType)
                }
                
                self.categories = allCategories
            } catch {
                print("Failed to fetch categories: \(error)")
            }
            isLoading = false
        }
    }

    private func selectCategory(_ category: CategoryDTO, _ router: AppRouter) {
        Task {
            self.selectedCategory = category
            selectCategoryPublisher.publish(category)
            await router.dismissModal()
        }
    }

}
