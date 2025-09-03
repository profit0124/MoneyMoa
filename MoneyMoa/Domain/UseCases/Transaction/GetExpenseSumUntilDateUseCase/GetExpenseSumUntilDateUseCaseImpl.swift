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
    
    private let transactionReader: TransactionReader
    
    // MARK: - Initialization
    
    public init(transactionReader: TransactionReader) {
        self.transactionReader = transactionReader
    }
    
    // MARK: - UseCase Methods
    
    public func execute(yearMonth: YearMonth, untilDay: Date = Date()) async throws -> Decimal {
        let startOfMonth = yearMonth.startOfMonth
        let calendar = FormatterManager.shared.koreaCalendar
        
        // 종료 날짜 결정: 현재 월, 직전 월, 그 이전 월에 따라 분기
        let endOfDay: Date
        
        if yearMonth < YearMonth(from: Date()).previousMonth() {
            // 그 이전 월들인 경우: 해당 월 전체 (월말 23:59:59까지)
            endOfDay = yearMonth.endOfMonth
        } else {
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
        let transactions = try await transactionReader.fetchTransactions(from: startOfMonth, to: endOfDay)
        return transactions
            .filter { $0.transactionType != .income }  // 수입 제외
            .reduce(0) { $0 + $1.amount }              // 지출 합계
    }
}
