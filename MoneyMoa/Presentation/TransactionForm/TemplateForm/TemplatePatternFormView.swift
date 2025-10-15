//
//  TemplatePatternFormView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/24/25.
//

import SwiftUI

struct TemplatePatternFormView: View {

    @Bindable var viewModel: TemplatePatternFormViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            recurrencePatternSection
            memoSection
        }
    }
    
    // MARK: - Recurrence Pattern Section

    @ViewBuilder
    private var recurrencePatternSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "repeat")
                    .font(.title2)
                    .foregroundColor(.green)
                Text("반복 패턴")
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            recurrencePeriodPicker

            if viewModel.recurrencePattern.period != .none {
                patternDescriptionSection
                patternDetailSection
                timeSelectionSection
            }
        }
    }

    @ViewBuilder
    private var recurrencePeriodPicker: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            ForEach(RecurrencePeriod.allCases, id: \.self) { period in
                periodSelectionButton(for: period)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    @ViewBuilder
    private func periodSelectionButton(for period: RecurrencePeriod) -> some View {
        let isSelected = viewModel.recurrencePattern.period == period

        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.send(.selectRecurrencePeriod(period))
            }
        } label: {
            Text(period.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .blue)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    isSelected ? Color.blue : Color.blue.opacity(0.1)
                )
                .cornerRadius(8)
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue, lineWidth: isSelected ? 0 : 1)
                }
        }
    }

    // MARK: - Pattern Description Section

    @ViewBuilder
    private var patternDescriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundColor(.green)

                Text("패턴 확인")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }

            HStack {
                Image(systemName: "repeat")
                    .font(.title2)
                    .foregroundColor(.green)

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.patternDescription)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }

                Spacer()
            }
        }
        .padding(16)
        .background(Color.green.opacity(0.05))
        .cornerRadius(12)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        }
    }

    // MARK: - Pattern Detail Section

    @ViewBuilder
    private var patternDetailSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .font(.title2)
                    .foregroundColor(.orange)
                Text("상세 설정")
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            switch viewModel.recurrencePattern.period {
            case .weekly:
                weeklyDetailSection
            case .monthly:
                monthlyDetailSection
            case .yearly:
                yearlyDetailSection
            case .none:
                EmptyView()
            }
        }
    }

    // MARK: - Weekly Detail Section

    @ViewBuilder
    private var weeklyDetailSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("요일 선택")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(1...7, id: \.self) { weekday in
                    weekdayButton(for: weekday)
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    @ViewBuilder
    private func weekdayButton(for weekday: Int) -> some View {
        let isSelected = viewModel.recurrencePattern.weekday == weekday
        let weekdayName = Calendar.current.veryShortWeekdaySymbols[weekday - 1]

        Button {
            viewModel.send(.selectWeekday(weekday))
        } label: {
            Text(weekdayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .orange)
                .frame(width: 32, height: 32)
                .background(
                    isSelected ? Color.orange : Color.orange.opacity(0.1)
                )
                .cornerRadius(16)
        }
    }

    // MARK: - Monthly Detail Section

    @ViewBuilder
    private var monthlyDetailSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("날짜 선택 (1-31일)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(1...31, id: \.self) { day in
                    monthlyDayButton(for: day)
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    @ViewBuilder
    private func monthlyDayButton(for day: Int) -> some View {
        let isSelected = viewModel.recurrencePattern.dayOfMonth == day

        Button {
            viewModel.send(.selectDayOfMonth(day))
        } label: {
            Text("\(day)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .orange)
                .frame(width: 32, height: 32)
                .background(
                    isSelected ? Color.orange : Color.orange.opacity(0.1)
                )
                .cornerRadius(16)
        }
    }

    // MARK: - Yearly Detail Section

    @ViewBuilder
    private var yearlyDetailSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Month Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("월 선택")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                    ForEach(1...12, id: \.self) { month in
                        yearlyMonthButton(for: month)
                    }
                }
            }

            Divider()

            // Day Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("일 선택 (1-31일)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                    ForEach(1...31, id: \.self) { day in
                        yearlyDayButton(for: day)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    @ViewBuilder
    private func yearlyMonthButton(for month: Int) -> some View {
        let isSelected = viewModel.recurrencePattern.yearlyMonth == month
        let monthName = Calendar.current.shortMonthSymbols[month - 1]

        Button {
            viewModel.send(.selectYearlyMonth(month))
        } label: {
            Text(monthName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    isSelected ? Color.orange : Color.orange.opacity(0.1)
                )
                .cornerRadius(8)
        }
    }

    @ViewBuilder
    private func yearlyDayButton(for day: Int) -> some View {
        let isSelected = viewModel.recurrencePattern.yearlyDay == day

        Button {
            viewModel.send(.selectYearlyDay(day))
        } label: {
            Text("\(day)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .orange)
                .frame(width: 32, height: 32)
                .background(
                    isSelected ? Color.orange : Color.orange.opacity(0.1)
                )
                .cornerRadius(16)
        }
    }

    // MARK: - Time Selection Section

    @ViewBuilder
    private var timeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock")
                    .font(.title2)
                    .foregroundColor(.purple)
                Text("실행 시간")
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            HStack(spacing: 20) {
                // Hour Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("시")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    Picker("시간", selection: Binding(
                        get: { viewModel.recurrencePattern.hour },
                        set: { viewModel.send(.setHour($0)) }
                    )) {
                        ForEach(0...23, id: \.self) { hour in
                            Text("\(hour)")
                                .tag(hour)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80, height: 100)
                    .clipped()
                }

                // Minute Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("분")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    Picker("분", selection: Binding(
                        get: { viewModel.recurrencePattern.minute },
                        set: { viewModel.send(.setMinute($0)) }
                    )) {
                        ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { minute in
                            Text(String(format: "%02d", minute))
                                .tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80, height: 100)
                    .clipped()
                }

                Spacer()

                // Current Time Display
                VStack(alignment: .center, spacing: 4) {
                    Text("설정된 시간")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(String(format: "%02d:%02d",
                               viewModel.recurrencePattern.hour,
                               viewModel.recurrencePattern.minute))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Memo Section

    @ViewBuilder
    private var memoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("메모")
                .font(.headline)
                .fontWeight(.semibold)

            TextField(
                "",
                text: $viewModel.memo,
                axis: .vertical
            )
            .textFieldStyle(.plain)
            .font(.subheadline)
            .lineLimit(3...6)
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay {
                VStack {
                    if viewModel.memo.isEmpty {
                        HStack {
                            VStack {
                                HStack {
                                    Image(systemName: "note.text")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("템플릿에 대한 메모를 입력하세요(선택 사항)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                Spacer()
                            }
                            .padding(16)
                            Spacer()
                        }
                    }
                    Spacer()
                }
            }
        }
    }

}

#Preview {
    TemplatePatternFormView(
        viewModel: TemplatePatternFormViewModel()
    )
    .padding(.horizontal, 16)
}

#Preview("Weekly Pattern") {
    TemplatePatternFormView(
        viewModel: TemplatePatternFormViewModel(
            memo: "주간 식료품 구매",
            recurrencePattern: RecurrencePattern.weekly(on: 6) // 금요일
        )
    )
    .padding(.horizontal, 16)
}

#Preview("Monthly Pattern") {
    TemplatePatternFormView(
        viewModel: TemplatePatternFormViewModel(
            memo: "월 보험료",
            recurrencePattern: RecurrencePattern.monthly(on: 15)
        )
    )
    .padding(.horizontal, 16)
}
