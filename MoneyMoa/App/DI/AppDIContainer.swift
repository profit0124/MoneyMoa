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
        let repository = makeTransactionRepository()
        return GetMonthlyTransactionsUseCaseImpl(transactionRepository: repository)
    }
    
    /// Production GetExpenseSumUntilDateUseCase를 생성합니다
    func makeGetExpenseSumUntilDateUseCase() -> GetExpenseSumUntilDateUseCase {
        let repository = makeTransactionRepository()
        return GetExpenseSumUntilDateUseCaseImpl(transactionRepository: repository)
    }
    
    /// Production GetMonthlyBudgetUseCase를 생성합니다
    func makeGetMonthlyBudgetUseCase() -> GetMonthlyBudgetUseCase {
        let repository = makeBudgetRepository()
        return GetMonthlyBudgetUseCaseImpl(budgetRepository: repository)
    }
    
    /// Production GetBudgetTemplateUseCase를 생성합니다
    func makeGetBudgetTemplateUseCase() -> GetBudgetTemplateUseCase {
        let repository = makeBudgetRepository()
        return GetBudgetTemplateUseCaseImpl(budgetRepository: repository)
    }
    
    /// Production CreateBudgetFromTemplateUseCase를 생성합니다
    func makeCreateBudgetFromTemplateUseCase() -> CreateBudgetFromTemplateUseCase {
        let repository = makeBudgetRepository()
        return CreateBudgetFromTemplateUseCaseImpl(budgetRepository: repository)
    }
    
    // MARK: - Repository Factory Methods
    
    /// TransactionRepository 구현체를 생성합니다
    private func makeTransactionRepository() -> TransactionRepository {
        return TransactionRepositoryImpl(database: database)
    }
    
    /// BudgetRepository 구현체를 생성합니다
    private func makeBudgetRepository() -> BudgetRepository {
        return BudgetRepositoryImpl(database: database)
    }
}
