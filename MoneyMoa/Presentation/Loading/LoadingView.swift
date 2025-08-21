//
//  LoadingView.swift
//  MoneyMoa
//
//  Created by Claude on 8/21/25.
//

import SwiftUI

// MARK: - LoadingView

struct LoadingView: View {
    let message: String
    @State private var showSkipButton = false
    let skipAction: (() -> Void)?
    
    init(message: String, skipAction: (() -> Void)? = nil) {
        self.message = message
        self.skipAction = skipAction
    }
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if showSkipButton, let skipAction = skipAction {
                Button("건너뛰기") {
                    skipAction()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear {
            if skipAction != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showSkipButton = true
                }
            }
        }
    }
}

#Preview {
    LoadingView(message: "추천 카테고리를 설정하고 있습니다...")
}
