//
//  DateAdditionalFormView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/19/25.
//

import SwiftUI

struct DateAdditionalFormView: View {
    
    @Bindable var viewModel: DateAdditionalFormViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            dateSection
            memoSection

            if !viewModel.isReadOnlyTemplate {
                templateSection
            }
        }
    }
    
    // MARK: - Date Section
    
    @ViewBuilder
    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("날짜 및 시간")
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            datePickerSection
        }
    }
    
    @ViewBuilder
    private var datePickerSection: some View {
        DatePicker(
            "거래 날짜",
            selection: $viewModel.selectedDate,
            displayedComponents: [.date, .hourAndMinute]
        )
        .datePickerStyle(.compact)
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
                                    Text("메모를 입력하세요(선택 사항)")
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
    
    // MARK: - Template Section

    @ViewBuilder
    private var templateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("템플릿 등록")
                .font(.headline)
                .fontWeight(.semibold)

            templateToggleSection
        }
    }

    @ViewBuilder
    private var templateToggleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("템플릿으로 저장")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("반복되는 거래를 템플릿으로 저장하면 자동으로 추가됩니다")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { viewModel.createAsTemplate },
                    set: { _ in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.send(.toggleTemplate)
                        }
                    }
                ))
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .scaleEffect(1.1)
                .padding(.trailing, 8)
            }

            if viewModel.createAsTemplate {
                recurrencePeriodPicker
            }
        }
        .padding(16)
        .background(
            viewModel.createAsTemplate ?
            Color.blue.opacity(0.05) : Color(.systemGray6)
        )
        .cornerRadius(12)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    viewModel.createAsTemplate ? Color.blue.opacity(0.3) : Color.clear,
                    lineWidth: 1
                )
        }
    }

    @ViewBuilder
    private var recurrencePeriodPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("반복 주기")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(RecurrencePeriod.allCases, id: \.self) { period in
                    periodSelectionButton(for: period)
                }
            }
        }
        .padding(16)
        .background(Color.blue.opacity(0.03))
        .cornerRadius(12)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        }
    }

    @ViewBuilder
    private func periodSelectionButton(for period: RecurrencePeriod) -> some View {
        let isSelected = viewModel.selectedRecurrencePeriod == period

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
}

#Preview {
    DateAdditionalFormView(
        viewModel: DateAdditionalFormViewModel()
    )
    .padding(.horizontal, 16)
}

#Preview("With Template") {
    DateAdditionalFormView(
        viewModel: DateAdditionalFormViewModel(
            selectedDate: Date(),
            memo: "점심 식사",
            selectedRecurrencePeriod: .monthly,
            isReadOnlyTemplate: true
        )
    )
    .padding(.horizontal, 16)
}
