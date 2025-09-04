//
//  MockDIContainer.swift
//  MoneyMoa
//
//  Created by Claude on 8/5/25.
//

import Foundation

// MARK: - MockDIContainer

/// Mock Repository 기반 DI 컨테이너
/// Presentation Layer 개발 및 테스트 시 사용됩니다
/// 실제 UseCase 로직과 Mock Repository를 조합하여 현실적인 테스트 환경 제공
final class MockDIContainer: DIContainer {
    
    // MARK: - Mock Repository Instances
    
    private lazy var _mockTransactionRepository: MockTransactionRepository = {
        MockTransactionRepository(scenario: .empty)
    }()
    
    private lazy var _mockCategoryRepository: MockCategoryRepository = {
        MockCategoryRepository()
    }()
    
    private lazy var _mockPaymentMethodRepository: MockPaymentMethodRepository = {
        MockPaymentMethodRepository(scenario: .normal())
    }()
    
    /// 테스트에서 직접 접근할 수 있는 MockTransactionRepository
    var mockTransactionRepository: MockTransactionRepository {
        return _mockTransactionRepository
    }
    
    /// 테스트에서 직접 접근할 수 있는 MockCategoryRepository
    var mockCategoryRepository: MockCategoryRepository {
        return _mockCategoryRepository
    }
    
    /// 테스트에서 직접 접근할 수 있는 MockPaymentMethodRepository
    var mockPaymentMethodRepository: MockPaymentMethodRepository {
        return _mockPaymentMethodRepository
    }
    
    // MARK: - Repository Factory Methods
    
    private func makeTransactionRepository() -> TransactionRepository {
        return _mockTransactionRepository
    }
    
    private func makeTransactionReader() -> TransactionReader {
        return _mockTransactionRepository
    }
    
    private func makeTransactionWriter() -> TransactionWriter {
        return _mockTransactionRepository
    }
    
    private func makeCategoryRepository() -> CategoryRepository {
        return _mockCategoryRepository
    }
    
    private func makePaymentMethodRepository() -> PaymentMethodRepository {
        return _mockPaymentMethodRepository
    }
    // MARK: - UseCase Factory Methods
    
    /// GetMonthlyTransactionsUseCase를 생성합니다 (Mock Repository 기반)
    func makeGetMonthlyTransactionsUseCase() -> GetMonthlyTransactionsUseCase {
        let reader = makeTransactionReader()
        return GetMonthlyTransactionsUseCaseImpl(transactionReader: reader)
    }
    
    /// GetExpenseSumUntilDateUseCase를 생성합니다 (Mock Repository 기반)
    func makeGetExpenseSumUntilDateUseCase() -> GetExpenseSumUntilDateUseCase {
        let reader = makeTransactionReader()
        return GetExpenseSumUntilDateUseCaseImpl(transactionReader: reader)
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
    
    /// CreateTransactionUseCase를 생성합니다 (Mock Repository 기반)
    func makeCreateTransactionUseCase() -> CreateTransactionUseCase {
        let writer = makeTransactionWriter()
        return CreateTransactionUseCaseImpl(transactionWriter: writer)
    }
    
    /// GetFavoriteTransactionsUseCase를 생성합니다 (Mock Repository 기반)
    func makeGetFavoriteTransactionsUseCase() -> GetFavoriteTransactionsUseCase {
        let reader = makeTransactionReader()
        return GetFavoriteTransactionsUseCaseImpl(transactionReader: reader)
    }
    
    /// DeleteTransactionUseCase를 생성합니다 (Mock Repository 기반)
    func makeDeleteTransactionUseCase() -> DeleteTransactionUseCase {
        let repository = makeTransactionRepository()
        return DeleteTransactionUseCaseImpl(transactionRepository: repository)
    }
    
    /// UpdateTransactionUseCase를 생성합니다 (Mock Repository 기반)
    func makeUpdateTransactionUseCase() -> UpdateTransactionUseCase {
        let writer = makeTransactionWriter()
        return UpdateTransactionUseCaseImpl(transactionWriter: writer)
    }
    
    /// GetTransactionByIdUseCase를 생성합니다 (Mock Repository 기반)
    func makeGetTransactionByIdUseCase() -> GetTransactionByIdUseCase {
        let reader = makeTransactionReader()
        return GetTransactionByIdUseCaseImpl(transactionReader: reader)
    }
    
    // MARK: - Category UseCase Factory Methods
    
    /// GetCategoriesByTypeUseCase를 생성합니다 (Mock Repository 기반)
    func makeGetCategoriesByTypeUseCase() -> GetCategoriesByTypeUseCase {
        let categoryRepository = makeCategoryRepository()
        return GetCategoriesByTypeUseCaseImpl(categoryRepository: categoryRepository)
    }
    
    /// Mock Repository 기반 CreateCategoryUseCase를 생성합니다
    func makeCreateCategoryUseCase() -> CreateCategoryUseCase {
        let categoryRepository = makeCategoryRepository()
        return CreateCategoryUseCaseImpl(categoryRepository: categoryRepository)
    }
    
    /// Mock Repository 기반 UpdateCategoryUseCase를 생성합니다
    func makeUpdateCategoryUseCase() -> UpdateCategoryUseCase {
        let categoryRepository = makeCategoryRepository()
        return UpdateCategoryUseCaseImpl(categoryRepository: categoryRepository)
    }

    /// Mock Repository 기반 UpdateSubCategoryUseCase를 생성합니다
    func makeUpdateSubCategoryUseCase() -> UpdateSubCategoryUseCase {
        let categoryRepository = makeCategoryRepository()
        return UpdateSubCategoryUseCaseImpl(categoryRepository: categoryRepository)
    }

    /// Mock Repository 기반 CreateSubCategoryUseCase를 생성합니다
    func makeCreateSubCategoryUseCase() -> CreateSubCategoryUseCase {
        let categoryRepository = makeCategoryRepository()
        return CreateSubCategoryUseCaseImpl(categoryRepository: categoryRepository)
    }
    
    /// Mock ImportRecommendedCategoriesUseCase를 생성합니다
    func makeImportRecommendedCategoriesUseCase() -> ImportRecommendedCategoriesUseCase {
        let categoryRepository = makeCategoryRepository()
        return ImportRecommendedCategoriesUseCaseImpl(categoryRepository: categoryRepository)
    }
    
    // MARK: - PaymentMethod UseCase Factory Methods
    
    /// GetActivePaymentMethodsUseCase를 생성합니다 (Mock Repository 기반)
    func makeGetActivePaymentMethodsUseCase() -> GetActivePaymentMethodsUseCase {
        let repository = makePaymentMethodRepository()
        return GetActivePaymentMethodsUseCaseImpl(paymentMethodRepository: repository)
    }
    
    /// CreatePaymentMethodUseCase를 생성합니다 (Mock Repository 기반)
    func makeCreatePaymentMethodUseCase() -> CreatePaymentMethodUseCase {
        let repository = makePaymentMethodRepository()
        return CreatePaymentMethodUseCaseImpl(paymentMethodRepository: repository)
    }

    func makeGetStatisticsDashboardUseCase() -> GetStatisticsDashboardUseCase {
        let repo = makeStatisticsRepository()
        return GetStatisticsDashboardUseCaseImpl(repo: repo)
    }

    // MARK: - Statistics Repository Factory Methods

    /// StatisticsRepository 구현체를 생성합니다
    private func makeStatisticsRepository() -> StatisticsRepository {
        return MockStatisticsRepository()
    }
}
