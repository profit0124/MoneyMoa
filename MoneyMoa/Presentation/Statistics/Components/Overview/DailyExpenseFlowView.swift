//
//  DailyExpenseFlowView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/2/25.
//

import SwiftUI
import Charts

struct DailyExpenseFlowView: View {
    let data: [DailyPointDTO]
    @State private var showMovingAverage = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title and Toggle
            HStack {
                Text("일별 지출 흐름")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if !data.isEmpty {
                    Button {
                        showMovingAverage.toggle()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: showMovingAverage ? "eye.fill" : "eye.slash.fill")
                                .font(.caption)
                            Text("7일 평균")
                                .font(.caption)
                        }
                        .foregroundColor(showMovingAverage ? .blue : .gray)
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
                        // Daily Expense Line
                        LineMark(
                            x: .value("날짜", point.date, unit: .day),
                            y: .value("일별 지출", Double(truncating: NSDecimalNumber(decimal: point.amount)))
                        )
                        .foregroundStyle(by: .value("날짜", "일별 지출"))
                        .lineStyle(StrokeStyle(lineWidth: 1))

                        // Weekend highlighting
                        if point.isWeekend {
                            PointMark(
                                x: .value("날짜", point.date, unit: .day),
                                y: .value("일별 지출", Double(truncating: NSDecimalNumber(decimal: point.amount))),

                            )
                            .foregroundStyle(.red)
                            .symbolSize(30)
                        }
                        
                        // Moving Average Line
                        if showMovingAverage {
                            LineMark(
                                x: .value("날짜", point.date, unit: .day),
                                y: .value("7일 평균", Double(truncating: NSDecimalNumber(decimal: point.movingAverage)))
                            )
                            .foregroundStyle(by: .value("날짜", "7일 평균"))
                            .lineStyle(StrokeStyle(lineWidth: 3))
                        }
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day(), centered: true)
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
                
                // Statistics Summary
                HStack(spacing: 20) {
                    StatCard(
                        title: "평균 지출",
                        value: FormatterManager.shared.formatCurrency(averageExpense),
                        color: .red
                    )
                    
                    StatCard(
                        title: "최고 지출",
                        value: FormatterManager.shared.formatCurrency(maxExpense),
                        color: .orange
                    )
                    
                    StatCard(
                        title: "주말 평균",
                        value: FormatterManager.shared.formatCurrency(weekendAverage),
                        color: .purple
                    )
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("일별 지출 데이터가 없습니다")
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text("선택한 기간에 거래 내역이 없습니다")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
    
    private var averageExpense: Decimal {
        guard !data.isEmpty else { return 0 }
        let sum = data.reduce(into: Decimal.zero) { $0 += $1.amount }
        return sum / Decimal(data.count)
    }
    
    private var maxExpense: Decimal {
        data.map(\.amount).max() ?? 0
    }
    
    private var weekendAverage: Decimal {
        let weekendData = data.filter(\.isWeekend)
        guard !weekendData.isEmpty else { return 0 }
        let sum = weekendData.reduce(into: Decimal.zero) { $0 += $1.amount }
        return sum / Decimal(weekendData.count)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.tertiarySystemGroupedBackground))
        }
    }
}

#Preview {
    DailyExpenseFlowView(data: DailyPointDTO.previewData)
        .padding()
}
