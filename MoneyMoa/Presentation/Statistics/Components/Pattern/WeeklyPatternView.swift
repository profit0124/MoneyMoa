//
//  WeeklyPatternView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/2/25.
//

import SwiftUI
import Charts

struct WeeklyPatternView: View {
    let data: WeeklyPatternDTO
    
    private var weekdayNames: [String] {
        ["일", "월", "화", "수", "목", "금", "토"]
    }
    
    private var weekdayAverage: Decimal {
        let weekdays = data.days.filter { $0.weekday >= 2 && $0.weekday <= 6 }
        guard !weekdays.isEmpty else { return 0 }
        let sum = weekdays.reduce(into: Decimal.zero) { $0 += $1.avgAmount }
        return sum / Decimal(weekdays.count)
    }
    
    private var weekendAverage: Decimal {
        let weekends = data.days.filter { $0.weekday == 1 || $0.weekday == 7 }
        guard !weekends.isEmpty else { return 0 }
        let sum = weekends.reduce(into: Decimal.zero) { $0 += $1.avgAmount }
        return sum / Decimal(weekends.count)
    }
    
    private var highestDay: Int {
        guard !data.days.isEmpty else { return 1 }
        return data.days.max(by: { $0.avgAmount < $1.avgAmount })?.weekday ?? 1
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("요일별 지출 패턴")
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
            
            if data.days.isEmpty {
                emptyStateView
            } else {
                // Bar Chart
                Chart(data.days, id: \.weekday) { day in
                    BarMark(
                        x: .value("요일", weekdayNames[day.weekday - 1]),
                        y: .value("평균 지출", Double(truncating: NSDecimalNumber(decimal: day.avgAmount)))
                    )
                    .foregroundStyle(day.weekday == 1 || day.weekday == 7 ? Color.red.gradient : Color.blue.gradient)
                    .cornerRadius(6)
                }
                .frame(height: 180)
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
                .padding(.horizontal, 16)
                
                // Pattern Summary
                HStack(spacing: 12) {
                    PatternCard(
                        title: "평일 평균",
                        value: FormatterManager.shared.formatCurrency(weekdayAverage),
                        color: .blue
                    )
                    
                    PatternCard(
                        title: "주말 평균",
                        value: FormatterManager.shared.formatCurrency(weekendAverage),
                        color: .red
                    )
                    
                    PatternCard(
                        title: "가장 큰 요일",
                        value: weekdayNames[highestDay - 1],
                        color: .purple
                    )
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("요일별 패턴 데이터가 없습니다")
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text("선택한 기간에 거래 내역이 없습니다")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 180)
        .frame(maxWidth: .infinity)
    }
}

struct PatternCard: View {
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
    WeeklyPatternView(data: WeeklyPatternDTO.previewData)
        .padding()
}
