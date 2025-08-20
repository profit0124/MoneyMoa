//
//  CategoryFormView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/18/25.
//

import Foundation
import Observation
import Combine

@Observable
final class CategoryFormViewModel: Identifiable {
    let id = UUID()
    private let createCategoryUseCase: CreateCategoryUseCase
    private let createSubCategoryUseCase: CreateSubCategoryUseCase

    let transactionType: TransactionType
    var category: CategoryDTO?

    var categoryName: String
    var subCategoryName: String
    var selectedCategoryIconName: String
    let availableCategoryIconNames: [String] = [
        "house.fill", "car.fill", "fork.knife", "gamecontroller.fill",
        "bag.fill", "creditcard.fill", "heart.fill", "star.fill",
        "book.fill", "music.note", "camera.fill", "bicycle",
        "airplane", "tram.fill", "bus.fill", "fuelpump.fill"
    ]

    var createPublisher = PassthroughSubject<SubCategoryDTO, Never>()

    var isValid: Bool {
        if category == nil {
            !categoryName.isEmpty && !subCategoryName.isEmpty
        } else {
            !subCategoryName.isEmpty
        }
    }

    init(
        createCategoryUseCase: CreateCategoryUseCase,
        createSubCategoryUseCase: CreateSubCategoryUseCase,
        transactionType: TransactionType,
        category: CategoryDTO?,
        subCategoryName: String = ""
    ) {
        self.createCategoryUseCase = createCategoryUseCase
        self.createSubCategoryUseCase = createSubCategoryUseCase
        self.transactionType = transactionType
        self.category = category
        self.categoryName = category?.name ?? ""
        self.subCategoryName = subCategoryName
        self.selectedCategoryIconName = category?.iconName ?? availableCategoryIconNames[0]
    }

    enum Action {
        case setSelectedCategoryIconName(String)
        case createCategory
    }

    func send(_ action: Action) {
        switch action {
        case .createCategory:
            Task {
                do {
                    try await createCategory()
                } catch {

                }
            }
        case .setSelectedCategoryIconName(let name):
            setSelectedCategoryIconName(name)
        }
    }

    private func setSelectedCategoryIconName(_ name: String) {
        selectedCategoryIconName = name
    }

    private func createCategory() async throws {
        var categoryDTO: CategoryDTO
        if category == nil {
            categoryDTO = CategoryDTO(name: categoryName, iconName: selectedCategoryIconName, transactionType: transactionType)
            try await createCategoryUseCase.execute(categoryDTO)
        } else {
            categoryDTO = category!
        }

        let subCategoryDTO = SubCategoryDTO(name: subCategoryName, transactionType: transactionType, categoryId: categoryDTO.id, categoryIconName: categoryDTO.iconName)
        try await createSubCategoryUseCase.execute(subCategoryDTO)

        createPublisher.send(subCategoryDTO)
    }
}
