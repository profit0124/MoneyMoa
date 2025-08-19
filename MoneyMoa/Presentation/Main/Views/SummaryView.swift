//
//  SummarySectionView.swift
//  MoneyMoa
//
//  Created by Claude on 8/4/25.
//

import SwiftUI

// MARK: - SummarySectionView

struct SummaryView: View {
    let summaryData: SummaryDisplayData?
    let isLoading: Bool
    let onBudgetSetupTap: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            if isLoading {
                // 로딩 상태
                SummaryLoadingView()
            } else if let summaryData = summaryData {
                // 데이터 있음
                SummaryContentView(
                    summaryData: summaryData,
                    onBudgetSetupTap: onBudgetSetupTap
                )
            } else {
                // 에러 상태
                SummaryErrorView()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - SummaryContentView

private struct SummaryContentView: View {
    let summaryData: SummaryDisplayData
    let onBudgetSetupTap: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // 현재 월 지출 (항상 표시)
            CurrentMonthExpenseView(amount: summaryData.currentMonthExpense)
            
            // 예산 정보
            if summaryData.hasBudget {
                BudgetInfoView(summaryData: summaryData)
            } else {
                BudgetSetupBannerView(onTap: onBudgetSetupTap)
            }
            
            // 전월 비교 (데이터가 있을 때만)
            if summaryData.canShowComparison {
                MonthlyComparisonView(summaryData: summaryData)
            }
        }
    }
}

// MARK: - CurrentMonthExpenseView

private struct CurrentMonthExpenseView: View {
    let amount: Decimal
    
    var body: some View {
        VStack(spacing: 4) {
            Text("이번 달 총 지출")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(formattedAmount)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private var formattedAmount: String {
        amount.formattedAmountWithWon
    }
}

// MARK: - BudgetInfoView

private struct BudgetInfoView: View {
    let summaryData: SummaryDisplayData
    
    var body: some View {
        VStack(spacing: 12) {
            // 예산 사용률
            if let usagePercentage = summaryData.budgetUsagePercentage {
                BudgetUsageProgressView(
                    percentage: usagePercentage,
                    isExceeded: summaryData.isBudgetExceeded
                )
            }
            
            // 예산 상세 정보
            HStack(spacing: 16) {
                // 예산 총액
                if let budget = summaryData.budget {
                    BudgetInfoItemView(
                        title: "예산",
                        amount: budget.totalAmount,
                        color: .blue
                    )
                }
                
                // 남은 예산
                if let remainingBudget = summaryData.remainingBudget {
                    BudgetInfoItemView(
                        title: summaryData.isBudgetExceeded ? "초과" : "잔여",
                        amount: abs(remainingBudget),
                        color: summaryData.isBudgetExceeded ? .red : .green
                    )
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - BudgetUsageProgressView

private struct BudgetUsageProgressView: View {
    let percentage: Double
    let isExceeded: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("예산 사용률")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formattedPercentage)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(progressColor)
            }
            
            ProgressView(value: min(percentage, 1.0))
                .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                .scaleEffect(x: 1, y: 2)
        }
    }
    
    private var formattedPercentage: String {
        "\(Int(percentage * 100))%"
    }
    
    private var progressColor: Color {
        if isExceeded {
            return .red
        } else if percentage > 0.8 {
            return .orange
        } else {
            return .blue
        }
    }
}

// MARK: - BudgetInfoItemView

private struct BudgetInfoItemView: View {
    let title: String
    let amount: Decimal
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(formattedAmount)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var formattedAmount: String {
        FormatterManager.shared.amountFormatter.string(from: amount as NSDecimalNumber) ?? "0원"
    }
}

// MARK: - BudgetSetupBannerView

private struct BudgetSetupBannerView: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("예산을 설정해보세요")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("월별 지출 목표를 설정하고 관리하세요")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - MonthlyComparisonView

private struct MonthlyComparisonView: View {
    let summaryData: SummaryDisplayData
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("전월 대비")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    Text(comparisonText)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(comparisonColor)
                    
                    ComparisonIconView(
                        isIncreased: summaryData.isExpenseIncreased,
                        color: comparisonColor
                    )
                }
            }
            
            Spacer()
            
            if let percentage = summaryData.comparisonPercentage {
                Text(formattedPercentage(percentage))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(comparisonColor)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(comparisonColor.opacity(0.1))
        )
    }
    
    private var comparisonText: String {
        guard let comparison = summaryData.monthlyComparison else { return "0원" }
        let formattedAmount = FormatterManager.shared.amountFormatter.string(from: abs(comparison) as NSDecimalNumber) ?? "0원"
        
        if summaryData.isExpenseIncreased {
            return "+\(formattedAmount)"
        } else if summaryData.isExpenseDecreased {
            return "-\(formattedAmount)"
        } else {
            return "동일"
        }
    }
    
    private var comparisonColor: Color {
        if summaryData.isExpenseIncreased {
            return .red
        } else if summaryData.isExpenseDecreased {
            return .green
        } else {
            return .gray
        }
    }
    
    private func formattedPercentage(_ percentage: Double) -> String {
        let percent = Int(abs(percentage) * 100)
        if summaryData.isExpenseIncreased {
            return "\(percent)% ↑"
        } else if summaryData.isExpenseDecreased {
            return "\(percent)% ↓"
        } else {
            return "0%"
        }
    }
}

// MARK: - ComparisonIconView

private struct ComparisonIconView: View {
    let isIncreased: Bool
    let color: Color
    
    var body: some View {
        Image(systemName: iconName)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(color)
    }
    
    private var iconName: String {
        isIncreased ? "arrow.up" : "arrow.down"
    }
}

// MARK: - Loading & Error Views

private struct SummaryLoadingView: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("요약 정보를 불러오는 중...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

private struct SummaryErrorView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 24))
                .foregroundColor(.orange)
            
            Text("요약 정보를 불러올 수 없습니다")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // 예산 있는 경우
        SummaryView(
            summaryData: SummaryDisplayData(
                currentMonthExpense: Decimal(1_500_000),
                previousMonthExpense: Decimal(1_200_000),
                monthlyComparison: Decimal(300_000),
                comparisonPercentage: 0.25,
                hasPreviousMonthData: true,
                budget: BudgetDTO(
                    month: YearMonth.current,
                    totalAmount: Decimal(2_000_000),
                    categoryBudgets: []
                ),
                remainingBudget: Decimal(500_000),
                budgetUsagePercentage: 0.75
            ),
            isLoading: false,
            onBudgetSetupTap: {}
        )
        
        Divider()
        
        // 예산 없는 경우
        SummaryView(
            summaryData: SummaryDisplayData(
                currentMonthExpense: Decimal(800_000),
                previousMonthExpense: Decimal(0),
                monthlyComparison: nil,
                comparisonPercentage: nil,
                hasPreviousMonthData: false,
                budget: nil,
                remainingBudget: nil,
                budgetUsagePercentage: nil
            ),
            isLoading: false,
            onBudgetSetupTap: {}
        )
        
        Spacer()
    }
    .padding()
}
