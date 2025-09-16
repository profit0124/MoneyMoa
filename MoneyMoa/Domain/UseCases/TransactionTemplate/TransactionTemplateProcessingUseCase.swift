//
//  ProcessDueTransactionTemplatesUseCase.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/15/25.
//

import Foundation

/// 반복 거래 템플릿 자동 처리 유스케이스
/// 앱 시작 시 또는 정기적으로 실행하여 처리 예정인 템플릿을 Transaction으로 변환
public protocol TransactionTemplateProcessingUseCase {
    /// 처리 예정인 템플릿들을 확인하여 Transaction을 생성하고 템플릿을 업데이트
    /// - Parameter upToDate: 기준 날짜 (이 날짜까지 처리)
    /// - Returns: 생성된 Transaction의 개수
    func execute(upToDate: Date) async throws -> Int
}
