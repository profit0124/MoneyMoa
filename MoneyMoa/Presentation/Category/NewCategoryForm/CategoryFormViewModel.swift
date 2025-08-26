//
//  CategoryFormViewModel.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/26/25.
//

import Foundation
import Observation

@Observable
final class CategoryFormViewModel {

    // MARK: UseCase
    private var createCategoryUseCase: CreateCategoryUseCase
    private var createSubCategoryUseCase: CreateSubCategoryUseCase
    private var updateCategoryUseCase: UpdateCategoryUseCase
    private var categoryEventPublisher: any CategoryEventPublisher

    let mode: CategoryListMode
    private let id: UUID
    var selectedTransactionType: TransactionType
    var selectedCategory: CategoryDTO?
    var categoryName: String
    var categoryIconName: String?
    var newSubCategoryName: String
    var subCategories: [SubCategoryDTO]
    var addedSubCategories: [SubCategoryDTO] = []
    
    // Alert 관련 상태
    var showingAddSubCategoryAlert: Bool = false
    var alertErrorMessage: String?

    var isChanged: Bool = false

    var isValid: Bool {
        let basicValidation = !categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
                             !(categoryIconName ?? "").isEmpty
        
        if mode == .selection {
            // Selection 모드: 카테고리 + 서브카테고리 1개 필수 (기존 CategoryFormViewModel과 동일)
            return basicValidation && !newSubCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } else {
            // Configuration 모드
            if selectedCategory != nil {
                // Update 모드: 기본 검증 + 변경사항 존재
                return basicValidation && hasChanges
            } else {
                // Create 모드: 기본 검증만 (서브카테고리는 선택사항)
                return basicValidation
            }
        }
    }
    
    private var hasChanges: Bool {
        guard let selectedCategory = selectedCategory else { return true }
        return selectedTransactionType != selectedCategory.transactionType ||
               categoryName.trimmingCharacters(in: .whitespacesAndNewlines) != selectedCategory.name ||
               categoryIconName != selectedCategory.iconName ||
               !addedSubCategories.isEmpty
    }

    init(createCategoryUseCase: CreateCategoryUseCase,
         createSubCategoryUseCase: CreateSubCategoryUseCase,
         updateCategoryUseCase: UpdateCategoryUseCase,
         categoryEventPublisher: any CategoryEventPublisher,
         mode: CategoryListMode,
         selectedTransactionType: TransactionType = .income,
         selectedCategory: CategoryDTO? = nil
    ) {
        self.createCategoryUseCase = createCategoryUseCase
        self.createSubCategoryUseCase = createSubCategoryUseCase
        self.updateCategoryUseCase = updateCategoryUseCase
        self.categoryEventPublisher = categoryEventPublisher
        self.mode = mode
        self.id = selectedCategory?.id ?? UUID()
        self.selectedTransactionType = selectedCategory?.transactionType ?? selectedTransactionType
        self.selectedCategory = selectedCategory
        self.categoryName = selectedCategory?.name ?? ""
        self.categoryIconName = selectedCategory?.iconName ?? ""
        // selectedCategory가 nil 이면 자동으로 바로 추가형태
        self.newSubCategoryName = ""
        self.subCategories = selectedCategory?.subCategories ?? []
    }

    enum Action {
        case tappedSubmitButton(AppRouter)
        case showAddSubCategoryAlert
        case addSubCategory
        case cancelAddSubCategory
        case handleError(Error)
    }

    func send(_ action: Action) {
        switch action {
        case .tappedSubmitButton(let router):
            handleTappedSubmitButton(router)

        case .showAddSubCategoryAlert:
            showingAddSubCategoryAlert = true
            
        case .addSubCategory:
            addSubCategory()

        case .cancelAddSubCategory:
            cancelAddSubCategory()

        case .handleError(let error):
            handleError(error)
        }
    }

    private func handleTappedSubmitButton(_ router: AppRouter) {
        Task {
            do {
                guard let categoryIconName = categoryIconName else { return }
                
                let trimmedCategoryName = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if mode == .selection {
                    // Selection 모드: 카테고리 + 서브카테고리 1개 생성 (기존 CategoryFormViewModel과 동일)
                    try await handleSelectionMode(categoryIconName: categoryIconName, categoryName: trimmedCategoryName)
                } else {
                    // Configuration 모드: Create/Update
                    if let selectedCategory = selectedCategory {
                        try await handleUpdateMode(selectedCategory: selectedCategory, categoryIconName: categoryIconName, categoryName: trimmedCategoryName)
                    } else {
                        // Create 모드: 카테고리 + 여러 서브카테고리 생성
                        try await handleCreateMode(categoryIconName: categoryIconName, categoryName: trimmedCategoryName)
                    }
                }
                
                await router.dismissModal()
            } catch {
                self.send(.handleError(error))
            }
        }
    }
    
    private func handleSelectionMode(categoryIconName: String, categoryName: String) async throws {
        // 카테고리 생성
        let category = CategoryDTO(
            id: id,
            name: categoryName,
            iconName: categoryIconName,
            transactionType: selectedTransactionType,
            subCategories: []
        )
        try await createCategoryUseCase.execute(category)
        
        // 서브카테고리 1개 생성 (필수)
        let trimmedSubCategoryName = newSubCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        let subCategory = SubCategoryDTO(
            name: trimmedSubCategoryName,
            transactionType: selectedTransactionType,
            categoryId: id,
            categoryName: categoryName,
            categoryIconName: categoryIconName
        )
        try await createSubCategoryUseCase.execute(subCategory)
        
        // 서브카테고리가 포함된 카테고리로 업데이트하여 이벤트 발행
        let categoryWithSubCategory = CategoryDTO(
            id: id,
            name: categoryName,
            iconName: categoryIconName,
            transactionType: selectedTransactionType,
            subCategories: [subCategory]
        )
        categoryEventPublisher.publish(.init(type: .created, category: categoryWithSubCategory))
    }
    
    private func handleCreateMode(categoryIconName: String, categoryName: String) async throws {
        // 카테고리 생성
        let category = CategoryDTO(
            id: id,
            name: categoryName,
            iconName: categoryIconName,
            transactionType: selectedTransactionType,
            subCategories: []
        )
        try await createCategoryUseCase.execute(category)
        
        var createdSubCategories: [SubCategoryDTO] = []
        
        // 추가된 서브카테고리들 생성
        for subCategory in addedSubCategories {
            let newSubCategory = SubCategoryDTO(
                id: subCategory.id,
                name: subCategory.name,
                transactionType: selectedTransactionType,
                categoryId: id,
                categoryName: categoryName,
                categoryIconName: categoryIconName
            )
            try await createSubCategoryUseCase.execute(newSubCategory)
            createdSubCategories.append(newSubCategory)
        }
        
        // 입력 필드의 서브카테고리가 있다면 생성 (선택사항)
        let trimmedSubCategoryName = newSubCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedSubCategoryName.isEmpty {
            let subCategory = SubCategoryDTO(
                name: trimmedSubCategoryName,
                transactionType: selectedTransactionType,
                categoryId: id,
                categoryName: categoryName,
                categoryIconName: categoryIconName
            )
            try await createSubCategoryUseCase.execute(subCategory)
            createdSubCategories.append(subCategory)
        }
        
        // 생성된 서브카테고리들이 포함된 카테고리로 이벤트 발행
        let categoryWithSubCategories = CategoryDTO(
            id: id,
            name: categoryName,
            iconName: categoryIconName,
            transactionType: selectedTransactionType,
            subCategories: createdSubCategories
        )
        categoryEventPublisher.publish(.init(type: .created, category: categoryWithSubCategories))
    }
    
    private func handleUpdateMode(selectedCategory: CategoryDTO, categoryIconName: String, categoryName: String) async throws {
        // 카테고리 정보 업데이트
        let updatedCategory = CategoryDTO(
            id: selectedCategory.id,
            name: categoryName,
            iconName: categoryIconName,
            transactionType: selectedTransactionType,
            isActive: selectedCategory.isActive,
            orderIndex: selectedCategory.orderIndex,
            subCategories: selectedCategory.subCategories
        )
        
        try await updateCategoryUseCase.execute(updatedCategory)
        
        var newSubCategories: [SubCategoryDTO] = []
        
        // 새로 추가된 서브카테고리들 생성
        for subCategory in addedSubCategories {
            let newSubCategory = SubCategoryDTO(
                id: subCategory.id,
                name: subCategory.name,
                transactionType: selectedTransactionType,
                categoryId: selectedCategory.id,
                categoryName: categoryName,
                categoryIconName: categoryIconName
            )
            try await createSubCategoryUseCase.execute(newSubCategory)
            newSubCategories.append(newSubCategory)
        }
        
        // 입력 필드의 서브카테고리가 있다면 생성 (선택사항)
        let trimmedSubCategoryName = newSubCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedSubCategoryName.isEmpty {
            let subCategory = SubCategoryDTO(
                name: trimmedSubCategoryName,
                transactionType: selectedTransactionType,
                categoryId: selectedCategory.id,
                categoryName: categoryName,
                categoryIconName: categoryIconName
            )
            try await createSubCategoryUseCase.execute(subCategory)
            newSubCategories.append(subCategory)
        }
        
        // 기존 서브카테고리 + 새로 추가된 서브카테고리를 포함한 업데이트된 카테고리로 이벤트 발행
        let updatedCategoryWithSubCategories = CategoryDTO(
            id: selectedCategory.id,
            name: categoryName,
            iconName: categoryIconName,
            transactionType: selectedTransactionType,
            isActive: selectedCategory.isActive,
            orderIndex: selectedCategory.orderIndex,
            subCategories: selectedCategory.subCategories + newSubCategories
        )
        categoryEventPublisher.publish(.init(type: .updated, category: updatedCategoryWithSubCategories))
    }

    private func addSubCategory() {
        let trimmedName = newSubCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 빈 이름 검증
        guard !trimmedName.isEmpty else {
            alertErrorMessage = "서브카테고리명을 입력해주세요."
            return
        }
        
        // 중복 검사: 기존 서브카테고리와 추가된 서브카테고리 모두 확인
        let isDuplicateInExisting = subCategories.contains { $0.name.lowercased() == trimmedName.lowercased() }
        let isDuplicateInAdded = addedSubCategories.contains { $0.name.lowercased() == trimmedName.lowercased() }
        
        if isDuplicateInExisting || isDuplicateInAdded {
            alertErrorMessage = "이미 존재하는 서브카테고리명입니다."
            return
        }
        
        // 서브카테고리 추가
        let subCategory = SubCategoryDTO(
            name: trimmedName,
            transactionType: selectedTransactionType,
            categoryId: id,
            categoryName: categoryName,
            categoryIconName: categoryIconName ?? ""
        )
        addedSubCategories.append(subCategory)
        
        // Alert 닫기 및 초기화
        showingAddSubCategoryAlert = false
        newSubCategoryName = ""
        alertErrorMessage = nil
    }
    
    private func cancelAddSubCategory() {
        // Alert 닫기 및 입력 내용 초기화
        showingAddSubCategoryAlert = false
        newSubCategoryName = ""
        alertErrorMessage = nil
    }

    private func handleError(_ error: Error) {
        print(error.localizedDescription)
    }
}
