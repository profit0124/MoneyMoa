//
//  CategoryRatioView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/2/25.
//

import SwiftUI
import Charts

struct CategoryRatioView: View {
    let data: [CategoryRatioDTO]
    @State private var selectedCategory: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            Text("카테고리 비율")
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
            
            if data.isEmpty {
                emptyStateView
            } else {
                HStack {
                    // Donut Chart
                    Chart(data, id: \.categoryName) { category in
                        SectorMark(
                            angle: .value("비율", category.ratio),
                            innerRadius: .ratio(0.6),
                            outerRadius: .ratio(1),
                            angularInset: 1.5
                        )
                        .foregroundStyle(category.color.gradient)
                        .opacity(selectedCategory == nil || selectedCategory == category.categoryName ? 1.0 : 0.5)
                    }
                    .frame(maxWidth: .infinity)
                    .chartBackground { chartProxy in
                        if let plotFrame = chartProxy.plotFrame {
                            GeometryReader { geometry in
                                let frame = geometry[plotFrame]
                                VStack(spacing: 2) {
                                    Text("총 지출")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(FormatterManager.shared.formatCurrency(
                                        data.reduce(0) { $0 + $1.amount }
                                    ))
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
                        ForEach(data.prefix(5), id: \.categoryName) { category in
                            CategoryLegendItem(
                                category: category,
                                isSelected: selectedCategory == category.categoryName
                            )
                            .onTapGesture {
                                selectedCategory = selectedCategory == category.categoryName ? nil : category.categoryName
                            }
                        }
                        
                        if data.count > 5 {
                            Text("기타 \(data.count - 5)개")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                
                // Top 3 Categories with Change
                topCategoriesSection
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.pie.fill")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("카테고리 데이터가 없습니다")
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
    
    private var topCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("상위 카테고리")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
            
            VStack(spacing: 8) {
                ForEach(Array(data.prefix(3).enumerated()), id: \.element.categoryName) { index, category in
                    CategoryTopCard(category: category, rank: index + 1)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

struct CategoryLegendItem: View {
    let category: CategoryRatioDTO
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(category.color)
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(category.categoryName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("\(String(format: "%.1f", category.ratio * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
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

struct CategoryTopCard: View {
    let category: CategoryRatioDTO
    let rank: Int
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank Badge
            Text("\(rank)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(category.color))
            
            // Category Info
            VStack(alignment: .leading, spacing: 2) {
                Text(category.categoryName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(FormatterManager.shared.formatCurrency(category.amount))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Change Badge
            HStack(spacing: 2) {
                Image(systemName: category.previousMonthChange >= 0 ? "arrow.up" : "arrow.down")
                    .font(.system(size: 8))
                Text("\(String(format: "%.1f", abs(category.previousMonthChange)))%")
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundColor(category.previousMonthChange >= 0 ? .red : .green)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background {
                RoundedRectangle(cornerRadius: 4)
                    .fill((category.previousMonthChange >= 0 ? Color.red : Color.green).opacity(0.1))
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
        CategoryRatioView(data: dashboard.category.ratios)
            .padding()
    }
}

#Preview("Empty") {
    CategoryRatioView(data: [])
            .padding()
}
