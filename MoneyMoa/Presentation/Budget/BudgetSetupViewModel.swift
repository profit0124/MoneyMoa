//
//  BudgetSetupViewModel.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/22/25.
//

import Foundation
import Observation

enum BudgetSetupViewModelError: Error {
    case noBudgetToUpdate
}

@Observable
final class BudgetSetupViewModel {
    
    // MARK: - Original Data
    var budget: BudgetDTO?

    // MARK: - Form State
    let yearMonth: YearMonth
    var totalAmount: Decimal?
    var categoryBudgets: [CategoryBudgetDTO] = []
    var categories: [CategoryDTO] = []
    
    // MARK: - UI State
    var isLoading: Bool = false
    var errorMessage: String?
    var showError: Bool = false
    var showingCategorySelection: Bool = false
    var showUpdateConfirmation: Bool = false

    // MARK: - Computed Properties
    
    /// 폼 유효성 검사
    var isValid: Bool {
        guard let totalAmount = totalAmount, totalAmount > 0 else { return false }
        guard totalCategoryBudgetTemplate <= totalAmount else { return false }
        guard totalCategoryBudgetTemplate >= 0 else { return false }
        return hasChanges
    }
    
    /// 변경사항이 있는지 확인
    private var hasChanges: Bool {
        let totalAmountChanged = budget?.totalAmount != totalAmount
        let categoryBudgetsChanged = !areEqual(budget?.categoryBudgets ?? [], categoryBudgets)
        return totalAmountChanged || categoryBudgetsChanged
    }
    
    /// 카테고리별 예산 총합
    var totalCategoryBudgetTemplate: Decimal {
        categoryBudgets.reduce(0) { $0 + $1.amount }
    }
    
    /// 남은 예산
    var remainingAmount: Decimal {
        (totalAmount ?? 0) - totalCategoryBudgetTemplate
    }
    
    /// 예산 초과 여부
    var isOverBudget: Bool {
        totalCategoryBudgetTemplate > (totalAmount ?? 0)
    }
    
    /// 추가 가능한 카테고리 목록 (중복 제거)
    var availableCategories: [CategoryDTO] {
        categories.filter { category in
            !categoryBudgets.contains { $0.categoryID == category.id }
        }
    }

    // MARK: - Dependencies
    private let getBudgetUseCase: GetMonthlyBudgetUseCase
    private let getCategoriesByTypeUseCase: GetCategoriesByTypeUseCase
    private let createTemplateFromBudgetUseCase: CreateTemplateFromBudgetUseCase
    private let updateBudgetTemplateUseCase: UpdateTemplateFromBudgetUseCase
    private let createBudgetUseCase: CreateBudgetUseCase
    private let updateBudgetRangeUseCase: UpdateBudgetRangeUseCase
    
    // MARK: - Initialization
    
    init(
        yearMonth: YearMonth = .current,
        getMonthlyBudgetUseCase: GetMonthlyBudgetUseCase,
        getCategoriesByTypeUseCase: GetCategoriesByTypeUseCase,
        createTemplateFromBudgetUseCase: CreateTemplateFromBudgetUseCase,
        updateBudgetTemplateUseCase: UpdateTemplateFromBudgetUseCase,
        createBudgetUseCase: CreateBudgetUseCase,
        updateBudgetRangeUseCase: UpdateBudgetRangeUseCase
    ) {
        self.yearMonth = yearMonth
        self.getBudgetUseCase = getMonthlyBudgetUseCase
        self.getCategoriesByTypeUseCase = getCategoriesByTypeUseCase
        self.createTemplateFromBudgetUseCase = createTemplateFromBudgetUseCase
        self.updateBudgetTemplateUseCase = updateBudgetTemplateUseCase
        self.createBudgetUseCase = createBudgetUseCase
        self.updateBudgetRangeUseCase = updateBudgetRangeUseCase
    }

    // MARK: - Types

    enum UpdateType {
        case withTemplate
        case withoutTemplate
    }

    enum Action {
        case onAppear
        case doneButtonTapped(() -> Void)
        case removeCategoryBudgetDTO(CategoryBudgetDTO)
        case addCategoryBudgets([CategoryDTO])
        case updateCategoryBudgetAmount(CategoryBudgetDTO, Decimal)
        case resetForm
        case updateBudget(UpdateType, () -> Void)
    }

    // MARK: - Public Methods
    
    func send(_ action: Action) {
        switch action {
        case .onAppear:
            handleOnAppear()
        case .doneButtonTapped(let completion):
            if budget != nil {
                showUpdateConfirmation = true
            } else {
                Task {
                    await createBudgetWithTemplate()
                    completion()
                }
            }
        case .removeCategoryBudgetDTO(let categoryBudget):
            removeCategoryBudgetDTO(categoryBudget)
        case .addCategoryBudgets(let categories):
            addCategoryBudget(categories)
        case .updateCategoryBudgetAmount(let categoryBudget, let amount):
            updateCategoryBudgetAmount(categoryBudget, amount)
        case .resetForm:
            resetForm()
        case .updateBudget(let type, let completion):
            Task {
                await handleUpdateBudget(type)
                completion()
            }
        }
    }

    // MARK: - Private Methods
    
    private func handleOnAppear() {
        Task {
            await loadInitialData()
        }
    }
    
    @MainActor
    private func loadInitialData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // 1. Budget Template 불러오기
            budget = try await getBudgetUseCase.execute(yearMonth: yearMonth)

            // 2. 불러온 후 데이터를 Form에 적용
            if let budget = budget {
                totalAmount = budget.totalAmount
                categoryBudgets = budget.categoryBudgets
            }
            
            // 3. Category 정보 불러오기 (지출 카테고리만)
            let variableExpenseCategories = try await getCategoriesByTypeUseCase.execute(.variableExpense)
            let fixedExpenseCategories = try await getCategoriesByTypeUseCase.execute(.fixedExpense)
            categories = (variableExpenseCategories + fixedExpenseCategories).sorted()
            
        } catch {
            errorMessage = "데이터를 불러오는 중 오류가 발생했습니다: \(error.localizedDescription)"
            showError = true
        }
    }
    
    @MainActor
    private func createBudgetWithTemplate() async {
        guard isValid else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let newBudgetDTO = makeBudgetDTOData()
            try await createBudgetTemplate(newBudgetDTO)
            try await createBudget(newBudgetDTO)
        } catch {
            errorMessage = "예산 저장 중 오류가 발생했습니다: \(error.localizedDescription)"
            showError = true
        }
    }

    private func handleUpdateBudget(_ updateType: UpdateType) async {
        guard isValid else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            if updateType == .withTemplate {
                try await updateBudgetTemplate()
            }
            try await updateBudget()
        } catch {
            errorMessage = "예산 수정 중 오류가 발생했습니다: \(error.localizedDescription)"
            showError = true
        }
    }

    // MARK: BudgetTemplate + CategoryBudgetTemplate

    private func createBudgetTemplate(_ budget: BudgetDTO) async throws {
        try await createTemplateFromBudgetUseCase.execute(budget)
    }
    
    private func updateBudgetTemplate() async throws {
        guard let existingBudget = budget else { throw BudgetSetupViewModelError.noBudgetToUpdate }

        let updatedTemplate = BudgetDTO(
            id: existingBudget.id,
            month: existingBudget.month,
            totalAmount: totalAmount ?? 0,
            categoryBudgets: categoryBudgets
        )

        try await updateBudgetTemplateUseCase.execute(updatedTemplate)
    }

    // MARK: Budget + CategoryBudget

    private func createBudget(_ budget: BudgetDTO) async throws {
        self.budget = try await createBudgetUseCase.execute(budget)
    }
    
    private func updateBudget() async throws {
        guard let existingBudget = budget else { throw BudgetSetupViewModelError.noBudgetToUpdate }

        let updateBudget = BudgetDTO(
            id: existingBudget.id,
            month: existingBudget.month,
            totalAmount: totalAmount ?? 0,
            categoryBudgets: categoryBudgets
        )

        // UpdateBudgetUseCase를 통해 현재 월 예산 업데이트
        try await updateBudgetRangeUseCase.execute(from: yearMonth, budget: updateBudget)
    }

    private func addCategoryBudget(_ categories: [CategoryDTO]) {
        let newBudgets = categories.map { category in
            CategoryBudgetDTO(
                id: UUID(),
                amount: 0,
                categoryID: category.id,
                categoryName: category.name,
                budgetId: UUID() // 임시 ID
            )
        }
        categoryBudgets.append(contentsOf: newBudgets)
    }
    
    private func updateCategoryBudgetAmount(_ categoryBudget: CategoryBudgetDTO, _ amount: Decimal) {
        if let index = categoryBudgets.firstIndex(where: { $0.id == categoryBudget.id }) {
            var updatedBudget = categoryBudgets[index]
            updatedBudget = CategoryBudgetDTO(
                id: updatedBudget.id,
                amount: amount,
                categoryID: updatedBudget.categoryID,
                categoryName: updatedBudget.categoryName,
                budgetId: updatedBudget.budgetId
            )
            categoryBudgets[index] = updatedBudget
        }
    }

    private func removeCategoryBudgetDTO(_ categoryBudget: CategoryBudgetDTO) {
        categoryBudgets.removeAll { $0.id == categoryBudget.id }
    }

    private func resetForm() {
        totalAmount = nil
        categoryBudgets.removeAll()
        errorMessage = nil
        showError = false
    }

    private func makeBudgetDTOData() -> BudgetDTO {
        BudgetDTO(
            id: UUID(),
            month: yearMonth,
            totalAmount: totalAmount ?? 0,
            categoryBudgets: categoryBudgets
        )
    }

    // MARK: - Helper Methods
    
    /// 배열의 순서를 무시하고 내용이 같은지 비교
    private func areEqual(_ lhs: [CategoryBudgetDTO], _ rhs: [CategoryBudgetDTO]) -> Bool {
        guard lhs.count == rhs.count else { return false }
        
        let lhsSet = Set(lhs.map { "\($0.categoryID)_\($0.amount)" })
        let rhsSet = Set(rhs.map { "\($0.categoryID)_\($0.amount)" })
        
        return lhsSet == rhsSet
    }
}
