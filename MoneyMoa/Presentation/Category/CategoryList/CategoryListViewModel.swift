//
//  CategoryListViewModel.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/25/25.
//

import Foundation
import Observation
import Combine

// MARK: CategoryList의 모드 enum

enum CategoryListMode {
    case selection
    case configuration
}

@Observable
final class CategoryListViewModel {

    private let getCategoriesUseCase: GetCategoriesByTypeUseCase

    private var subCategoryEventPublisher: (any SubCategoryEventPublisher)?

    let mode: CategoryListMode
    var selectedTransactionType: TransactionType
    var categories: [CategoryDTO] = []
    var selectedSubCategory: SubCategoryDTO?

    private var cancellables: Set<AnyCancellable> = []

    init(getCategoriesUseCase: GetCategoriesByTypeUseCase,
         mode: CategoryListMode = .configuration,
    ) {
        self.getCategoriesUseCase = getCategoriesUseCase

        self.mode = mode
        self.selectedTransactionType = mode == .selection ? .variableExpense : .income
    }

    enum Action {
        case onAppear
        case selectTransactionType(TransactionType)
        case selectSubCategory(CategoryDTO, SubCategoryDTO, AppRouter)
        case addSubCategory(CategoryDTO, AppRouter)
        case unsubscribe
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear:
            onAppear()
        case .selectTransactionType(let transactionType):
            handleSelectTransactionType(transactionType)

        case .selectSubCategory(let category, let subCategory, let router):
            handleSelectSubCategory(category: category, subCategory: subCategory, router: router)

        case .addSubCategory(let category, let router):
            addSubCategory(category: category, router: router)

        case .unsubscribe:
            cancellables.removeAll()
            subCategoryEventPublisher = nil
        }
    }

    private func onAppear() {
        if categories.isEmpty {
            Task {
                await fetchCategories()
            }
        }
    }

    private func fetchCategories() async {
        do {
            self.categories = try await getCategoriesUseCase.execute(selectedTransactionType)
        } catch {
            print(error)
        }
    }

    private func handleSelectTransactionType(_ transactionType: TransactionType) {
        self.selectedTransactionType = transactionType
        Task {
            await fetchCategories()
        }
    }

    private func handleSelectSubCategory(category: CategoryDTO, subCategory: SubCategoryDTO, router: AppRouter) {
        if mode == .selection {
            self.selectedSubCategory = subCategory
        } else {
            Task {
                subscribeSubCategoryEvent()
                await router.present(.settings(.subCategoryForm(category, subCategory)), as: .sheet)
            }
        }
    }

    private func addSubCategory(category: CategoryDTO, router: AppRouter) {
        Task {
            subscribeSubCategoryEvent()
            await router.present(.subCategoryForm(category, nil), as: .sheet)
        }
    }

    private func subscribeSubCategoryEvent() {
        self.subCategoryEventPublisher = DefaultSubCategoryEventPublisher.shared
        self.subCategoryEventPublisher?.subCategoryEvents
            .sink(receiveValue: { [weak self] subCategory in
                if self?.selectedTransactionType == subCategory.subCategory.transactionType {
                    Task {
                        await self?.fetchCategories()
                    }
                }
            })
            .store(in: &cancellables)
    }
}
