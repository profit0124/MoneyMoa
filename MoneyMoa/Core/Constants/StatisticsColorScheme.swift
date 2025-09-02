//
//  StatisticsColorScheme.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/2/25.
//

import SwiftUI

/// 통계 차트에서 사용하는 색상 스키마
public struct StatisticsColorScheme {
    
    // MARK: - Category Colors
    /// 카테고리별 색상 배열 (최대 10개 카테고리 지원)
    public static let categoryColors: [Color] = [
        .red,        // 식비
        .blue,       // 교통
        .green,      // 쇼핑
        .orange,     // 의료/건강
        .purple,     // 문화/여가
        .mint,       // 교육
        .pink,       // 주거/통신
        .cyan,       // 경조사/회비
        .indigo,     // 보험/세금
        .brown       // 기타
    ]
    
    // MARK: - Payment Method Colors
    /// 결제수단별 색상 배열
    public static let paymentMethodColors: [Color] = [
        .blue,       // 신용카드
        .green,      // 체크카드
        .orange,     // 현금
        .purple,     // 계좌이체
        .mint        // 기타
    ]
    
    // MARK: - Transaction Type Colors
    /// 거래 유형별 색상
    public static let transactionTypeColors: [TransactionType: Color] = [
        .income: .green,
        .fixedExpense: .orange,
        .variableExpense: .red
    ]
    
    // MARK: - Budget Status Colors
    /// 예산 상태별 색상
    public static func budgetStatusColor(for status: BudgetStatus) -> Color {
        switch status {
        case .exceeded:
            return .red
        case .warning:
            return .orange
        case .normal:
            return .green
        }
    }
    
    // MARK: - Helper Methods
    
    /// 카테고리 인덱스에 따른 색상 반환
    public static func categoryColor(at index: Int) -> Color {
        categoryColors[index % categoryColors.count]
    }
    
    /// 결제수단 인덱스에 따른 색상 반환
    public static func paymentMethodColor(at index: Int) -> Color {
        paymentMethodColors[index % paymentMethodColors.count]
    }
    
    /// 카테고리 이름에 기반한 일관된 색상 반환 (해시 기반)
    public static func categoryColor(for name: String) -> Color {
        let hash = abs(name.hashValue)
        return categoryColors[hash % categoryColors.count]
    }
    
    /// 결제수단 이름에 기반한 일관된 색상 반환 (해시 기반)
    public static func paymentMethodColor(for name: String) -> Color {
        let hash = abs(name.hashValue)
        return paymentMethodColors[hash % paymentMethodColors.count]
    }
}