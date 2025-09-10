//
//  MerchantRankingView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/2/25.
//

import SwiftUI
import Charts

struct MerchantRankingView: View {
    let data: MerchantRankingDTO
    
    private var hasData: Bool {
        !data.entries.isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("주요 가맹점 순위")
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
            
            if !hasData {
                emptyStateView
            } else {
                // Top Merchants Chart
                Chart(data.entries.prefix(8), id: \.id) { merchant in
                    BarMark(
                        x: .value("지출액", Double(truncating: NSDecimalNumber(decimal: merchant.total))),
                        y: .value("가맹점", merchant.merchant)
                    )
                    .foregroundStyle(StatisticsColorScheme.categoryColor(at: merchant.rank - 1).gradient)
                    .cornerRadius(4)
                }
                .frame(height: 200)
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
                
                // Top 5 Merchants List
                VStack(spacing: 8) {
                    ForEach(data.entries.prefix(5)) { merchant in
                        MerchantRankCard(merchant: merchant)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "building.2.fill")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("가맹점 데이터가 없습니다")
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
}

struct MerchantRankCard: View {
    let merchant: MerchantRankingDTO.Entry
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank Badge
            Text("\(merchant.rank)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(StatisticsColorScheme.categoryColor(at: merchant.rank - 1)))
            
            // Merchant Info
            VStack(alignment: .leading, spacing: 2) {
                Text(merchant.merchant)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("\(merchant.count)건")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Amount
            Text(FormatterManager.shared.formatCurrency(merchant.total))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
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
        MerchantRankingView(data: dashboard.pattern.merchants)
            .padding()
    }
}
