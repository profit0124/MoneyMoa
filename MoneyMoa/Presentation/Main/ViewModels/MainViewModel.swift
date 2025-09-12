//
//  MainViewModel.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/30/25.
//

import Foundation
import SwiftUI
import Observation
import Combine

// MARK: - MainViewModel

@Observable
public class MainViewModel {
    
    // MARK: - Properties
    
    // MARK: - 거래내역
    
    /// MainView 완료 시점에 transactions 의 필요 여부에 따라 삭제 가능
    private(set) var transactions: [TransactionDTO] = []
    public private(set) var transactionsByDate: [Date: [TransactionDTO]] = [:]
    public var listData: [(Date, [TransactionDTO])] {
        transactionsByDate.sorted(by: { $0.key > $1.key})
    }
    
    /// 현재 선택된 연월
    public private(set) var currentYearMonth: YearMonth
    
    /// 로딩 상태
    public private(set) var isLoading: Bool = false
    
    // MARK: - Summary
    
    /// Summary Section 데이터
    public private(set) var summaryData: SummaryDisplayData?
    
    /// Summary 로딩 상태
    public private(set) var isSummaryLoading: Bool = true
    
    /// 현재 월 지출 (계산된 값 저장)
    private var currentMonthExpenseAmount: Decimal = 0
    
    /// 전월 지출 (로드된 값 저장)
    private var previousMonthExpenseAmount: Decimal = 0
    
    /// 현재 월 예산 (로드된 값 저장)
    private var currentMonthBudget: BudgetDTO?
    
    // MARK: - Dependencies
    
    private let getMonthlyTransactionsUseCase: GetMonthlyTransactionsUseCase
    private let getExpenseSumUntilDateUseCase: GetExpenseSumUntilDateUseCase
    private let getMonthlyBudgetUseCase: GetMonthlyBudgetUseCase
    private let transactionEventPublisher: TransactionEventPublisher
    
    // MARK: - Publisher Subscriptions
    
    /// Publisher 구독 관리
    private var cancellables: Set<AnyCancellable> = []
    
    // MARK: - Initialization
    
    public init(
        getMonthlyTransactionsUseCase: GetMonthlyTransactionsUseCase,
        getExpenseSumUntilDateUseCase: GetExpenseSumUntilDateUseCase,
        getMonthlyBudgetUseCase: GetMonthlyBudgetUseCase,
        transactionEventPublisher: TransactionEventPublisher,
        initialYearMonth: YearMonth = YearMonth.current
    ) {
        self.getMonthlyTransactionsUseCase = getMonthlyTransactionsUseCase
        self.getExpenseSumUntilDateUseCase = getExpenseSumUntilDateUseCase
        self.getMonthlyBudgetUseCase = getMonthlyBudgetUseCase
        self.transactionEventPublisher = transactionEventPublisher
        self.currentYearMonth = initialYearMonth
        
        setupTransactionEventObservers()
    }
    
    // MARK: - MainView Actions
    enum Action {
        case loadTransactions
        case makeDictionary
        case calculateCurrentMonthExpense
        case loadPreviousMonthExpense
        case loadCurrentMonthBudget
        case setBudget(BudgetDTO?)
        case updateSummaryData
        case handleYearMonth(HandleYearMonth)
    }
    
    enum HandleYearMonth {
        case moveToNextMonth
        case moveToPreviousMonth
        case setMonth(YearMonth)
    }
    
    // MARK: - Public Methods
    
    func send(_ action: Action) {
        switch action {
        case .loadTransactions:
            Task {
                await loadTransactions()
                send(.makeDictionary)
                send(.calculateCurrentMonthExpense)
            }
        case .makeDictionary:
            makeDictionary(from: transactions)
        case .calculateCurrentMonthExpense:
            calculateCurrentMonthExpense()
            send(.loadPreviousMonthExpense)
        case .loadPreviousMonthExpense:
            Task {
                await loadPreviousMonthExpense()
                send(.loadCurrentMonthBudget)
            }
        case .loadCurrentMonthBudget:
            Task {
                let action = await loadCurrentMonthBudget()
                send(action)
            }
        case .setBudget(let budget):
            setBudget(budget)
            send(.updateSummaryData)
        case .updateSummaryData:
            updateSummaryData()
        case .handleYearMonth(let handleYearMonth):
            handleYearMonthAction(handleYearMonth)
            send(.loadTransactions)
        }
    }
    /// 특정 연월의 거래 내역을 로드합니다
    /// - Parameter yearMonth: 로드할 연월
    private func loadTransactions() async {
        isLoading = true
        defer {
            isLoading = false
        }
        do {
            self.transactions = try await getMonthlyTransactionsUseCase.execute(yearMonth: currentYearMonth)
        } catch {
            print("Failed to load transactions: \(error.localizedDescription)")
        }
    }
    
    /// 다음 월로 이동합니다
    private func moveToNextMonth() {
        currentYearMonth = currentYearMonth.nextMonth()
    }
    
    /// 이전 월로 이동합니다
    private func moveToPreviousMonth() {
        currentYearMonth = currentYearMonth.previousMonth()
    }
    
    /// 특정 월로 이동합니다
    /// - Parameter yearMonth: 이동할 연월
    private func setMonth(_ yearMonth: YearMonth) {
        currentYearMonth = yearMonth
    }
    
    /// Calendar 와 거래내역에 사용할 수 있게 날짜별 Grouping 진행
    /// - Note: loadSummaryChain()이 이후에 자동 실행됩니다
    private func makeDictionary(from transactions: [TransactionDTO]) {
        self.transactionsByDate = Dictionary(grouping: transactions, by: {
            Calendar.current.startOfDay(for: $0.date)
        })
    }
    
    // MARK: - Summary State Management
    
    /// 동기 작업에 대한 로딩 상태 처리
    private func handleLoading(_ process: () -> Void) {
        startSummaryLoading()
        defer {
            stopSummaryLoading()
        }
        
        process()
    }
    
    /// 비동기 작업에 대한 로딩 상태 처리
    private func handleAsyncLoading(_ process: () async -> Void) async {
        startSummaryLoading()
        defer {
            stopSummaryLoading()
        }
        
        await process()
    }
    
    /// Summary 로딩 상태를 시작합니다 (중복 호출 안전)
    private func startSummaryLoading() {
        if !isSummaryLoading {
            isSummaryLoading = true
        }
    }
    
    /// Summary 로딩 상태를 종료합니다
    private func stopSummaryLoading() {
        if isSummaryLoading {
            isSummaryLoading = false
        }
    }
    
    /// 현재 월 지출을 기존 transactions에서 계산합니다
    private func calculateCurrentMonthExpense() {
        handleLoading({
            let currentDate = Date()
            let calendar = Calendar.current
            let currentDay = calendar.component(.day, from: currentDate)
            
            currentMonthExpenseAmount = transactions
                .filter { transaction in
                    // 지출만 포함 (수입 제외)
                    guard transaction.transactionType != .income else { return false }
                    
                    // 현재 날짜까지만 포함
                    let transactionDay = calendar.component(.day, from: transaction.date)
                    return transactionDay <= currentDay
                }
                .reduce(0) { $0 + $1.amount }
        })
    }
    
    /// 전월 지출을 로드합니다 (현재 날짜까지)
    private func loadPreviousMonthExpense() async {
        await handleAsyncLoading {
            do {
                let currentDate = Date()
                let previousMonth = currentYearMonth.previousMonth()
                
                previousMonthExpenseAmount = try await getExpenseSumUntilDateUseCase.execute(
                    yearMonth: previousMonth,
                    untilDay: currentDate
                )
            } catch {
                print("Previous month expense load error: \(error.localizedDescription)")
                previousMonthExpenseAmount = 0
            }
        }
    }
    
    /// 현재 월 예산을 로드합니다
    private func loadCurrentMonthBudget() async -> Action {
        startSummaryLoading()
        defer {
            stopSummaryLoading()
        }
        
        do {
            let budgetDTO = try await getMonthlyBudgetUseCase.execute(yearMonth: currentYearMonth)
            return .setBudget(budgetDTO)
        } catch {
            print("Current month budget load error: \(error.localizedDescription)")
            return .setBudget(nil)
        }
    }
    
    /// 예산을 설정합니다 (reload 대신 직접 설정)
    private func setBudget(_ budget: BudgetDTO?) {
        currentMonthBudget = budget
    }
    
    /// Summary 데이터를 업데이트합니다 (모든 계산된 데이터 조립)
    private func updateSummaryData() {
        handleLoading {
            summaryData = createSummaryDisplayData(
                currentMonthExpense: currentMonthExpenseAmount,
                previousMonthExpense: previousMonthExpenseAmount,
                budget: currentMonthBudget
            )
        }
    }
    
    /// SummaryDisplayData를 생성합니다
    private func createSummaryDisplayData(
        currentMonthExpense: Decimal,
        previousMonthExpense: Decimal,
        budget: BudgetDTO?
    ) -> SummaryDisplayData {
        
        // 전월 데이터 존재 여부 확인
        let hasPreviousData = previousMonthExpense > 0
        
        // 전월 대비 증감 계산 (전월 데이터가 있을 때만)
        let monthlyComparison: Decimal?
        let comparisonPercentage: Double?
        
        if hasPreviousData {
            monthlyComparison = currentMonthExpense - previousMonthExpense
            comparisonPercentage = calculateComparisonPercentage(
                current: currentMonthExpense,
                previous: previousMonthExpense
            )
        } else {
            monthlyComparison = nil
            comparisonPercentage = nil
        }
        
        if let budget = budget {
            // 예산이 설정된 경우
            let remainingBudget = budget.totalAmount - currentMonthExpense
            let budgetUsagePercentage = calculateBudgetUsagePercentage(
                expense: currentMonthExpense,
                budget: budget.totalAmount
            )
            
            return SummaryDisplayData(
                currentMonthExpense: currentMonthExpense,
                previousMonthExpense: previousMonthExpense,
                monthlyComparison: monthlyComparison,
                comparisonPercentage: comparisonPercentage,
                hasPreviousMonthData: hasPreviousData,
                budget: budget,
                remainingBudget: remainingBudget,
                budgetUsagePercentage: budgetUsagePercentage
            )
        } else {
            // 예산이 설정되지 않은 경우
            return SummaryDisplayData(
                currentMonthExpense: currentMonthExpense,
                previousMonthExpense: previousMonthExpense,
                monthlyComparison: monthlyComparison,
                comparisonPercentage: comparisonPercentage,
                hasPreviousMonthData: hasPreviousData,
                budget: nil,
                remainingBudget: nil,
                budgetUsagePercentage: nil
            )
        }
    }
    
    // MARK: - Helper Methods
    
    /// 전월 대비 증감률을 계산합니다
    private func calculateComparisonPercentage(current: Decimal, previous: Decimal) -> Double {
        guard previous > 0 else {
            return current > 0 ? 1.0 : 0.0
        }
        
        let difference = current - previous
        let percentage = Double(truncating: difference as NSDecimalNumber) / 
                        Double(truncating: previous as NSDecimalNumber)
        
        return percentage
    }
    
    /// 예산 사용률을 계산합니다
    private func calculateBudgetUsagePercentage(expense: Decimal, budget: Decimal) -> Double {
        guard budget > 0 else { return 0.0 }
        
        let usage = Double(truncating: expense as NSDecimalNumber) / 
                   Double(truncating: budget as NSDecimalNumber)
        
        return max(0.0, usage)
    }
    
    // MARK: - Computed Properties for Summary
    
    /// 현재 월 지출 총액 (전체 월, 기존 transactions 활용)
    public var currentMonthTotalExpense: Decimal {
        transactions
            .filter { $0.transactionType != .income }
            .reduce(0) { $0 + $1.amount }
    }
    
    /// 현재 월 수입 총액
    public var currentMonthTotalIncome: Decimal {
        transactions
            .filter { $0.transactionType == .income }
            .reduce(0) { $0 + $1.amount }
    }
    
    /// Summary 데이터 로드 상태 확인
    public var hasSummaryData: Bool {
        summaryData != nil
    }
    
    // MARK: handleYearMonth
    private func handleYearMonthAction(_ handleYearMonth: HandleYearMonth) {
        switch handleYearMonth {
        case .moveToNextMonth:
            moveToNextMonth()
        case .moveToPreviousMonth:
            moveToPreviousMonth()
        case .setMonth(let yearMonth):
            setMonth(yearMonth)
        }
    }
    
    // MARK: - TransactionEvent Handling
    
    /// TransactionEvent 옵저버를 설정합니다
    private func setupTransactionEventObservers() {
        transactionEventPublisher.transactionEvents
            .filter { [weak self] event in
                // 현재 보고 있는 연월과 일치하는 이벤트만 처리
                event.yearMonth == self?.currentYearMonth
            }
            .sink { [weak self] event in
                self?.handleTransactionEvent(event)
            }
            .store(in: &cancellables)
    }
    
    /// 트랜잭션 이벤트 처리
    /// - Parameter event: 처리할 트랜잭션 이벤트
    private func handleTransactionEvent(_ event: TransactionEvent) {
        switch event.type {
        case .created, .updated, .deleted:
            // 모든 변경사항에 대해 목록 새로고침
            send(.loadTransactions)
        }
    }
    
    /// Publisher 구독 해제 (deinit에서 호출)
    deinit {
        cancellables.removeAll()
    }
}
