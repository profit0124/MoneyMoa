//
//  TransactionTypeSelectionView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/23/25.
//

import SwiftUI

struct TransactionTypeSelectionView: View {

    let title: String = "거래 유형"
    @Binding var selectedTransactionType: TransactionType

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)

            HStack(spacing: 8) {
                ForEach(TransactionType.allCases, id: \.self) { type in
                    transactionTypeButton(type)
                }
            }
        }
    }

    @ViewBuilder
    private func transactionTypeButton(_ type: TransactionType) -> some View {
        Button(action: {
            if selectedTransactionType != type {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTransactionType = type
                }
            }
        }, label: {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundStyle(type.color)
                    .frame(width: 48, height: 48)
                    .background {
                        Circle()
                            .fill(type.color.opacity(0.1))

                    }

                Text(type.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        })
        .padding(8)
        .buttonStyle(PlainButtonStyle())
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(
                    color: selectedTransactionType == type ?
                        type.color.opacity(0.3) : Color.black.opacity(0.05),
                    radius: selectedTransactionType == type ? 8 : 2,
                    x: 0,
                    y: selectedTransactionType == type ? 4 : 1
                )

        }
        .overlay {
            if selectedTransactionType == type {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(type.color, lineWidth: 2)
            }
        }
        .scaleEffect(selectedTransactionType == type ? 1.05 : 1.0)
    }
}

#Preview {
    TransactionTypeSelectionView(selectedTransactionType: .constant(.fixedExpense))
}
