//
//  CategoryBudgetView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/2/25.
//

import SwiftUI
import Charts

struct CategoryBudgetView: View {
    let data: [CategoryBudgetVsExpenseDTO]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("카테고리별 예산 관리")
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
            
            // Budget Progress Chart or Empty State
            if data.isEmpty {
                emptyStateView
            } else {
                // Budget Progress Chart
                Chart(data, id: \.categoryName) { category in
                    // Budget Bar (Background)
                    let title1 = category.budget >= category.expense ? "남은 예산" : "초과 지출"
                    let title2 = category.budget >= category.expense ? "지출" : "예산"

                    BarMark(
                        x: .value(title1, min(
                            Double(truncating: NSDecimalNumber(decimal: category.expense)),
                            Double(truncating: NSDecimalNumber(decimal: category.budget))
                        )),
                        y: .value("카테고리", category.categoryName)
                    )
                    .foregroundStyle(.gray.opacity(0.3))
                    .cornerRadius(4)
                    
                    // Actual Expense Bar (Foreground)
                    BarMark(
                        x: .value(title2, Double(truncating: NSDecimalNumber(decimal: abs(category.expense - category.budget)))),
                        y: .value("카테고리", category.categoryName)
                    )
                    .foregroundStyle(category.expense > category.budget ? Color.red.gradient : Color.green.gradient)
                    .cornerRadius(4)
                }
                .frame(height: CGFloat(data.count * 30 + 50))
                .chartXAxis {
                    AxisMarks(position: .bottom) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text(FormatterManager.shared.formatCurrency(Decimal(doubleValue)))
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisTick()
                        AxisValueLabel()
                    }
                }
                .padding(.horizontal, 16)
                
                // Budget Status Cards
                VStack(spacing: 8) {
                    ForEach(data.prefix(5)) { category in
                        CategoryBudgetCard(category: category)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "target")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("카테고리별 예산이 설정되지 않았습니다")
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text("카테고리별 예산을 설정해주세요")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
}

struct CategoryBudgetCard: View {
    let category: CategoryBudgetVsExpenseDTO
    
    private var budgetStatus: (percentage: Double, isOver: Bool) {
        let percentage = Double(truncating: NSDecimalNumber(decimal: category.expense / category.budget * 100))
        return (percentage, percentage > 100)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Category Color Indicator
            Circle()
                .fill(category.color)
                .frame(width: 12, height: 12)
            
            // Category Info
            VStack(alignment: .leading, spacing: 2) {
                Text(category.categoryName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    Text(FormatterManager.shared.formatCurrency(category.expense))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("/")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(FormatterManager.shared.formatCurrency(category.budget))
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            // Progress Indicator
            VStack(alignment: .trailing, spacing: 4) {
                let status = budgetStatus
                Text("\(String(format: "%.0f", status.percentage))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(status.isOver ? .red : .green)
                
                // Mini Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(.tertiarySystemFill))
                            .frame(height: 4)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(status.isOver ? Color.red : Color.green)
                            .frame(width: min(geometry.size.width, geometry.size.width * CGFloat(status.percentage / 100)), height: 4)
                    }
                }
                .frame(width: 40, height: 4)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.tertiarySystemGroupedBackground))
        }
    }
}

#Preview {
    StatisticsPreviewHelper.preview { dashboard in
        CategoryBudgetView(data: dashboard.budget.byCategory)
            .padding()
    }
}

#Preview("Empty") {
    CategoryBudgetView(data: [])
        .padding()
}
