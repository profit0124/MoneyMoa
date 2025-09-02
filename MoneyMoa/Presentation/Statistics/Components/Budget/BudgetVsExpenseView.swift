//
//  BudgetVsExpenseView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/2/25.
//

import SwiftUI
import Charts

struct BudgetVsExpenseView: View {
    let data: [BudgetVsExpenseDTO]
    
    var overallBudgetStatus: (isOver: Bool, amount: Decimal) {
        guard let latest = data.last else { return (false, 0) }
        let difference = latest.expense - latest.budget
        return (difference > 0, abs(difference))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title and Overall Status
            HStack {
                Text("예산 vs 실제 지출")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if !data.isEmpty {
                    let status = overallBudgetStatus
                    Text(status.isOver ? "초과: \(FormatterManager.shared.formatCurrency(status.amount))" : "남음: \(FormatterManager.shared.formatCurrency(status.amount))")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(status.isOver ? .red : .green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.tertiarySystemGroupedBackground))
                        }
                }
            }
            .padding(.horizontal, 16)
            
            // Chart or Empty State
            if data.isEmpty {
                emptyStateView
            } else {
                // Chart
                Chart(data) { point in
                    // Budget Line (Target)
                    LineMark(
                        x: .value("월", point.monthStart, unit: .month),
                        y: .value("예산", Double(truncating: NSDecimalNumber(decimal: point.budget)))
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(dash: [8, 4]))
                    .symbol(.circle)
                    .symbolSize(30)
                    
                    // Actual Expense Bar
                    BarMark(
                        x: .value("월", point.monthStart, unit: .month),
                        y: .value("실제 지출", Double(truncating: NSDecimalNumber(decimal: point.expense)))
                    )
                    .foregroundStyle(point.expense > point.budget ? .red : .green)
                    .opacity(0.7)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month(.abbreviated), centered: true)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
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
                .chartLegend(position: .bottom, alignment: .center)
                .padding(.horizontal, 16)
                
                // Budget Summary
                ScrollView(.horizontal, showsIndicators: false) {
                    ScrollViewReader { proxy in
                        HStack(spacing: 12) {
                            ForEach(data.suffix(3)) { point in
                                BudgetStatusCard(point: point)
                                    .id(point.monthStart)
                            }
                        }
                        .padding(.horizontal, 16)
                        .onAppear {
                            if let lastMonth = data.suffix(3).last?.monthStart {
                                proxy.scrollTo(lastMonth, anchor: .trailing)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "dollarsign.circle")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("예산 데이터가 설정되지 않았습니다")
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text("예산을 설정하고 거래를 추가해주세요")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
}

struct BudgetStatusCard: View {
    let point: BudgetVsExpenseDTO
    
    private var monthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월"
        return formatter.string(from: point.monthStart)
    }
    
    private var budgetStatus: (isOver: Bool, percentage: Double) {
        let percentage = Double(truncating: NSDecimalNumber(decimal: point.expense / point.budget * 100))
        return (percentage > 100, percentage)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(monthName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("예산 달성률")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    let status = budgetStatus
                    Text("\(String(format: "%.1f", status.percentage))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(status.isOver ? .red : .green)
                }
                
                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(.tertiarySystemFill))
                            .frame(height: 4)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(budgetStatus.isOver ? Color.red : Color.green)
                            .frame(width: min(geometry.size.width, geometry.size.width * CGFloat(budgetStatus.percentage / 100)), height: 4)
                    }
                }
                .frame(height: 4)
                
                HStack {
                    Text("차이")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    let difference = point.expense - point.budget
                    Text(FormatterManager.shared.formatCurrency(abs(difference)))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(difference > 0 ? .red : .green)
                }
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
    BudgetVsExpenseView(data: BudgetVsExpenseDTO.previewData)
        .padding()
}

#Preview("Empty") {
    BudgetVsExpenseView(data: [])
        .padding()
}
