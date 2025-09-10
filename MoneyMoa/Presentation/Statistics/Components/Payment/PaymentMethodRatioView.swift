//
//  PaymentMethodRatioView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/2/25.
//

import SwiftUI
import Charts

struct PaymentMethodRatioView: View {
    let data: [PaymentMethodRatioDTO]
    @State private var selectedMethod: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("결제 수단 비율")
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
            
            if data.isEmpty {
                emptyStateView
            } else {
                HStack(spacing: 20) {
                    // Donut Chart
                    Chart(data, id: \.methodName) { method in
                        SectorMark(
                            angle: .value("비율", method.ratio),
                            innerRadius: .ratio(0.6),
                            angularInset: 1.5
                        )
                        .foregroundStyle(method.color.gradient)
                        .opacity(selectedMethod == nil || selectedMethod == method.methodName ? 1.0 : 0.5)
                    }
                    .frame(width: 120, height: 120)
                    .chartBackground { chartProxy in
                        if let plotFrame = chartProxy.plotFrame {
                            GeometryReader { geometry in
                                let frame = geometry[plotFrame]
                                VStack(spacing: 2) {
                                    Text("총 거래")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text("\(data.reduce(0) { $0 + $1.count })건")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                }
                                .position(x: frame.midX, y: frame.midY)
                            }
                        }
                    }
                    
                    // Legend
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(data, id: \.methodName) { method in
                            PaymentMethodLegendItem(
                                method: method,
                                isSelected: selectedMethod == method.methodName
                            )
                            .onTapGesture {
                                selectedMethod = selectedMethod == method.methodName ? nil : method.methodName
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "creditcard.fill")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("결제 수단 데이터가 없습니다")
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text("선택한 기간에 거래 내역이 없습니다")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
    }
}

struct PaymentMethodLegendItem: View {
    let method: PaymentMethodRatioDTO
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(method.color)
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(method.methodName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    Text("\(String(format: "%.1f", method.ratio * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("·")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("\(method.count)건")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isSelected ? Color(.tertiarySystemFill) : Color.clear)
        )
    }
}

#Preview {
    StatisticsPreviewHelper.preview { dashboard in
        PaymentMethodRatioView(data: dashboard.payment.ratios)
            .padding()
    }
}
