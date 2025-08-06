//
//  FloatingActionButton.swift
//  MoneyMoa
//
//  Created by Claude on 1/25/25.
//

import SwiftUI

struct FloatingActionButton: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(Color.blue)
                        .shadow(
                            color: Color.black.opacity(0.2),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.1), value: false)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            HStack {
                Spacer()
                FloatingActionButton(onTap: {
                    print("FAB tapped")
                })
                .padding(.trailing, 16)
                .padding(.bottom, 16)
            }
        }
    }
}