//
//  BurndownChartView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/2/25.
//

import SwiftUI
import Charts

struct BurndownChartView: View {
    let data: [BurndownPointDTO]
    
    var budgetStatus: String {
        guard let lastPoint = data.last else { return "데이터 없음" }
        let remaining = lastPoint.expectedCumulative - lastPoint.actualCumulative
        let isOverBudget = remaining < 0
        
        if isOverBudget {
            return "예산 초과: \(FormatterManager.shared.formatCurrency(abs(remaining)))"
        } else {
            return "남은 예산: \(FormatterManager.shared.formatCurrency(remaining))"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title and Status
            HStack {
                Text("번다운 차트")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if !data.isEmpty {
                    Text(budgetStatus)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(data.last?.actualCumulative ?? 0 > data.last?.expectedCumulative ?? 0 ? .red : .green)
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
                Chart {
                    ForEach(data) { point in
                        // Budget Baseline (Horizontal Line)
                        RuleMark(
                            y: .value("월 예산", Double(truncating: NSDecimalNumber(decimal: point.monthlyBudget)))
                        )
                        .foregroundStyle(.orange)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                        
                        // Expected Cumulative Spending Line
                        LineMark(
                            x: .value("일", point.date, unit: .day),
                            y: .value("예상 누적 지출", Double(truncating: NSDecimalNumber(decimal: point.expectedCumulative)))
                        )
                        .foregroundStyle(by: .value("일", "에상 누적 지출"))
//                        .foregroundStyle(.blue)
                        .lineStyle(StrokeStyle(dash: [8, 4]))
                        .symbol(.circle)
                        .symbolSize(25)
                        
                        // Actual Cumulative Spending Line
                        LineMark(
                            x: .value("일", point.date, unit: .day),
                            y: .value("실제 누적 지출", Double(truncating: NSDecimalNumber(decimal: point.actualCumulative)))
                        )
                        .foregroundStyle(by: .value("일", "실제 누적 지출"))
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        .symbol(.circle)
                        .symbolSize(30)
                        
                        // Over-budget area (when actual > expected)
                        if point.actualCumulative > point.expectedCumulative {
                            AreaMark(
                                x: .value("일", point.date, unit: .day),
                                yStart: .value("예상", Double(truncating: NSDecimalNumber(decimal: point.expectedCumulative))),
                                yEnd: .value("실제", Double(truncating: NSDecimalNumber(decimal: point.actualCumulative)))
                            )
                            .foregroundStyle(.red.opacity(0.1))
                        }
                    }
                    
                    // Future projection for remaining days
                    if let lastPoint = data.last {
                        let calendar = Calendar.current
                        let monthStart = calendar.startOfMonth(for: lastPoint.date)
                        let monthEnd = calendar.endOfMonthExclusive(for: monthStart)
                        let totalDays = calendar.dateComponents([.day], from: monthStart, to: monthEnd).day ?? 30
                        let remainingDays = totalDays - lastPoint.day
                        
                        if remainingDays > 0 {
                            let dailyRate = lastPoint.actualCumulative / Decimal(lastPoint.day)
                            let projectedTotal = dailyRate * Decimal(totalDays)
                            
                            if let futureDate = calendar.date(byAdding: .day, value: remainingDays, to: lastPoint.date) {
                                LineMark(
                                    x: .value("일", lastPoint.date, unit: .day),
                                    y: .value("예상 총 지출", Double(truncating: NSDecimalNumber(decimal: lastPoint.actualCumulative)))
                                )
                                LineMark(
                                    x: .value("일", futureDate, unit: .day),
                                    y: .value("예상 총 지출", Double(truncating: NSDecimalNumber(decimal: projectedTotal)))
                                )
                                .foregroundStyle(.orange)
                                .lineStyle(StrokeStyle(dash: [3, 3]))
                            }
                        }
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 5)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.day(), centered: true)
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
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.downtrend.xyaxis")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("번다운 차트 데이터가 없습니다")
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text("일별 예산과 거래 내역이 필요합니다")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    BurndownChartView(data: BurndownPointDTO.previewData)
        .padding()
}
