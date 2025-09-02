//
//  StatisticsSectionView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/2/25.
//

import SwiftUI

struct StatisticsSectionView<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(iconColor)
                
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Section Content
            content
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
        }
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        }
    }
}

#Preview {
    StatisticsSectionView(title: "전체 개요", icon: "chart.bar.fill", iconColor: .blue) {
        VStack {
            Text("Sample content")
            Rectangle()
                .fill(.blue.opacity(0.3))
                .frame(height: 200)
        }
    }
    .padding()
}
