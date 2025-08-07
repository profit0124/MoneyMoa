//
//  YearMonthHeaderView.swift
//  MoneyMoa
//
//  Created by Claude on 8/3/25.
//

import SwiftUI

// MARK: - YearMonthHeaderView

struct YearMonthHeaderView: View {
    let yearMonth: YearMonth
    let onYearMonthChange: (MainViewModel.HandleYearMonth) -> Void
    @State private var isDatePickerPresented = false
    
    var body: some View {
        HStack {
            // Year/Month Display (Left aligned, clickable)
            Button(action: {
                isDatePickerPresented = true
            }, label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: "%d년", yearMonth.year))
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("\(yearMonth.month)월")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            })
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Navigation Buttons
            HStack(spacing: 16) {
                // Previous Month Button
                Button(action: {
                    onYearMonthChange(.moveToPreviousMonth)
                }, label: {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.blue)
                })
                
                // Next Month Button
                Button(action: {
                    onYearMonthChange(.moveToNextMonth)
                }, label: {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(.blue)
                })
            }
        }
        .padding(.horizontal, 8)
        .sheet(isPresented: $isDatePickerPresented) {
            YearMonthPickerView(
                selectedYearMonth: yearMonth,
                onSelection: { newYearMonth in
                    onYearMonthChange(.setMonth(newYearMonth))
                    isDatePickerPresented = false
                }
            )
            .presentationDetents([.medium])
        }
    }
}

// MARK: - YearMonthPickerView

private struct YearMonthPickerView: View {
    let selectedYearMonth: YearMonth
    let onSelection: (YearMonth) -> Void
    
    @State private var selectedYear: Int
    @State private var selectedMonth: Int
    
    private let currentYear = Calendar.current.component(.year, from: Date())
    private let years: [Int]
    private let months = Array(1...12)
    
    init(selectedYearMonth: YearMonth, onSelection: @escaping (YearMonth) -> Void) {
        self.selectedYearMonth = selectedYearMonth
        self.onSelection = onSelection
        
        // 현재 연도 기준으로 ±10년 범위
        let currentYear = Calendar.current.component(.year, from: Date())
        self.years = Array((currentYear - 10)...(currentYear))
        
        self._selectedYear = State(initialValue: selectedYearMonth.year)
        self._selectedMonth = State(initialValue: selectedYearMonth.month)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                HStack(spacing: 0) {
                    // 연도 선택
                    Picker("년도", selection: $selectedYear) {
                        ForEach(years, id: \.self) { year in
                            Text(String(format: "%d년", year))
                                .tag(year)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    
                    // 월 선택
                    Picker("월", selection: $selectedMonth) {
                        ForEach(months, id: \.self) { month in
                            Text(String(format: "%d월", month))
                                .tag(month)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("년월 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        onSelection(selectedYearMonth) // Keep original
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("확인") {
                        let newYearMonth = YearMonth(year: selectedYear, month: selectedMonth)
                        onSelection(newYearMonth)
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    YearMonthHeaderView(
        yearMonth: .current,
        onYearMonthChange: { action in
            print("Year/Month action: \(action)")
        }
    )
    .padding()
}
