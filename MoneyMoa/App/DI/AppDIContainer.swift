//
//  AppDIContainer.swift
//  MoneyMoa
//
//  Created by Claude on 8/5/25.
//

import Foundation
import SwiftData

// MARK: - AppDIContainer

/// Production 환경에서 사용되는 DI 컨테이너
/// 실제 Repository 구현체들을 주입하여 UseCase를 생성합니다
/// App Layer에서 모든 레이어의 구현체를 알고 있으므로 완전한 객체 그래프를 구성할 수 있습니다
final class AppDIContainer: DIContainer {
    
    // MARK: - Properties
    
    /// SwiftData Database Actor
    private let database: Database
    
    // MARK: - Initialization
    
    /// AppDIContainer를 초기화합니다
    /// - Parameter database: SwiftData Database 인스턴스
    public init(database: Database) {
        self.database = database
    }
    
    // MARK: - UseCase Factory Methods
    
    /// Production GetMonthlyTransactionsUseCase를 생성합니다
    func makeGetMonthlyTransactionsUseCase() -> GetMonthlyTransactionsUseCase {
        let reader = makeTransactionReader()
        return GetMonthlyTransactionsUseCaseImpl(transactionReader: reader)
    }
    
    /// Production GetExpenseSumUntilDateUseCase를 생성합니다
    func makeGetExpenseSumUntilDateUseCase() -> GetExpenseSumUntilDateUseCase {
        let reader = makeTransactionReader()
        return GetExpenseSumUntilDateUseCaseImpl(transactionReader: reader)
    }
    
    /// Production GetMonthlyBudgetUseCase를 생성합니다
    func makeGetMonthlyBudgetUseCase() -> GetMonthlyBudgetUseCase {
        let repository = makeBudgetRepository()
        return GetMonthlyBudgetUseCaseImpl(budgetRepository: repository)
    }
    
    /// Production GetBudgetTemplateUseCase를 생성합니다
    func makeGetBudgetTemplateUseCase() -> GetBudgetTemplateUseCase {
        let repository = makeBudgetRepository()
        return GetBudgetTemplateUseCaseImpl(repo: repository)
    }
    
    /// Production CreateBudgetFromTemplateUseCase를 생성합니다
    func makeCreateBudgetFromTemplateUseCase() -> CreateBudgetFromTemplateUseCase {
        let repository = makeBudgetRepository()
        return CreateBudgetFromTemplateUseCaseImpl(budgetRepository: repository)
    }
    
    /// Production CreateBudgetUseCase를 생성합니다
    func makeCreateBudgetUseCase() -> CreateBudgetUseCase {
        let repository = makeBudgetRepository()
        return CreateBudgetUseCaseImpl(budgetRepository: repository)
    }
    
    /// Production CreateBudgetTemplateUseCase를 생성합니다
    func makeCreateBudgetTemplateUseCase() -> CreateTemplateFromBudgetUseCase {
        let repository = makeBudgetRepository()
        return CreateTemplateFromBudgetUseCaseImpl(repo: repository)
    }
    
    /// Production UpdateBudgetTemplateUseCase를 생성합니다
    func makeUpdateBudgetTemplateUseCase() -> UpdateTemplateFromBudgetUseCase {
        let repository = makeBudgetRepository()
        return UpdateTemplateFromBudgetUseCaseImpl(repo: repository)
    }
    
    /// Production UpdateBudgetRangeUseCase를 생성합니다
    func makeUpdateBudgetRangeUseCase() -> UpdateBudgetRangeUseCase {
        let repository = makeBudgetRepository()
        return UpdateBudgetRangeUseCaseImpl(budgetRepository: repository)
    }
    
    // MARK: - Transaction UseCase Factory Methods
    
    /// Production CreateTransactionUseCase를 생성합니다
    func makeCreateTransactionUseCase() -> CreateTransactionUseCase {
        let writer = makeTransactionWriter()
        return CreateTransactionUseCaseImpl(transactionWriter: writer)
    }
    
    /// Production GetFavoriteTransactionsUseCase를 생성합니다
    func makeGetFavoriteTransactionsUseCase() -> GetFavoriteTransactionsUseCase {
        let reader = makeTransactionReader()
        return GetFavoriteTransactionsUseCaseImpl(transactionReader: reader)
    }
    
    /// Production DeleteTransactionUseCase를 생성합니다
    func makeDeleteTransactionUseCase() -> DeleteTransactionUseCase {
        let repository = makeTransactionRepository()
        return DeleteTransactionUseCaseImpl(transactionRepository: repository)
    }
    
    /// Production UpdateTransactionUseCase를 생성합니다
    func makeUpdateTransactionUseCase() -> UpdateTransactionUseCase {
        let writer = makeTransactionWriter()
        return UpdateTransactionUseCaseImpl(transactionWriter: writer)
    }
    
    /// Production GetTransactionByIdUseCase를 생성합니다
    func makeGetTransactionByIdUseCase() -> GetTransactionByIdUseCase {
        let reader = makeTransactionReader()
        return GetTransactionByIdUseCaseImpl(transactionReader: reader)
    }
    
    // MARK: - Category UseCase Factory Methods
    
    /// Production GetCategoriesByTypeUseCase를 생성합니다
    func makeGetCategoriesByTypeUseCase() -> GetCategoriesByTypeUseCase {
        let categoryRepository = makeCategoryRepository()
        return GetCategoriesByTypeUseCaseImpl(categoryRepository: categoryRepository)
    }
    
    /// Production CreateCategoryUseCase를 생성합니다
    func makeCreateCategoryUseCase() -> CreateCategoryUseCase {
        let categoryRepository = makeCategoryRepository()
        return CreateCategoryUseCaseImpl(categoryRepository: categoryRepository)
    }
    
    /// Production UpdateCategoryUseCase를 생성합니다
    func makeUpdateCategoryUseCase() -> UpdateCategoryUseCase {
        let repository = makeCategoryRepository()
        return UpdateCategoryUseCaseImpl(categoryRepository: repository)
    }
    
    /// Production CreateSubCategoryUseCase를 생성합니다
    func makeCreateSubCategoryUseCase() -> CreateSubCategoryUseCase {
        let repository = makeCategoryRepository()
        return CreateSubCategoryUseCaseImpl(categoryRepository: repository)
    }

    /// Production UpdateSubCategoryUseCase를 생성합니다
    func makeUpdateSubCategoryUseCase() -> UpdateSubCategoryUseCase {
        let repository = makeCategoryRepository()
        return UpdateSubCategoryUseCaseImpl(categoryRepository: repository)
    }

    /// Production ImportRecommendedCategoriesUseCase를 생성합니다
    func makeImportRecommendedCategoriesUseCase() -> ImportRecommendedCategoriesUseCase {
        let categoryRepository = makeCategoryRepository()
        return ImportRecommendedCategoriesUseCaseImpl(categoryRepository: categoryRepository)
    }
    
    // MARK: - PaymentMethod UseCase Factory Methods
    
    /// Production GetActivePaymentMethodsUseCase를 생성합니다
    func makeGetActivePaymentMethodsUseCase() -> GetActivePaymentMethodsUseCase {
        let repository = makePaymentMethodRepository()
        return GetActivePaymentMethodsUseCaseImpl(paymentMethodRepository: repository)
    }
    
    /// Production CreatePaymentMethodUseCase를 생성합니다
    func makeCreatePaymentMethodUseCase() -> CreatePaymentMethodUseCase {
        let repository = makePaymentMethodRepository()
        return CreatePaymentMethodUseCaseImpl(paymentMethodRepository: repository)
    }
    
    // MARK: - Repository Factory Methods
    
    /// TransactionRepository 구현체를 생성합니다 (통합 인터페이스)
    private func makeTransactionRepository() -> TransactionRepository {
        return TransactionRepositoryImpl(database: database)
    }
    
    /// TransactionReader 구현체를 생성합니다 (읽기 전용)
    private func makeTransactionReader() -> TransactionReader {
        return TransactionRepositoryImpl(database: database)
    }
    
    /// TransactionWriter 구현체를 생성합니다 (쓰기 전용)
    private func makeTransactionWriter() -> TransactionWriter {
        return TransactionRepositoryImpl(database: database)
    }
    
    /// BudgetRepository 구현체를 생성합니다
    private func makeBudgetRepository() -> CompleteBudgetRepository {
        return BudgetRepositoryImpl(database: database)
    }
    
    /// CategoryRepository 구현체를 생성합니다 (통합 인터페이스)
    private func makeCategoryRepository() -> CategoryRepository {
        return CategoryRepositoryImpl(database: database)
    }
    
    /// CategoryReader 구현체를 생성합니다 (읽기 전용)
    private func makeCategoryReader() -> CategoryReader {
        return CategoryRepositoryImpl(database: database)
    }
    
    /// CategoryWriter 구현체를 생성합니다 (쓰기 전용)
    private func makeCategoryWriter() -> CategoryWriter {
        return CategoryRepositoryImpl(database: database)
    }
    
    /// PaymentMethodRepository 구현체를 생성합니다
    private func makePaymentMethodRepository() -> PaymentMethodRepository {
        return PaymentMethodRepositoryImpl(database: database)
    }
    
    // MARK: - Statistics UseCase Factory Methods
    
    /// Production GetStatisticsDashboardUseCase를 생성합니다
    func makeGetStatisticsDashboardUseCase() -> GetStatisticsDashboardUseCase {
        let repository = makeStatisticsRepository()
        return GetStatisticsDashboardUseCaseImpl(repo: repository)
    }
    
    // MARK: - Statistics Repository Factory Methods
    
    /// StatisticsRepository 구현체를 생성합니다
    private func makeStatisticsRepository() -> StatisticsRepository {
        return StatisticsRepositoryImpl(
            tx: TransactionRepositoryAdapter(
                repo: makeTransactionRepository()
            ),
            budget: BudgetRepositoryAdapter(
                budgetRepo: makeBudgetRepository(),
                txRepo: makeTransactionRepository()
            )
        )
    }
}
