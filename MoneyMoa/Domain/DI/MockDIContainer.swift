//
//  MockDIContainer.swift
//  MoneyMoa
//
//  Created by Claude on 8/5/25.
//

import Foundation

// MARK: - MockDIContainer

/// Mock 구현체들을 제공하는 DI 컨테이너
/// Presentation Layer 개발 및 테스트 시 사용됩니다
final class MockDIContainer: DIContainer {

    // MARK: - UseCase Factory Methods
    
    /// Mock GetMonthlyTransactionsUseCase를 생성합니다
    func makeGetMonthlyTransactionsUseCase() -> GetMonthlyTransactionsUseCase {
        return MockGetMonthlyTransactionsUseCase()
    }
    
    /// Mock GetExpenseSumUntilDateUseCase를 생성합니다
    func makeGetExpenseSumUntilDateUseCase() -> GetExpenseSumUntilDateUseCase {
        return MockGetExpenseSumUntilDateUseCase()
    }
    
    /// Mock GetMonthlyBudgetUseCase를 생성합니다
    func makeGetMonthlyBudgetUseCase() -> GetMonthlyBudgetUseCase {
        return MockGetMonthlyBudgetUseCase()
    }
    
    /// Mock GetBudgetTemplateUseCase를 생성합니다
    func makeGetBudgetTemplateUseCase() -> GetBudgetTemplateUseCase {
        return MockGetBudgetTemplateUseCase()
    }
    
    /// Mock CreateBudgetFromTemplateUseCase를 생성합니다
    func makeCreateBudgetFromTemplateUseCase() -> CreateBudgetFromTemplateUseCase {
        return MockCreateBudgetFromTemplateUseCase()
    }
    
    /// Mock CreateBudgetUseCase를 생성합니다
    func makeCreateBudgetUseCase() -> CreateBudgetUseCase {
        return MockCreateBudgetUseCase()
    }
    
    /// Mock CreateBudgetTemplateUseCase를 생성합니다
    func makeCreateBudgetTemplateUseCase() -> CreateTemplateFromBudgetUseCase {
        return MockCreateTemplateFromBudgetUseCase()
    }
    
    /// Mock UpdateBudgetTemplateUseCase를 생성합니다
    func makeUpdateBudgetTemplateUseCase() -> UpdateTemplateFromBudgetUseCase {
        return MockUpdateTemplateFromBudgetUseCase()
    }
    
    /// Mock UpdateBudgetRangeUseCase를 생성합니다
    func makeUpdateBudgetRangeUseCase() -> UpdateBudgetRangeUseCase {
        return MockUpdateBudgetRangeUseCase()
    }
    
    // MARK: - Transaction UseCase Factory Methods
    
    /// Mock CreateTransactionUseCase를 생성합니다
    func makeCreateTransactionUseCase() -> CreateTransactionUseCase {
        return MockCreateTransactionUseCase()
    }
    
    /// Mock GetFavoriteTransactionsUseCase를 생성합니다
    func makeGetFavoriteTransactionsUseCase() -> GetFavoriteTransactionsUseCase {
        return MockGetFavoriteTransactionsUseCase()
    }
    
    /// Mock DeleteTransactionUseCase를 생성합니다
    func makeDeleteTransactionUseCase() -> DeleteTransactionUseCase {
        return MockDeleteTransactionUseCase()
    }
    
    /// Mock UpdateTransactionUseCase를 생성합니다
    func makeUpdateTransactionUseCase() -> UpdateTransactionUseCase {
        return MockUpdateTransactionUseCase()
    }
    
    /// Mock GetTransactionByIdUseCase를 생성합니다
    func makeGetTransactionByIdUseCase() -> GetTransactionByIdUseCase {
        return MockGetTransactionByIdUseCase()
    }
    
    // MARK: - Category UseCase Factory Methods
    
    /// Mock GetCategoriesByTypeUseCase를 생성합니다
    func makeGetCategoriesByTypeUseCase() -> GetCategoriesByTypeUseCase {
        return MockGetCategoriesByTypeUseCase()
    }
    
    /// Mock CreateCategoryUseCase를 생성합니다
    func makeCreateCategoryUseCase() -> CreateCategoryUseCase {
        return MockCreateCategoryUseCase()
    }
    
    /// Mock UpdateCategoryUseCase를 생성합니다
    func makeUpdateCategoryUseCase() -> UpdateCategoryUseCase {
        return MockUpdateCategoryUseCase()
    }

    func makeUpdateSubCategoryUseCase() -> UpdateSubCategoryUseCase {
        return MockUpdateSubCategoryUseCase()
    }

    /// Mock CreateSubCategoryUseCase를 생성합니다
    func makeCreateSubCategoryUseCase() -> CreateSubCategoryUseCase {
        return MockCreateSubCategoryUseCase()
    }
    
    /// Mock ImportRecommendedCategoriesUseCase를 생성합니다
    func makeImportRecommendedCategoriesUseCase() -> ImportRecommendedCategoriesUseCase {
        return MockImportRecommendedCategoriesUseCase()
    }
    
    // MARK: - PaymentMethod UseCase Factory Methods
    
    /// Mock GetActivePaymentMethodsUseCase를 생성합니다
    func makeGetActivePaymentMethodsUseCase() -> GetActivePaymentMethodsUseCase {
        return MockGetActivePaymentMethodsUseCase()
    }
    
    /// Mock CreatePaymentMethodUseCase를 생성합니다
    func makeCreatePaymentMethodUseCase() -> CreatePaymentMethodUseCase {
        return MockCreatePaymentMethodUseCase()
    }
    
    // MARK: - ViewModel Factory Methods
    
    /// Mock AddTransactionViewModel을 생성합니다
    func makeAddTransactionViewModel() -> AddTransactionViewModel {
        return AddTransactionViewModel(container: self)
    }
}
