//
//  CategoryMonthlyTrendView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/3/25.
//

import SwiftUI
import Charts

struct CategoryMonthlyTrendView: View {
    let data: [CategoryMonthlyPointDTO]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("카테고리별 월간 추이")
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)

            if data.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title2)
                        .foregroundColor(.secondary)

                    Text("월간 추이 데이터가 없습니다")
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text("선택한 기간에 거래 내역이 없습니다")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
            } else {
                Chart(data, id: \.id) { point in
                    LineMark(
                        x: .value("월", point.monthStart, unit: .month),
                        y: .value("지출", Double(truncating: NSDecimalNumber(decimal: point.expense)))
                    )
                    .foregroundStyle(by: .value("카테고리", point.categoryName))
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    .symbol(.circle)
                    .symbolSize(40)
                    .interpolationMethod(.catmullRom)
                }
                .frame(height: 250)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month(.abbreviated), centered: true)
                    }
                }
                .chartYAxis {
                    AxisMarks(format: .currency(code: "KRW"))
                }
                .chartLegend(position: .top)
                .padding(.horizontal, 16)
            }
        }
    }
}

#Preview {
    CategoryMonthlyTrendView(data: CategoryPreviewData.categoryMonthlyPoints)
}
