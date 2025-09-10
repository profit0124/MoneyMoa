//
//  TransactionTypeRatioView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/2/25.
//

import SwiftUI
import Charts

struct TransactionTypeRatioView: View {
    let data: TransactionTypeRatioDTO
    
    private var hasData: Bool {
        data.income > 0 || data.expense > 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("거래 유형 분석")
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
            
            if !hasData {
                emptyStateView
            } else {
                HStack(spacing: 20) {
                    // Income vs Expense Chart
                    Chart {
                        SectorMark(
                            angle: .value("수입", data.income),
                            innerRadius: .ratio(0.6),
                            angularInset: 1.5
                        )
                        .foregroundStyle(.green.gradient)
                        
                        SectorMark(
                            angle: .value("지출", data.expense),
                            innerRadius: .ratio(0.6),
                            angularInset: 1.5
                        )
                        .foregroundStyle(.red.gradient)
                    }
                    .frame(width: 100, height: 100)
                    .chartBackground { chartProxy in
                        if let plotFrame = chartProxy.plotFrame {
                            GeometryReader { geometry in
                                let frame = geometry[plotFrame]
                                VStack(spacing: 2) {
                                    Text("총액")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(FormatterManager.shared.formatCurrency(Decimal(data.income + data.expense)))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                }
                                .position(x: frame.midX, y: frame.midY)
                            }
                        }
                    }
                    
                    // Legend and Stats
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(.green)
                                    .frame(width: 8, height: 8)
                                
                                Text("수입")
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text(FormatterManager.shared.formatCurrency(Decimal(data.income)))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.green)
                            }
                            
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(.red)
                                    .frame(width: 8, height: 8)
                                
                                Text("지출")
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text(FormatterManager.shared.formatCurrency(Decimal(data.expense)))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("순수입")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            let netIncome = Decimal(data.income - data.expense)
                            Text(FormatterManager.shared.formatCurrency(netIncome))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(netIncome >= 0 ? .green : .red)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.up.arrow.down.circle")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("거래 유형 데이터가 없습니다")
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text("선택한 기간에 거래 내역이 없습니다")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    StatisticsPreviewHelper.preview { dashboard in
        TransactionTypeRatioView(data: dashboard.pattern.typeRatio)
            .padding()
    }
}
