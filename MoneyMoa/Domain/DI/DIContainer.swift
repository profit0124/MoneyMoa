//
//  DIContainer.swift
//  MoneyMoa
//
//  Created by Claude on 8/5/25.
//

import Foundation

// MARK: - DIContainer Protocol

/// 의존성 주입을 위한 컨테이너 프로토콜
/// Presentation Layer에서 이 프로토콜을 사용하여 의존성을 주입받습니다
protocol DIContainer {
    
    // MARK: - ViewModel Factory Methods
    
    /// MainViewModel을 생성합니다
    func makeMainViewModel() -> MainViewModel
    
    // MARK: - UseCase Factory Methods
    
    /// GetMonthlyTransactionsUseCase를 생성합니다
    func makeGetMonthlyTransactionsUseCase() -> GetMonthlyTransactionsUseCase
    
    /// GetExpenseSumUntilDateUseCase를 생성합니다
    func makeGetExpenseSumUntilDateUseCase() -> GetExpenseSumUntilDateUseCase
    
    /// GetMonthlyBudgetUseCase를 생성합니다
    func makeGetMonthlyBudgetUseCase() -> GetMonthlyBudgetUseCase
    
    /// GetBudgetTemplateUseCase를 생성합니다
    func makeGetBudgetTemplateUseCase() -> GetBudgetTemplateUseCase
    
    /// CreateBudgetFromTemplateUseCase를 생성합니다
    func makeCreateBudgetFromTemplateUseCase() -> CreateBudgetFromTemplateUseCase
    
    // MARK: - Transaction UseCase Factory Methods
    
    /// CreateTransactionUseCase를 생성합니다
    func makeCreateTransactionUseCase() -> CreateTransactionUseCase
    
    /// GetFavoriteTransactionsUseCase를 생성합니다
    func makeGetFavoriteTransactionsUseCase() -> GetFavoriteTransactionsUseCase
    
    // MARK: - Category UseCase Factory Methods
    
    /// GetCategoriesByTypeUseCase를 생성합니다
    func makeGetCategoriesByTypeUseCase() -> GetCategoriesByTypeUseCase
    
    /// CreateCategoryUseCase를 생성합니다
    func makeCreateCategoryUseCase() -> CreateCategoryUseCase
    
    /// CreateSubCategoryUseCase를 생성합니다
    func makeCreateSubCategoryUseCase() -> CreateSubCategoryUseCase
    
    // MARK: - PaymentMethod UseCase Factory Methods
    
    /// GetActivePaymentMethodsUseCase를 생성합니다
    func makeGetActivePaymentMethodsUseCase() -> GetActivePaymentMethodsUseCase
    
    /// CreatePaymentMethodUseCase를 생성합니다
    func makeCreatePaymentMethodUseCase() -> CreatePaymentMethodUseCase
    
    // MARK: - ViewModel Factory Methods
    
    /// AddTransactionViewModel을 생성합니다
    func makeAddTransactionViewModel() -> AddTransactionViewModel
    
    // MARK: - TransactionForm ViewModel Factory Methods
    
    /// AmountPlacePaymentMethodFormViewModel을 생성합니다
    func makeAmountPlacePaymentMethodFormViewModel() -> AmountPlacePaymentMethodFormViewModel
    
    /// TransactionTypeCategoryFormViewModel을 생성합니다
    func makeTransactionTypeCategoryFormViewModel() -> TransactionTypeCategoryFormViewModel
    
    /// DateAdditionalFormViewModel을 생성합니다
    func makeDateAdditionalFormViewModel() -> DateAdditionalFormViewModel
}

// MARK: - Default Implementation

extension DIContainer {
    
    /// MainViewModel을 생성합니다 (기본 구현)
    /// 모든 필요한 UseCase들을 주입하여 MainViewModel을 생성합니다
    func makeMainViewModel() -> MainViewModel {
        return MainViewModel(
            getMonthlyTransactionsUseCase: makeGetMonthlyTransactionsUseCase(),
            getExpenseSumUntilDateUseCase: makeGetExpenseSumUntilDateUseCase(),
            getMonthlyBudgetUseCase: makeGetMonthlyBudgetUseCase(),
            getBudgetTemplateUseCase: makeGetBudgetTemplateUseCase(),
            createBudgetFromTemplateUseCase: makeCreateBudgetFromTemplateUseCase()
        )
    }
    
    // MARK: - TransactionForm ViewModel Default Implementation
    
    /// AmountPlacePaymentMethodFormViewModel을 생성합니다 (기본 구현)
    func makeAmountPlacePaymentMethodFormViewModel() -> AmountPlacePaymentMethodFormViewModel {
        return AmountPlacePaymentMethodFormViewModel(
            getActivePaymentMethodsUseCase: makeGetActivePaymentMethodsUseCase(),
            createPaymentMethodUseCase: makeCreatePaymentMethodUseCase()
        )
    }
    
    /// TransactionTypeCategoryFormViewModel을 생성합니다 (기본 구현)
    func makeTransactionTypeCategoryFormViewModel() -> TransactionTypeCategoryFormViewModel {
        return TransactionTypeCategoryFormViewModel(
            getCategoriesByTypeUseCase: makeGetCategoriesByTypeUseCase(),
            createCategoryUseCase: makeCreateCategoryUseCase(),
            createSubCategoryUseCase: makeCreateSubCategoryUseCase()
        )
    }
    
    /// DateAdditionalFormViewModel을 생성합니다 (기본 구현)
    func makeDateAdditionalFormViewModel() -> DateAdditionalFormViewModel {
        return DateAdditionalFormViewModel()
    }
}
