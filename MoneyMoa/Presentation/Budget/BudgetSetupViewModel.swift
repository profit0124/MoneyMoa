//
//  BudgetSetupViewModel.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/22/25.
//

import Foundation
import Observation

@Observable
final class BudgetSetupViewModel {
    
    // MARK: - Original Data
    var budget: BudgetTemplateDTO?

    // MARK: - Form State
    var totalAmount: Decimal?
    var categoryBudgetTemplates: [CategoryBudgetTemplateDTO] = []
    var categories: [CategoryDTO] = []
    
    // MARK: - UI State
    var isLoading: Bool = false
    var errorMessage: String?
    var showError: Bool = false

    // MARK: - Computed Properties
    
    /// 폼 유효성 검사
    var isValid: Bool {
        guard let totalAmount = totalAmount, totalAmount > 0 else { return false }
        guard totalCategoryBudgetTemplate <= totalAmount else { return false }
        guard totalCategoryBudgetTemplate > 0 else { return false }
        return hasChanges
    }
    
    /// 변경사항이 있는지 확인
    private var hasChanges: Bool {
        let totalAmountChanged = budget?.totalAmount != totalAmount
        let categoryBudgetsChanged = !areEqual(budget?.categoryBudgetTemplates ?? [], categoryBudgetTemplates)
        return totalAmountChanged || categoryBudgetsChanged
    }
    
    /// 카테고리별 예산 총합
    var totalCategoryBudgetTemplate: Decimal {
        categoryBudgetTemplates.reduce(0) { $0 + $1.amount }
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
            !categoryBudgetTemplates.contains { $0.categoryID == category.id }
        }
    }

    // MARK: - Types
    
    enum CreateBudgetType {
        case create                    // 최초 생성
        case updateWithTemplate       // 템플릿 포함 업데이트 
        case updateWithoutTemplate    // 현재월만 업데이트
    }

    enum Action {
        case onAppear
        case createBudgetTemplate
        case deleteCategoryBudgetTemplate(CategoryBudgetTemplateDTO)
        case addCategoryBudgetTemplate([CategoryDTO])
        case updateCategoryBudgetAmount(CategoryBudgetTemplateDTO, Decimal)
        case resetForm
    }
    
    // MARK: - Dependencies (TODO: DI Container에서 주입받도록 수정 예정)
    // private let getBudgetTemplateUseCase: GetBudgetTemplateUseCase
    // private let getCategoriesByTypeUseCase: GetCategoriesByTypeUseCase  
    // private let createBudgetTemplateUseCase: CreateBudgetTemplateUseCase
    // private let updateBudgetTemplateUseCase: UpdateBudgetTemplateUseCase
    // private let createBudgetFromTemplateUseCase: CreateBudgetFromTemplateUseCase

    // MARK: - Public Methods
    
    func send(_ action: Action) {
        switch action {
        case .onAppear:
            handleOnAppear()
        case .createBudgetTemplate:
            Task {
                await handleCreateBudgetTemplate()
            }
        case .deleteCategoryBudgetTemplate(let template):
            deleteCategoryBudgetTemplate(template)
        case .addCategoryBudgetTemplate(let categories):
            addCategoryBudgetTemplate(categories)
        case .updateCategoryBudgetAmount(let template, let amount):
            updateCategoryBudgetAmount(template, amount)
        case .resetForm:
            resetForm()
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
            // TODO: UseCase 구현 후 연결
            // 1. Budget Template 불러오기
            // budget = try await getBudgetTemplateUseCase.execute()
            
            // 2. 불러온 후 데이터를 Form에 적용
            // if let budget = budget {
            //     totalAmount = budget.totalAmount
            //     categoryBudgetTemplates = budget.categoryBudgetTemplates
            // }
            
            // 3. Category 정보 불러오기 (지출 카테고리만)
            // let variableExpenseCategories = try await getCategoriesByTypeUseCase.execute(.variableExpense)
            // let fixedExpenseCategories = try await getCategoriesByTypeUseCase.execute(.fixedExpense)
            // categories = (variableExpenseCategories + fixedExpenseCategories).sorted()
            
        } catch {
            errorMessage = "데이터를 불러오는 중 오류가 발생했습니다: \(error.localizedDescription)"
            showError = true
        }
    }
    
    @MainActor
    private func handleCreateBudgetTemplate() async {
        guard isValid else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let type = determineBudgetType()
            
            switch type {
            case .create:
                try await createBudgetTemplate()
                try await createBudgetFromTemplate()
                
            case .updateWithTemplate:
                try await updateBudgetTemplate()
                try await updateCurrentMonthBudget()
                
            case .updateWithoutTemplate:
                try await updateCurrentMonthBudget()
            }
            
        } catch {
            errorMessage = "예산 저장 중 오류가 발생했습니다: \(error.localizedDescription)"
            showError = true
        }
    }
    
    private func determineBudgetType() -> CreateBudgetType {
        if budget == nil {
            return .create
        }
        
        // TODO: 사용자 선택에 따른 분기 로직 구현
        // 현재는 임시로 updateWithTemplate 반환
        return .updateWithTemplate
    }
    
    private func createBudgetTemplate() async throws {
        // TODO: UseCase 구현 후 연결
        // let templateDTO = BudgetTemplateDTO(
        //     totalAmount: totalAmount ?? 0,
        //     categoryBudgetTemplates: categoryBudgetTemplates
        // )
        // budget = try await createBudgetTemplateUseCase.execute(templateDTO)
    }
    
    private func updateBudgetTemplate() async throws {
        guard let existingBudget = budget else { return }
        
        // TODO: UseCase 구현 후 연결
        // let updatedTemplate = BudgetTemplateDTO(
        //     id: existingBudget.id,
        //     totalAmount: totalAmount ?? 0,
        //     categoryBudgetTemplates: categoryBudgetTemplates
        // )
        // budget = try await updateBudgetTemplateUseCase.execute(updatedTemplate)
    }
    
    private func createBudgetFromTemplate() async throws {
        guard let budget = budget else { return }
        
        // TODO: UseCase 구현 후 연결
        // let currentYearMonth = YearMonth.current
        // try await createBudgetFromTemplateUseCase.execute(
        //     template: budget,
        //     yearMonth: currentYearMonth
        // )
    }
    
    private func updateCurrentMonthBudget() async throws {
        // TODO: UseCase 구현 후 연결
        // let currentYearMonth = YearMonth.current
        // let budgetDTO = BudgetDTO(
        //     month: currentYearMonth,
        //     totalAmount: totalAmount ?? 0,
        //     categoryBudgets: categoryBudgetTemplates.map { /* CategoryBudgetDTO 변환 */ }
        // )
        // try await updateBudgetUseCase.execute(for: currentYearMonth, budget: budgetDTO)
    }
    
    private func deleteCategoryBudgetTemplate(_ template: CategoryBudgetTemplateDTO) {
        categoryBudgetTemplates.removeAll { $0.id == template.id }
    }

    private func addCategoryBudgetTemplate(_ categories: [CategoryDTO]) {
        let newTemplates = categories.map { category in
            CategoryBudgetTemplateDTO(
                amount: 0,
                categoryID: category.id,
                categoryName: category.name,
                budgetTemplateId: UUID() // 임시 ID
            )
        }
        categoryBudgetTemplates.append(contentsOf: newTemplates)
    }
    
    private func updateCategoryBudgetAmount(_ template: CategoryBudgetTemplateDTO, _ amount: Decimal) {
        if let index = categoryBudgetTemplates.firstIndex(where: { $0.id == template.id }) {
            var updatedTemplate = categoryBudgetTemplates[index]
            updatedTemplate = CategoryBudgetTemplateDTO(
                id: updatedTemplate.id,
                amount: amount,
                categoryID: updatedTemplate.categoryID,
                categoryName: updatedTemplate.categoryName,
                budgetTemplateId: updatedTemplate.budgetTemplateId
            )
            categoryBudgetTemplates[index] = updatedTemplate
        }
    }
    
    private func resetForm() {
        totalAmount = nil
        categoryBudgetTemplates.removeAll()
        errorMessage = nil
        showError = false
    }

    // MARK: - Helper Methods
    
    /// 배열의 순서를 무시하고 내용이 같은지 비교
    private func areEqual(_ lhs: [CategoryBudgetTemplateDTO], _ rhs: [CategoryBudgetTemplateDTO]) -> Bool {
        guard lhs.count == rhs.count else { return false }
        
        let lhsSet = Set(lhs.map { "\($0.categoryID)_\($0.amount)" })
        let rhsSet = Set(rhs.map { "\($0.categoryID)_\($0.amount)" })
        
        return lhsSet == rhsSet
    }
}
