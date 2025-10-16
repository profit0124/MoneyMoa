//
//  SubCategoryFormViewModel.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/25/25.
//

import Foundation
import Observation
import Combine

@Observable
final class SubCategoryFormViewModel {

    private var createSubCategoryUseCase: CreateSubCategoryUseCase
    private var updateSubCategoryUseCase: UpdateSubCategoryUseCase
    private var deleteSubCategoryUseCase: DeleteSubCategoryUseCase
    private var subCategoryEventPublisher: any SubCategoryEventPublisher

    var selectedCategory: CategoryDTO
    var selectedSubCategoryDTO: SubCategoryDTO?
    var subCategoryName: String = ""
    var showingDeleteConfirmation: Bool = false

    var cancellables: Set<AnyCancellable> = []

    var isValid: Bool {
        !subCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (selectedSubCategoryDTO?.categoryId != selectedCategory.id ||
         (selectedSubCategoryDTO?.name ?? "") != subCategoryName)
    }

    init(createSubCategoryUseCase: CreateSubCategoryUseCase,
         updateSubCategoryUseCase: UpdateSubCategoryUseCase,
         deleteSubCategoryUseCase: DeleteSubCategoryUseCase,
         subCategoryEventPublisher: any SubCategoryEventPublisher,
         selectedCategory: CategoryDTO,
         selectedSubCategory: SubCategoryDTO? = nil
    ) {
        self.createSubCategoryUseCase = createSubCategoryUseCase
        self.updateSubCategoryUseCase = updateSubCategoryUseCase
        self.deleteSubCategoryUseCase = deleteSubCategoryUseCase
        self.subCategoryEventPublisher = subCategoryEventPublisher
        self.selectedCategory = selectedCategory
        self.selectedSubCategoryDTO = selectedSubCategory
        self.subCategoryName = selectedSubCategory?.name ?? ""
    }

    enum Action {
        case submit(AppRouter)
        case showCategorySelector(AppRouter)
        case selectCategory(CategoryDTO)
        case showDeleteConfirmation
        case deleteSubCategory(AppRouter)
        case unsubscribe
    }

    func send(_ action: Action) {
        switch action {
        case .submit(let router):
            submit(router)

        case .showCategorySelector(let router):
            Task {
                subscribeSelectCategoryEventPublisher()
                await router.present(.settings(.categorySelector(selectedCategory)), as: .sheet)
            }

        case .selectCategory(let category):
            self.selectedCategory = category

        case .showDeleteConfirmation:
            showingDeleteConfirmation = true

        case .deleteSubCategory(let router):
            deleteSubCategory(router)

        case .unsubscribe:
            self.cancellables.removeAll()
        }
    }

    private func subscribeSelectCategoryEventPublisher() {
        let publisher = DefaultSelectCategoryEventPublisher.shared

        publisher.selectCategoryEvent
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] in
                self?.send(.selectCategory($0))
            })
            .store(in: &cancellables)
    }

    private func submit(_ router: AppRouter) {
        Task {
            do {
                let trimmedName = subCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)

                if let existingSubCategory = selectedSubCategoryDTO {
                    // 수정 모드
                    let updatedSubCategory = SubCategoryDTO(
                        id: existingSubCategory.id,
                        name: trimmedName,
                        transactionType: selectedCategory.transactionType,
                        categoryId: selectedCategory.id,
                        categoryName: selectedCategory.name,
                        categoryIconName: selectedCategory.iconName
                    )

                    try await updateSubCategoryUseCase.execute(updatedSubCategory)
                    subCategoryEventPublisher.publish(.init(type: .updated, subCategory: updatedSubCategory))
                } else {
                    // 생성 모드
                    let newSubCategory = SubCategoryDTO(
                        id: UUID(),
                        name: trimmedName,
                        transactionType: selectedCategory.transactionType,
                        categoryId: selectedCategory.id,
                        categoryName: selectedCategory.name,
                        categoryIconName: selectedCategory.iconName
                    )

                    try await createSubCategoryUseCase.execute(newSubCategory)
                    subCategoryEventPublisher.publish(.init(type: .created, subCategory: newSubCategory))
                }

                await router.dismissModal()
            } catch {
                print("서브카테고리 처리 실패: \(error.localizedDescription)")
            }
        }
    }

    private func deleteSubCategory(_ router: AppRouter) {
        Task {
            do {
                guard let selectedSubCategory = selectedSubCategoryDTO else { return }

                try await deleteSubCategoryUseCase.execute(selectedSubCategory.id)
                subCategoryEventPublisher.publish(.init(type: .deleted, subCategory: selectedSubCategory))

                await router.dismissModal()
            } catch {
                print("서브카테고리 삭제 실패: \(error.localizedDescription)")
            }
        }
    }
}
