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
    
    /// CreateBudgetTemplateUseCase를 생성합니다
    func makeCreateBudgetTemplateUseCase() -> CreateBudgetTemplateUseCase
    
    /// UpdateBudgetTemplateUseCase를 생성합니다
    func makeUpdateBudgetTemplateUseCase() -> UpdateBudgetTemplateUseCase
    
    /// UpdateBudgetUseCase를 생성합니다
    func makeUpdateBudgetUseCase() -> UpdateBudgetUseCase
    
    // MARK: - Transaction UseCase Factory Methods
    
    /// CreateTransactionUseCase를 생성합니다
    func makeCreateTransactionUseCase() -> CreateTransactionUseCase
    
    /// GetFavoriteTransactionsUseCase를 생성합니다
    func makeGetFavoriteTransactionsUseCase() -> GetFavoriteTransactionsUseCase
    
    /// DeleteTransactionUseCase를 생성합니다
    func makeDeleteTransactionUseCase() -> DeleteTransactionUseCase
    
    /// UpdateTransactionUseCase를 생성합니다
    func makeUpdateTransactionUseCase() -> UpdateTransactionUseCase
    
    /// GetTransactionByIdUseCase를 생성합니다
    func makeGetTransactionByIdUseCase() -> GetTransactionByIdUseCase
    
    // MARK: - Category UseCase Factory Methods
    
    /// GetCategoriesByTypeUseCase를 생성합니다
    func makeGetCategoriesByTypeUseCase() -> GetCategoriesByTypeUseCase
    
    /// CreateCategoryUseCase를 생성합니다
    func makeCreateCategoryUseCase() -> CreateCategoryUseCase
    
    /// CreateSubCategoryUseCase를 생성합니다
    func makeCreateSubCategoryUseCase() -> CreateSubCategoryUseCase
    
    /// ImportRecommendedCategoriesUseCase를 생성합니다
    func makeImportRecommendedCategoriesUseCase() -> ImportRecommendedCategoriesUseCase
    
    // MARK: - PaymentMethod UseCase Factory Methods
    
    /// GetActivePaymentMethodsUseCase를 생성합니다
    func makeGetActivePaymentMethodsUseCase() -> GetActivePaymentMethodsUseCase
    
    /// CreatePaymentMethodUseCase를 생성합니다
    func makeCreatePaymentMethodUseCase() -> CreatePaymentMethodUseCase
    
    // MARK: - ViewModel Factory Methods
    
    /// AddTransactionViewModel을 생성합니다
    func makeAddTransactionViewModel() -> AddTransactionViewModel

    /// TransactionDetailViewModel을 생성합니다
    func makeTransactionDetailViewModel(transaction: TransactionDTO) -> TransactionDetailViewModel

    /// UpdateTransactionViewModel을 생성합니다
    func makeUpdateTransactionViewModel(transaction: TransactionDTO) -> UpdateTransactionViewModel

    /// BudgetSetupViewModel을 생성합니다.
    func makeBudgetSetupViewModel() -> BudgetSetupViewModel

    // MARK: - TransactionForm ViewModel Factory Methods
    
    /// AmountPlacePaymentMethodFormViewModel을 생성합니다
    func makeAmountPlacePaymentMethodFormViewModel(amount: Decimal?, place: String, paymentMethod: PaymentMethodDTO?) -> AmountPlacePaymentMethodFormViewModel

    /// TransactionTypeCategoryFormViewModel을 생성합니다
    func makeTransactionTypeCategoryFormViewModel(transactionType: TransactionType, subCategory: SubCategoryDTO?) -> TransactionTypeCategoryFormViewModel

    /// DateAdditionalFormViewModel을 생성합니다
    func makeDateAdditionalFormViewModel(date: Date, memo: String, isFavorite: Bool) -> DateAdditionalFormViewModel

    // MARK: - Service Factory Methods
    
    /// TransactionEventPublisher를 생성합니다
    func makeTransactionEventPublisher() -> TransactionEventPublisher
    
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
            createBudgetFromTemplateUseCase: makeCreateBudgetFromTemplateUseCase(),
            transactionEventPublisher: makeTransactionEventPublisher()
        )
    }

    /// TransactionDetailViewModel을 생성합니다. (기본 구현)
    func makeTransactionDetailViewModel(transaction: TransactionDTO) -> TransactionDetailViewModel {
        return TransactionDetailViewModel(
            transaction: transaction,
            deleteTransactionUseCase: makeDeleteTransactionUseCase(),
            getTransactionByIdUseCase: makeGetTransactionByIdUseCase(),
            transactionEventPublisher: DefaultTransactionEventPublisher.shared,
            updateTransactionViewModel: makeUpdateTransactionViewModel(transaction: transaction)
        )
    }

    func makeUpdateTransactionViewModel(transaction: TransactionDTO) -> UpdateTransactionViewModel {
        let amounPlacePaymentMethodFormViewModel = makeAmountPlacePaymentMethodFormViewModel(
            amount: transaction.amount,
            place: transaction.place ?? "",
            paymentMethod: transaction.paymentMethod
        )
        let transactionTypeCategoryFormViewModel = makeTransactionTypeCategoryFormViewModel(
            transactionType: transaction.transactionType,
            subCategory: transaction.subCategory
        )
        let dateAdditionalFormViewModel = makeDateAdditionalFormViewModel(
            date: transaction.date,
            memo: transaction.memo ?? "",
            isFavorite: transaction.isFavorite
        )
        return UpdateTransactionViewModel(
            transaction: transaction,
            updateTransactionUseCase: makeUpdateTransactionUseCase(),
            transactionEventPublisher: makeTransactionEventPublisher(),
            amountPlacePaymentViewModel: amounPlacePaymentMethodFormViewModel,
            transactionTypeSelectionViewModel: transactionTypeCategoryFormViewModel,
            dateAdditionalFormViewModel: dateAdditionalFormViewModel
        )
    }

    func makeBudgetSetupViewModel() -> BudgetSetupViewModel {
        BudgetSetupViewModel(
            getBudgetTemplateUseCase: makeGetBudgetTemplateUseCase(),
            getCategoriesByTypeUseCase: makeGetCategoriesByTypeUseCase(),
            createBudgetTemplateUseCase: makeCreateBudgetTemplateUseCase(),
            updateBudgetTemplateUseCase: makeUpdateBudgetTemplateUseCase(),
            createBudgetFromTemplateUseCase: makeCreateBudgetFromTemplateUseCase(),
            updateBudgetUseCase: makeUpdateBudgetUseCase()
        )
    }

    // MARK: - TransactionForm ViewModel Default Implementation
    
    /// AmountPlacePaymentMethodFormViewModel을 생성합니다 (기본 구현)
    func makeAmountPlacePaymentMethodFormViewModel(
        amount: Decimal? = nil,
        place: String = "",
        paymentMethod: PaymentMethodDTO? = nil) -> AmountPlacePaymentMethodFormViewModel {
        return AmountPlacePaymentMethodFormViewModel(
            getActivePaymentMethodsUseCase: makeGetActivePaymentMethodsUseCase(),
            createPaymentMethodUseCase: makeCreatePaymentMethodUseCase(),
            amount: amount,
            place: place,
            selectedPaymentMethod: paymentMethod
        )
    }
    
    /// TransactionTypeCategoryFormViewModel을 생성합니다 (기본 구현)
    func makeTransactionTypeCategoryFormViewModel(
        transactionType: TransactionType = .variableExpense,
        subCategory: SubCategoryDTO? = nil
    ) -> TransactionTypeCategoryFormViewModel {
        return TransactionTypeCategoryFormViewModel(
            getCategoriesByTypeUseCase: makeGetCategoriesByTypeUseCase(),
            createCategoryUseCase: makeCreateCategoryUseCase(),
            createSubCategoryUseCase: makeCreateSubCategoryUseCase(),
            selectedTransactionType: transactionType,
            selectedSubCategory: subCategory
        )
    }
    
    /// DateAdditionalFormViewModel을 생성합니다 (기본 구현)
    func makeDateAdditionalFormViewModel(
        date: Date = Date(),
        memo: String = "",
        isFavorite: Bool = false
    ) -> DateAdditionalFormViewModel {
        return DateAdditionalFormViewModel(
            selectedDate: date,
            memo: memo,
            isFavorite: isFavorite
        )
    }
    
    // MARK: - Service Default Implementation
    
    /// TransactionEventPublisher를 생성합니다 (기본 구현)
    /// 싱글톤 인스턴스를 반환하여 앱 전체에서 동일한 이벤트 스트림 공유
    func makeTransactionEventPublisher() -> TransactionEventPublisher {
        return DefaultTransactionEventPublisher.shared
    }
    
}
