//
//  TransactionListView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/30/25.
//

import SwiftUI

// MARK: - TransactionListView

struct TransactionListView: View {
    let listData: [(Date, [TransactionDTO])]
    let onTransactionTap: (TransactionDTO) -> Void
    
    var body: some View {
        Group {
            if listData.isEmpty {
                TransactionEmptyView()
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(listData, id: \.0) { (date, transactions) in
                        TransactionDateSectionView(
                            date: date,
                            transactions: transactions,
                            onTransactionTap: onTransactionTap
                        )
                    }
                }
            }
        }
    }
}

// MARK: - TransactionEmptyView

private struct TransactionEmptyView: View {
    var body: some View {
        VStack(spacing: 20) {
            // Empty Icon
            Image(systemName: "list.clipboard")
                .font(.system(size: 64))
                .foregroundColor(.gray.opacity(0.5))
            
            // Empty Message
            VStack(spacing: 8) {
                Text("거래 내역이 없습니다")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("이번 달에 등록된 거래가 없어요.\n우측 하단의 + 버튼을 눌러 거래를 추가해보세요!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 60)
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}

// MARK: - TransactionDateSectionView

private struct TransactionDateSectionView: View {
    let date: Date
    let transactions: [TransactionDTO]
    let onTransactionTap: (TransactionDTO) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            TransactionSectionHeaderView(date: date)
            
            // Transaction List
            LazyVStack(spacing: 8) {
                ForEach(transactions, id: \.id) { transaction in
                    TransactionRowView(
                        transaction: transaction,
                        onTap: { onTransactionTap(transaction) }
                    )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - TransactionSectionHeaderView

private struct TransactionSectionHeaderView: View {
    let date: Date
    
    var body: some View {
        HStack {
            Text(sectionHeaderText)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.bottom, 4)
    }
    
    private var sectionHeaderText: String {
        return date.transactionListSectionHeader
    }
}

// MARK: - TransactionRowView

private struct TransactionRowView: View {
    let transaction: TransactionDTO
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack(spacing: 6) {
                    CategoryIconView(subCategory: transaction.subCategory)
                    
                    Text(transaction.subCategory.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                
                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    // Amount (가장 강조)
                    Text(amountText)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(amountColor)
                    
                    // PaymentMethod + Place
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 4) {
                            PaymentMethodKindIconView(paymentMethod: transaction.paymentMethod)
                            
                            Text(transaction.paymentMethod.name)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        Text(displayPlace)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .cornerRadius(12)
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Computed Properties
    
    private var displayPlace: String {
        if let place = transaction.place, !place.isEmpty {
            return place
        }
        return "사용처 확인 불가"
    }
    
    private var amountText: String {
        return transaction.formattedAmount
    }
    
    private var amountColor: Color {
        return transaction.transactionType.color
    }
    
    // MARK: - Card Design Properties
    
    private var cardBackground: Color {
        Color(.systemBackground)
    }
    
    private var borderColor: Color {
        Color.gray.opacity(0.2)
    }
    
    private var borderWidth: CGFloat {
        0.5
    }
    
    private var shadowColor: Color {
        Color.black.opacity(0.05)
    }
    
    private var shadowRadius: CGFloat {
        3.0
    }
    
    private var shadowY: CGFloat {
        2.0
    }
}

// MARK: - PaymentMethodKindIconView

private struct PaymentMethodKindIconView: View {
    let paymentMethod: PaymentMethodDTO
    
    var body: some View {
        Image(systemName: paymentMethod.displayIconName)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(.secondary)
    }
}

// MARK: - CategoryIconView

private struct CategoryIconView: View {
    let subCategory: SubCategoryDTO
    
    var body: some View {
        Circle()
            .fill(iconBackgroundColor)
            .frame(width: 48, height: 48)
            .overlay(
                Image(systemName: iconName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
            )
    }
    
    private var iconName: String {
        return subCategory.categoryIconName
    }
    
    private var iconBackgroundColor: Color {
        return subCategory.transactionType.color.opacity(0.15)
    }
}

// MARK: - Preview

// #Preview {
//    let dummyData = createDummyTransactionData()
//    return TransactionListView(
//        listData: dummyData,
//        onTransactionTap: { transaction in
//            print("Tapped: \(transaction.subCategory.name)")
//        }
//    )
//    .padding()
// }

#Preview("Empty State") {
    TransactionListView(
        listData: [],
        onTransactionTap: { transaction in
            print("Tapped: \(transaction.subCategory.name)")
        }
    )
    .padding()
}
//
// private func createDummyTransactionData() -> [(Date, [TransactionDTO])] {
//    let today = Date()
//    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today
//    let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: today) ?? today
//    
//    // Mock Categories
//    let expenseCategory = CategoryDTO(
//        name: "생활비",
//        iconName: "house.fill",
//        transactionType: .variableExpense
//    )
//    let incomeCategory = CategoryDTO(
//        name: "수입",
//        iconName: "plus.circle.fill",
//        transactionType: .income
//    )
//    
//    // Today's transactions
//    let todayTransactions = [
//        TransactionDTO(
//            amount: 15000,
//            date: today,
//            place: "맥도날드 강남점",
//            memo: "점심식사",
//            transactionType: .variableExpense,
//            subCategory: SubCategoryDTO(
//                name: "식비",
//                transactionType: .variableExpense,
//                categoryId: expenseCategory.id,
//                categoryIconName: expenseCategory.iconName
//            ),
//            paymentMethod: PaymentMethodDTO(
//                name: "신용카드",
//                kind: .credit,
//                iconName: "creditcard.fill"
//            )
//        ),
//        TransactionDTO(
//            amount: 25000,
//            date: today,
//            place: nil,
//            memo: "교통비",
//            transactionType: .variableExpense,
//            subCategory: SubCategoryDTO(
//                name: "교통",
//                transactionType: .variableExpense,
//                categoryId: expenseCategory.id,
//                categoryIconName: expenseCategory.iconName
//            ),
//            paymentMethod: PaymentMethodDTO(
//                name: "교통카드",
//                kind: .credit
//            )
//        )
//    ]
//    
//    // Yesterday's transactions
//    let yesterdayTransactions = [
//        TransactionDTO(
//            amount: 50000,
//            date: yesterday,
//            place: "아버지",
//            memo: "용돈",
//            transactionType: .income,
//            subCategory: SubCategoryDTO(
//                name: "용돈",
//                transactionType: .income,
//                categoryId: incomeCategory.id,
//                categoryIconName: incomeCategory.iconName
//            ),
//            paymentMethod: PaymentMethodDTO(
//                name: "현금",
//                kind: .cash
//            )
//        )
//    ]
//    
//    // Three days ago transactions
//    let threeDaysAgoTransactions = [
//        TransactionDTO(
//            amount: 80000,
//            date: threeDaysAgo,
//            place: "올리브영 홍대점",
//            memo: "화장품",
//            transactionType: .variableExpense,
//            subCategory: SubCategoryDTO(
//                name: "미용",
//                transactionType: .variableExpense,
//                categoryId: expenseCategory.id,
//                categoryIconName: expenseCategory.iconName
//            ),
//            paymentMethod: PaymentMethodDTO(
//                name: "체크카드",
//                kind: .debit
//            )
//        )
//    ]
//    
//    return [
//        (today, todayTransactions),
//        (yesterday, yesterdayTransactions),
//        (threeDaysAgo, threeDaysAgoTransactions)
//    ]
// }
