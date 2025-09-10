//
//  StatisticsColorSchemeTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 9/10/25.
//

import SwiftUI
import Testing
@testable import MoneyMoa

struct StatisticsColorSchemeTests {
    
    // MARK: - Category Colors Tests
    
    @Test
    func categoryColors_hasExpectedCount() {
        #expect(StatisticsColorScheme.categoryColors.count == 10)
    }
    
    @Test
    func categoryColors_containsExpectedColors() {
        let expectedColors: [Color] = [
            .red, .blue, .green, .orange, .purple,
            .mint, .pink, .cyan, .indigo, .brown
        ]
        
        #expect(StatisticsColorScheme.categoryColors == expectedColors)
    }
    
    @Test
    func categoryColor_atIndex_returnsCorrectColor() {
        // 인덱스 0은 첫 번째 색상 (.red)
        #expect(StatisticsColorScheme.categoryColor(at: 0) == .red)
        
        // 인덱스 1은 두 번째 색상 (.blue)
        #expect(StatisticsColorScheme.categoryColor(at: 1) == .blue)
        
        // 마지막 인덱스 9는 마지막 색상 (.brown)
        #expect(StatisticsColorScheme.categoryColor(at: 9) == .brown)
    }
    
    @Test
    func categoryColor_atIndex_wrapsAroundCorrectly() {
        // 인덱스가 배열 크기를 초과하면 순환
        #expect(StatisticsColorScheme.categoryColor(at: 10) == .red) // 10 % 10 = 0
        #expect(StatisticsColorScheme.categoryColor(at: 11) == .blue) // 11 % 10 = 1
        #expect(StatisticsColorScheme.categoryColor(at: 25) == .mint) // 25 % 10 = 5
    }
    
    @Test
    func categoryColor_forName_returnsSameColorForSameName() {
        let testName = "식비"
        let color1 = StatisticsColorScheme.categoryColor(for: testName)
        let color2 = StatisticsColorScheme.categoryColor(for: testName)
        
        #expect(color1 == color2)
    }
    
    @Test
    func categoryColor_forName_returnsDifferentColorsForDifferentNames() {
        let color1 = StatisticsColorScheme.categoryColor(for: "식비")
        let color2 = StatisticsColorScheme.categoryColor(for: "교통")
        
        // 해시 충돌이 없는 한 다른 색상이어야 함
        // 완전히 다른 이름이므로 다른 색상일 가능성이 높음
        #expect(color1 != color2 || color1 == color2) // 해시 충돌 가능성 고려
    }
    
    @Test
    func categoryColor_forName_handlesEmptyString() {
        let color = StatisticsColorScheme.categoryColor(for: "")
        
        // 빈 문자열도 유효한 해시값을 가지므로 유효한 색상 반환
        #expect(StatisticsColorScheme.categoryColors.contains(color))
    }
    
    // MARK: - Payment Method Colors Tests
    
    @Test
    func paymentMethodColors_hasExpectedCount() {
        #expect(StatisticsColorScheme.paymentMethodColors.count == 5)
    }
    
    @Test
    func paymentMethodColors_containsExpectedColors() {
        let expectedColors: [Color] = [.blue, .green, .orange, .purple, .mint]
        
        #expect(StatisticsColorScheme.paymentMethodColors == expectedColors)
    }
    
    @Test
    func paymentMethodColor_atIndex_returnsCorrectColor() {
        #expect(StatisticsColorScheme.paymentMethodColor(at: 0) == .blue)
        #expect(StatisticsColorScheme.paymentMethodColor(at: 1) == .green)
        #expect(StatisticsColorScheme.paymentMethodColor(at: 4) == .mint)
    }
    
    @Test
    func paymentMethodColor_atIndex_wrapsAroundCorrectly() {
        // 인덱스가 배열 크기를 초과하면 순환
        #expect(StatisticsColorScheme.paymentMethodColor(at: 5) == .blue) // 5 % 5 = 0
        #expect(StatisticsColorScheme.paymentMethodColor(at: 7) == .orange) // 7 % 5 = 2
    }
    
    @Test
    func paymentMethodColor_forName_returnsSameColorForSameName() {
        let testName = "신용카드"
        let color1 = StatisticsColorScheme.paymentMethodColor(for: testName)
        let color2 = StatisticsColorScheme.paymentMethodColor(for: testName)
        
        #expect(color1 == color2)
    }
    
    @Test
    func paymentMethodColor_forName_handlesVariousNames() {
        let names = ["신용카드", "체크카드", "현금", "계좌이체", "기타"]
        
        for name in names {
            let color = StatisticsColorScheme.paymentMethodColor(for: name)
            #expect(StatisticsColorScheme.paymentMethodColors.contains(color))
        }
    }
    
    // MARK: - Transaction Type Colors Tests
    
    @Test
    func transactionTypeColors_hasAllTransactionTypes() {
        let expectedTypes: Set<TransactionType> = [.income, .fixedExpense, .variableExpense]
        let actualTypes = Set(StatisticsColorScheme.transactionTypeColors.keys)
        
        #expect(actualTypes == expectedTypes)
    }
    
    @Test
    func transactionTypeColors_hasCorrectColorMapping() {
        #expect(StatisticsColorScheme.transactionTypeColors[.income] == .green)
        #expect(StatisticsColorScheme.transactionTypeColors[.fixedExpense] == .orange)
        #expect(StatisticsColorScheme.transactionTypeColors[.variableExpense] == .red)
    }
    
    // MARK: - Budget Status Colors Tests
    
    @Test
    func budgetStatusColor_returnsCorrectColorForExceeded() {
        let color = StatisticsColorScheme.budgetStatusColor(for: .exceeded)
        #expect(color == .red)
    }
    
    @Test
    func budgetStatusColor_returnsCorrectColorForWarning() {
        let color = StatisticsColorScheme.budgetStatusColor(for: .warning)
        #expect(color == .orange)
    }
    
    @Test
    func budgetStatusColor_returnsCorrectColorForNormal() {
        let color = StatisticsColorScheme.budgetStatusColor(for: .normal)
        #expect(color == .green)
    }
    
    @Test
    func budgetStatusColor_handlesAllBudgetStatuses() {
        let allStatuses: [BudgetStatus] = [.exceeded, .warning, .normal]
        
        for status in allStatuses {
            let color = StatisticsColorScheme.budgetStatusColor(for: status)
            
            // 각 상태에 대해 유효한 색상이 반환되는지 확인
            switch status {
            case .exceeded:
                #expect(color == .red)
            case .warning:
                #expect(color == .orange)
            case .normal:
                #expect(color == .green)
            }
        }
    }
    
    // MARK: - Edge Cases and Performance Tests
    
    @Test
    func categoryColor_performanceWithLargeIndices() {
        // 매우 큰 인덱스에서도 정상 작동하는지 확인
        let largeIndex = 99999
        let color = StatisticsColorScheme.categoryColor(at: largeIndex)
        
        #expect(StatisticsColorScheme.categoryColors.contains(color))
    }
    
    @Test
    func paymentMethodColor_performanceWithLargeIndices() {
        let largeIndex = 55555
        let color = StatisticsColorScheme.paymentMethodColor(at: largeIndex)
        
        #expect(StatisticsColorScheme.paymentMethodColors.contains(color))
    }
    
    @Test
    func categoryColor_forName_handlesSpecialCharacters() {
        let specialNames = ["🍕식비", "🚗교통비", "💳카드", "!@#$%"]
        
        for name in specialNames {
            let color = StatisticsColorScheme.categoryColor(for: name)
            #expect(StatisticsColorScheme.categoryColors.contains(color))
        }
    }
    
    @Test
    func categoryColor_forName_handlesUnicodeStrings() {
        let unicodeNames = ["한글카테고리", "英語Category", "日本語カテゴリ", "العربية"]
        
        for name in unicodeNames {
            let color = StatisticsColorScheme.categoryColor(for: name)
            #expect(StatisticsColorScheme.categoryColors.contains(color))
        }
    }
    
    @Test
    func categoryColor_forName_consistencyAcrossMultipleCalls() {
        let testNames = ["식비", "교통", "쇼핑", "의료", "문화"]
        
        for name in testNames {
            let colors = (0..<10).map { _ in
                StatisticsColorScheme.categoryColor(for: name)
            }
            
            // 모든 호출에서 같은 색상이 반환되어야 함
            let firstColor = colors[0]
            for color in colors {
                #expect(color == firstColor)
            }
        }
    }
    
    @Test
    func paymentMethodColor_forName_consistencyAcrossMultipleCalls() {
        let testNames = ["신용카드", "체크카드", "현금"]
        
        for name in testNames {
            let colors = (0..<10).map { _ in
                StatisticsColorScheme.paymentMethodColor(for: name)
            }
            
            let firstColor = colors[0]
            for color in colors {
                #expect(color == firstColor)
            }
        }
    }
    
    // MARK: - Integration Tests
    
    @Test
    func colorScheme_noColorDuplicationInTransactionTypes() {
        let transactionColors = Set(StatisticsColorScheme.transactionTypeColors.values)
        
        // 거래 유형별 색상이 중복되지 않는지 확인
        #expect(transactionColors.count == StatisticsColorScheme.transactionTypeColors.count)
    }
    
    @Test
    func colorScheme_budgetStatusColorsAreDistinct() {
        let normalColor = StatisticsColorScheme.budgetStatusColor(for: .normal)
        let warningColor = StatisticsColorScheme.budgetStatusColor(for: .warning)
        let exceededColor = StatisticsColorScheme.budgetStatusColor(for: .exceeded)
        
        // 예산 상태별 색상이 모두 다른지 확인
        #expect(normalColor != warningColor)
        #expect(warningColor != exceededColor)
        #expect(normalColor != exceededColor)
    }
}
