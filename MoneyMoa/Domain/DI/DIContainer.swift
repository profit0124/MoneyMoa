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
    
    /// CreateBudgetUseCase를 생성합니다
    func makeCreateBudgetUseCase() -> CreateBudgetUseCase
    
    /// CreateBudgetTemplateUseCase를 생성합니다
    func makeCreateBudgetTemplateUseCase() -> CreateTemplateFromBudgetUseCase
    
    /// UpdateBudgetTemplateUseCase를 생성합니다
    func makeUpdateBudgetTemplateUseCase() -> UpdateTemplateFromBudgetUseCase
    
    /// UpdateBudgetRangeUseCase를 생성합니다
    func makeUpdateBudgetRangeUseCase() -> UpdateBudgetRangeUseCase
    
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

    // MARK: - TransactionTemplate UseCase Factory Methods

    /// TransactionTemplateProcessingUseCase를 생성합니다
    func makeTransactionTemplateProcessingUseCase() -> TransactionTemplateProcessingUseCase
    
    // MARK: - Category UseCase Factory Methods
    
    /// GetCategoriesByTypeUseCase를 생성합니다
    func makeGetCategoriesByTypeUseCase() -> GetCategoriesByTypeUseCase
    
    /// CreateCategoryUseCase를 생성합니다
    func makeCreateCategoryUseCase() -> CreateCategoryUseCase
    
    /// UpdateCategoryUseCase를 생성합니다
    func makeUpdateCategoryUseCase() -> UpdateCategoryUseCase
    
    /// CreateSubCategoryUseCase를 생성합니다
    func makeCreateSubCategoryUseCase() -> CreateSubCategoryUseCase

    /// UpdateSubCategoryUseCase를 생성합니다
    func makeUpdateSubCategoryUseCase() -> UpdateSubCategoryUseCase

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
    func makeBudgetSetupViewModel(yearMonth: YearMonth) -> BudgetSetupViewModel

    /// makeCategoryListViewModel을 생성합니다.
    func makeCategoryListViewModel(mode: CategoryListMode) -> CategoryListViewModel

    /// CategorySelectorViewModel을 생성합니다.
    func makeCategorySelectorViewModel(selectedCategory: CategoryDTO) -> CategorySelectorViewModel

    func makeCategoryFormViewModel(from mode: CategoryListMode, category: CategoryDTO?, transactionType: TransactionType?) -> CategoryFormViewModel

    /// SubCategoryFormViewModel을 생성합니다.
    func makeSubCategoryFormViewModel(category: CategoryDTO, subCategory: SubCategoryDTO?) -> SubCategoryFormViewModel

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
    
    /// CategoryEventPublisher를 생성합니다
    func makeCategoryEventPublisher() -> CategoryEventPublisher
    
    // MARK: - Statistics Factory Methods
    
    /// GetStatisticsDashboardUseCase를 생성합니다
    func makeGetStatisticsDashboardUseCase() -> GetStatisticsDashboardUseCase
    
    /// StatisticsViewModel을 생성합니다
    func makeStatisticsViewModel() -> StatisticsViewModel
    
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
            transactionEventPublisher: makeTransactionEventPublisher()
        )
    }

    func makeAddTransactionViewModel() -> AddTransactionViewModel {
        return AddTransactionViewModel(
            createTransactionUseCase: makeCreateTransactionUseCase(),
            getFavoriteTransactionsUseCase: makeGetFavoriteTransactionsUseCase(),
            transactionEventPublisher: makeTransactionEventPublisher(),
            amountPlacePaymentViewModel: makeAmountPlacePaymentMethodFormViewModel(),
            transactionTypeSelectionViewModel: makeTransactionTypeCategoryFormViewModel(),
            dateAdditionalFormViewModel: makeDateAdditionalFormViewModel()
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

    func makeBudgetSetupViewModel(yearMonth: YearMonth) -> BudgetSetupViewModel {
        BudgetSetupViewModel(
            yearMonth: yearMonth,
            getMonthlyBudgetUseCase: makeGetMonthlyBudgetUseCase(),
            getCategoriesByTypeUseCase: makeGetCategoriesByTypeUseCase(),
            createTemplateFromBudgetUseCase: makeCreateBudgetTemplateUseCase(),
            updateBudgetTemplateUseCase: makeUpdateBudgetTemplateUseCase(),
            createBudgetUseCase: makeCreateBudgetUseCase(),
            updateBudgetRangeUseCase: makeUpdateBudgetRangeUseCase()
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
        // Selection 모드의 CategoryListViewModel 생성
        let categoryListViewModel = makeCategoryListViewModel(mode: .selection)
        
        // 초기값 설정
        categoryListViewModel.send(.selectTransactionType(transactionType))
        if let subCategory = subCategory {
            categoryListViewModel.selectedSubCategory = subCategory
        }
        
        return TransactionTypeCategoryFormViewModel(categoryListViewModel: categoryListViewModel)
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

    // MARK: CategorySetting

    func makeCategoryListViewModel(mode: CategoryListMode) -> CategoryListViewModel {
        return CategoryListViewModel(
            getCategoriesUseCase: makeGetCategoriesByTypeUseCase(),
            categoryEventPublisher: makeCategoryEventPublisher(),
            mode: mode
        )
    }

    func makeCategorySelectorViewModel(selectedCategory: CategoryDTO) -> CategorySelectorViewModel {
        return CategorySelectorViewModel(
            getCategoriesByTypeUseCase: makeGetCategoriesByTypeUseCase(),
            selectedCategory: selectedCategory,
            selectCategoryPublisher: DefaultSelectCategoryEventPublisher.shared
        )
    }

    func makeCategoryFormViewModel(from mode: CategoryListMode, category: CategoryDTO?, transactionType: TransactionType?) -> CategoryFormViewModel {
        return CategoryFormViewModel(
            createCategoryUseCase: makeCreateCategoryUseCase(),
            createSubCategoryUseCase: makeCreateSubCategoryUseCase(),
            updateCategoryUseCase: makeUpdateCategoryUseCase(),
            categoryEventPublisher: makeCategoryEventPublisher(),
            mode: mode,
            selectedTransactionType: transactionType ?? .income,
            selectedCategory: category
        )
    }

    func makeSubCategoryFormViewModel(category: CategoryDTO, subCategory: SubCategoryDTO?) -> SubCategoryFormViewModel {
        return SubCategoryFormViewModel(
            createSubCategoryUseCase: makeCreateSubCategoryUseCase(),
            updateSubCategoryUseCase: makeUpdateSubCategoryUseCase(),
            subCategoryEventPublisher: DefaultSubCategoryEventPublisher.shared,
            selectedCategory: category,
            selectedSubCategory: subCategory
        )
    }

    // MARK: - Service Default Implementation
    
    /// TransactionEventPublisher를 생성합니다 (기본 구현)
    /// 싱글톤 인스턴스를 반환하여 앱 전체에서 동일한 이벤트 스트림 공유
    func makeTransactionEventPublisher() -> TransactionEventPublisher {
        return DefaultTransactionEventPublisher.shared
    }
    
    /// CategoryEventPublisher를 생성합니다 (기본 구현)
    /// 싱글톤 인스턴스를 반환하여 앱 전체에서 동일한 이벤트 스트림 공유
    func makeCategoryEventPublisher() -> CategoryEventPublisher {
        return DefaultCategoryEventPublisher.shared
    }
    
    // MARK: - Statistics Default Implementation

    /// StatisticsViewModel을 생성합니다 (기본 구현)
    func makeStatisticsViewModel() -> StatisticsViewModel {
        return StatisticsViewModel(
            getStatisticsDashboardUseCase: makeGetStatisticsDashboardUseCase()
        )
    }
}
