//
//  MainViewModel.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/30/25.
//

import Foundation
import SwiftUI
import Observation

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
    
    // MARK: - Dependencies
    
    private let getMonthlyTransactionsUseCase: GetMonthlyTransactionsUseCase
    
    // MARK: - Initialization
    
    public init(
        getMonthlyTransactionsUseCase: GetMonthlyTransactionsUseCase,
        initialYearMonth: YearMonth = YearMonth.current
    ) {
        self.getMonthlyTransactionsUseCase = getMonthlyTransactionsUseCase
        self.currentYearMonth = initialYearMonth
    }
    
    // MARK: - MainView Actions
    enum Action {
        case loadTransactions
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
                makeDictionary(from: transactions)
            }
        case .handleYearMonth(let handleYearMonth):
            switch handleYearMonth {
            case .moveToNextMonth:
                moveToNextMonth()
            case .moveToPreviousMonth:
                moveToPreviousMonth()
            case .setMonth(let yearMonth):
                setMonth(yearMonth)
            }
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
            // TODO: 에러 핸들링 추가 필요
            print("error : \(error.localizedDescription)")
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
    private func makeDictionary(from transactions: [TransactionDTO]) {
        self.transactionsByDate = Dictionary(grouping: transactions, by: {
            Calendar.current.startOfDay(for: $0.date)
        })
    }
}

