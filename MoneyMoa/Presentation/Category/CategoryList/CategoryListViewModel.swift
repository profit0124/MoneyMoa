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
    private var categoryEventPublisher: (any CategoryEventPublisher)?

    let mode: CategoryListMode
    var selectedTransactionType: TransactionType
    var categories: [CategoryDTO] = []
    var selectedSubCategory: SubCategoryDTO?

    private var cancellables: Set<AnyCancellable> = []

    init(getCategoriesUseCase: GetCategoriesByTypeUseCase,
         categoryEventPublisher: (any CategoryEventPublisher)? = nil,
         mode: CategoryListMode = .configuration,
    ) {
        self.getCategoriesUseCase = getCategoriesUseCase
        self.categoryEventPublisher = categoryEventPublisher

        self.mode = mode
        self.selectedTransactionType = mode == .selection ? .variableExpense : .income
        
        setupCategoryEventSubscription()
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
    
    private func setupCategoryEventSubscription() {
        guard let categoryEventPublisher = categoryEventPublisher else { return }
        
        categoryEventPublisher.categoryEvents
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] categoryEvent in
                guard let self = self else { return }
                
                switch categoryEvent.type {
                case .created:
                    if self.mode == .selection {
                        self.send(.selectTransactionType(categoryEvent.category.transactionType))
                        self.selectedSubCategory = categoryEvent.category.subCategories.first
                    } else {
                        // 같은 거래 유형인 경우에만 카테고리 목록 갱신
                        if self.selectedTransactionType == categoryEvent.category.transactionType {
                            Task {
                                await self.fetchCategories()
                            }
                        }
                    }
                case .updated:
                    Task {
                        await self.fetchCategories()
                    }
                case .deleted:
                    // 삭제된 카테고리를 목록에서 제거
                    self.categories.removeAll { $0.id == categoryEvent.category.id }
                }
            })
            .store(in: &cancellables)
    }
}
