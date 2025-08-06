//
//  CustomNavigationBarView.swift
//  MoneyMoa
//
//  Created by Claude on 1/25/25.
//

import SwiftUI

struct CustomNavigationBarView: View {
    let onChartTap: () -> Void
    let onSettingsTap: () -> Void
    
    var body: some View {
        HStack {
            // App Name
            Text("MoneyMoa")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Spacer()
            
            // Toolbar Buttons
            HStack(spacing: 8) {
                // Chart Button
                Button(action: onChartTap) {
                    Image(systemName: "chart.bar.fill")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Settings Button
                Button(action: onSettingsTap) {
                    Image(systemName: "gearshape.fill")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
}

// MARK: - Preview

#Preview {
    CustomNavigationBarView(
        onChartTap: {
            print("Chart tapped")
        },
        onSettingsTap: {
            print("Settings tapped")
        }
    )
    .padding()
}
