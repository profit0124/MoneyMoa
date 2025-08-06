//
//  GetExpenseSumUntilDateUseCase.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/4/25.
//

import Foundation

// MARK: - GetExpenseSumUntilDateUseCase Protocol

public protocol GetExpenseSumUntilDateUseCase {
    /// 특정 연월의 시작일부터 지정된 날짜까지의 지출 합계를 조회합니다.
    /// 
    /// - Parameters:
    ///   - yearMonth: 조회할 연월
    ///   - untilDay: 종료 기준 날짜 (기본값: 현재 날짜)
    /// 
    /// - Returns: 해당 기간의 지출 총합 (수입 제외)
    /// 
    /// - Note: 
    ///   - yearMonth가 untilDay보다 과거인 경우: 해당 월 전체 (월말 23:59:59까지)
    ///   - yearMonth가 untilDay와 같은 월인 경우: untilDay의 23:59:59까지
    /// 
    /// - Example:
    ///   ```swift
    ///   // 8월 4일 현재 기준
    ///   let currentDate = Date() // 2024-08-04
    ///   
    ///   // 7월 전체 지출: 7월 1일 ~ 7월 31일 23:59:59
    ///   let julySum = await useCase.execute(yearMonth: YearMonth(year: 2024, month: 7), untilDay: currentDate)
    ///   
    ///   // 8월 현재까지 지출: 8월 1일 ~ 8월 4일 23:59:59
    ///   let augustSum = await useCase.execute(yearMonth: YearMonth(year: 2024, month: 8), untilDay: currentDate)
    ///   ```
    func execute(yearMonth: YearMonth, untilDay: Date) async throws -> Decimal
}
