//
//  CalendarView.swift
//  MoneyMoa
//
//  Created by Claude on 8/3/25.
//

import SwiftUI

// MARK: - CalendarView

struct CalendarView: View {
    let yearMonth: YearMonth
    let transactionsByDate: [Date: [TransactionDTO]]
    let onDateTap: (Date) -> Void
    
    private let calendar = FormatterManager.shared.koreaCalendar
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        VStack(spacing: 16) {
            // Calendar Header (요일)
            CalendarHeaderView()
            
            // Calendar Grid
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(calendarDates, id: \.self) { date in
                    CalendarDayView(
                        date: date,
                        transactions: transactionsByDate[calendar.startOfDay(for: date)] ?? [],
                        isCurrentMonth: calendar.isDate(date, equalTo: yearMonth.startOfMonth, toGranularity: .month),
                        isToday: calendar.isDateInToday(date),
                        onTap: { onDateTap(date) }
                    )
                }
            }
        }
        .padding(.vertical, 12)
    }
    
    private var calendarDates: [Date] {
        generateCalendarDates(for: yearMonth)
    }
    
    // MARK: - Helper Methods for generateCalendarDates
    
    private func generateCalendarDates(for yearMonth: YearMonth) -> [Date] {
        let startOfMonth = yearMonth.startOfMonth
        
        // 월의 첫 주 시작일 (일요일부터 시작)
        let startOfFirstWeek = calendar.dateInterval(of: .weekOfYear, for: startOfMonth)?.start ?? startOfMonth
        
        // 월의 마지막 주 마지막일
        let endOfMonth = yearMonth.endOfMonth
        let endOfLastWeek = calendar.dateInterval(of: .weekOfYear, for: endOfMonth)?.end ?? endOfMonth
        
        var dates: [Date] = []
        var currentDate = startOfFirstWeek
        
        while currentDate < endOfLastWeek {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return dates
    }
}

// MARK: - CalendarHeaderView

private struct CalendarHeaderView: View {
    private let weekdays = ["일", "월", "화", "수", "목", "금", "토"]
    
    var body: some View {
        HStack {
            ForEach(weekdays, id: \.self) { weekday in
                Text(weekday)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - CalendarDayView

private struct CalendarDayView: View {
    let date: Date
    let transactions: [TransactionDTO]
    let isCurrentMonth: Bool
    let isToday: Bool
    let onTap: () -> Void
    
    private let calendar = FormatterManager.shared.koreaCalendar
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                // 날짜 숫자
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 16, weight: isToday ? .bold : .medium))
                    .foregroundColor(dayNumberColor)
                
                // 거래 금액 표시
                if !transactions.isEmpty && isCurrentMonth {
                    VStack(spacing: 2) {
                        if let incomeAmount = totalIncomeAmount {
                            AmountCapsuleView(
                                amount: incomeAmount,
                                isIncome: true
                            )
                            .frame(minWidth: 32, maxWidth: 40, minHeight: 14, maxHeight: 14)
                        }
                        
                        if let expenseAmount = totalExpenseAmount {
                            AmountCapsuleView(
                                amount: expenseAmount,
                                isIncome: false
                            )
                            .frame(minWidth: 32, maxWidth: 40, minHeight: 14, maxHeight: 14)
                        }
                    }
                }
            }
            .frame(height: 60, alignment: .top)
            .frame(maxWidth: .infinity)
            .overlay(
                // Today 하이라이트
                isToday ? 
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue, lineWidth: 2)
                : nil
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isCurrentMonth)
    }
    
    // MARK: - Computed Properties
    
    private var dayNumberColor: Color {
        if !isCurrentMonth {
            return .gray.opacity(0.3)
        } else if isToday {
            return .blue
        } else {
            return .primary
        }
    }
    
    private var totalIncomeAmount: Decimal? {
        let income = transactions
            .filter { $0.transactionType == .income }
            .reduce(Decimal(0)) { $0 + $1.amount }
        return income > 0 ? income : nil
    }
    
    private var totalExpenseAmount: Decimal? {
        let expense = transactions
            .filter { $0.transactionType != .income }
            .reduce(Decimal(0)) { $0 + $1.amount }
        return expense > 0 ? expense : nil
    }
}

// MARK: - AmountCapsuleView

private struct AmountCapsuleView: View {
    let amount: Decimal
    let isIncome: Bool
    
    var body: some View {
        Text(amount.compactAmountText)
            .font(.system(size: 9, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .minimumScaleFactor(0.6)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
            .background(
                Capsule()
                    .fill(backgroundColor)
            )
    }
    
    private var backgroundColor: Color {
        isIncome ? .green : .red
    }
}

// MARK: - Preview

#Preview {
    let mockTransactions = createMockCalendarData()
    
    return CalendarView(
        yearMonth: .current,
        transactionsByDate: mockTransactions,
        onDateTap: { date in
            print("Tapped date: \(date)")
        }
    )
    .padding()
}

private func createMockCalendarData() -> [Date: [TransactionDTO]] {
    let calendar = Calendar.current
    let today = Date()
    
    // Mock data for various dates
    var transactions: [Date: [TransactionDTO]] = [:]
    
    // 오늘
    transactions[calendar.startOfDay(for: today)] = [
        createMockTransaction(amount: 15000, type: .variableExpense),
        createMockTransaction(amount: 50000, type: .income)
    ]
    
    // 어제
    if let yesterday = calendar.date(byAdding: .day, value: -1, to: today) {
        transactions[calendar.startOfDay(for: yesterday)] = [
            createMockTransaction(amount: 25000, type: .variableExpense)
        ]
    }
    
    // 3일 전
    if let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today) {
        transactions[calendar.startOfDay(for: threeDaysAgo)] = [
            createMockTransaction(amount: 100_000_000, type: .income), // 1억 (limit test)
            createMockTransaction(amount: 80000, type: .variableExpense)
        ]
    }
    
    return transactions
}

private func createMockTransaction(amount: Decimal, type: TransactionType) -> TransactionDTO {
    let category = CategoryDTO(
        name: type == .income ? "수입" : "지출",
        iconName: type == .income ? "plus.circle" : "minus.circle",
        transactionType: type
    )
    
    return TransactionDTO(
        amount: amount,
        date: Date(),
        place: "테스트",
        memo: "테스트",
        transactionType: type,
        subCategory: SubCategoryDTO(
            name: "테스트",
            transactionType: type,
            categoryId: category.id,
            categoryName: category.name,
            categoryIconName: category.iconName
        ),
        paymentMethod: PaymentMethodDTO(
            name: "테스트",
            kind: .cash
        )
    )
}
