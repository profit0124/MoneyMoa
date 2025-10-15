//
//  TemplateUpdateStrategy.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 10/15/25.
//

import Foundation

/// 거래 수정 시 연관된 템플릿의 업데이트 전략
public enum TemplateUpdateStrategy {
    /// 템플릿도 함께 수정
    /// - 금액, 장소, 메모, 거래 타입, 카테고리, 결제 수단 동기화
    /// - RecurrencePattern과 nextDueDate는 유지
    case updateWithTemplate

    /// 템플릿 관련 변경 없음 (거래만 수정)
    case none
}
