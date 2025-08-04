//
//  GetExpenseSumUntilDateUseCaseImpl.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/4/25.
//

import Foundation

// MARK: - GetExpenseSumUntilDateUseCaseImpl

public class GetExpenseSumUntilDateUseCaseImpl: GetExpenseSumUntilDateUseCase {
    
    // MARK: - Properties
    
    private let transactionRepository: TransactionRepository
    
    // MARK: - Initialization
    
    public init(transactionRepository: TransactionRepository) {
        self.transactionRepository = transactionRepository
    }
    
    // MARK: - UseCase Methods
    
    public func execute(yearMonth: YearMonth, untilDay: Date = Date()) async throws -> Decimal {
        let startOfMonth = yearMonth.startOfMonth
        let calendar = FormatterManager.shared.koreaCalendar
        
        // 종료 날짜 결정: 과거 월인지 현재 월인지에 따라 분기
        let endOfDay: Date
        
        if yearMonth < YearMonth(from: untilDay) {
            // yearMonth가 untilDay보다 과거인 경우: 해당 월 전체 (월말 23:59:59까지)
            endOfDay = yearMonth.endOfMonth
        } else {
            // yearMonth가 untilDay와 같은 월인 경우: untilDay의 23:59:59까지
            let day = calendar.component(.day, from: untilDay)
            var components = DateComponents()
            components.year = yearMonth.year
            components.month = yearMonth.month
            components.day = day
            components.hour = 23
            components.minute = 59
            components.second = 59
            endOfDay = calendar.date(from: components) ?? untilDay
        }
        
        // 해당 기간의 거래내역 조회 후 지출만 필터링하여 합계 계산
        let transactions = try await transactionRepository.fetchTransactions(from: startOfMonth, to: endOfDay)
        return transactions
            .filter { $0.transactionType != .income }  // 수입 제외
            .reduce(0) { $0 + $1.amount }              // 지출 합계
    }
}
