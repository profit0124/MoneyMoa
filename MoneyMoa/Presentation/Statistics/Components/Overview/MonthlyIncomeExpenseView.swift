//
//  MonthlyIncomeExpenseView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/2/25.
//

import SwiftUI
import Charts

struct MonthlyIncomeExpenseView: View {
    let data: [MonthlyPointDTO]
    @State private var showNetIncome = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title and Toggle
            HStack {
                Text("월별 수입/지출 추이")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if !data.isEmpty {
                    Button {
                        showNetIncome.toggle()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: showNetIncome ? "eye.fill" : "eye.slash.fill")
                                .font(.caption)
                            Text("순수입")
                                .font(.caption)
                        }
                        .foregroundColor(showNetIncome ? .blue : .gray)
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
                        // Income Bar
                        BarMark(
                            x: .value("월", point.monthStart, unit: .month),
                            y: .value("수입", Double(truncating: NSDecimalNumber(decimal: point.income))),
                            width: .ratio(0.4)
                        )
                        .foregroundStyle(.green.gradient)
                        .position(by: .value("타입", "수입"))
                        
                        // Expense Bar
                        BarMark(
                            x: .value("월", point.monthStart, unit: .month),
                            y: .value("지출", Double(truncating: NSDecimalNumber(decimal: point.expense))),
                            width: .ratio(0.4)
                        )
                        .foregroundStyle(.red.gradient)
                        .position(by: .value("타입", "지출"))
                        
                        // Net Income Line
                        if showNetIncome {
                            LineMark(
                                x: .value("월", point.monthStart, unit: .month),
                                y: .value("순수입", Double(truncating: NSDecimalNumber(decimal: point.netIncome)))
                            )
                            .foregroundStyle(.blue)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                            .symbol(Circle().strokeBorder(lineWidth: 2))
                            .symbolSize(40)
                        }
                    }
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
                
                // Summary Cards
                ScrollView(.horizontal, showsIndicators: false) {
                    ScrollViewReader { proxy in
                        HStack(spacing: 12) {
                            ForEach(data) { point in
                                MonthSummaryCard(point: point)
                                    .id(point.monthStart)
                            }
                        }
                        .padding(.horizontal, 16)
                        .onAppear {
                            if let lastMonth = data.last?.monthStart {
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
            Image(systemName: "chart.bar.xaxis")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("수입/지출 데이터가 없습니다")
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
        let sum = data.reduce(into: Decimal.zero) { $0 += $1.expense }
        return sum / Decimal(data.count)
    }
    
    private var maxExpense: Decimal {
        data.map(\.expense).max() ?? 0
    }
    
    private var averageIncome: Decimal {
        guard !data.isEmpty else { return 0 }
        let sum = data.reduce(into: Decimal.zero) { $0 += $1.income }
        return sum / Decimal(data.count)
    }
}

struct MonthSummaryCard: View {
    let point: MonthlyPointDTO
    
    private var monthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월"
        return formatter.string(from: point.monthStart)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(monthName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("저축률")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(String(format: "%.1f", point.savingsRate))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                HStack {
                    Text("전월대비")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack(spacing: 2) {
                        Image(systemName: point.previousMonthChange >= 0 ? "arrow.up" : "arrow.down")
                            .font(.system(size: 8))
                        Text("\(String(format: "%.1f", abs(point.previousMonthChange)))%")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(point.previousMonthChange >= 0 ? .red : .green)
                }
            }
        }
        .padding(12)
        .frame(width: 150)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.tertiarySystemGroupedBackground))
        }
    }
}

#Preview {
    MonthlyIncomeExpenseView(data: MonthlyPointDTO.previewData)
        .padding()
}
