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
            favoriteSection
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
    
    // MARK: - Favorite Section
    
    @ViewBuilder
    private var favoriteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("즐겨찾기")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("즐겨찾기 등록")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("자주 하는 거래로 등록하면 다음번에 빠르게 입력할 수 있어요")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.send(.toggleFavorite)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.isFavorite ? "star.fill" : "star")
                            .font(.title2)
                            .foregroundColor(viewModel.isFavorite ? .orange : .gray)
                        
                        Text(viewModel.isFavorite ? "등록됨" : "등록")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(viewModel.isFavorite ? .orange : .gray)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        viewModel.isFavorite ? 
                        Color.orange.opacity(0.1) : Color(.systemGray6)
                    )
                    .cornerRadius(20)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                viewModel.isFavorite ? Color.orange : Color.clear,
                                lineWidth: 1.5
                            )
                    }
                }
                .scaleEffect(viewModel.isFavorite ? 1.05 : 1.0)
            }
            .padding(16)
            .background(
                viewModel.isFavorite ?
                Color.orange.opacity(0.05) : Color(.systemGray6)
            )
            .cornerRadius(12)
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        viewModel.isFavorite ? Color.orange.opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
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

#Preview("With Data") {
    DateAdditionalFormView(
        viewModel: DateAdditionalFormViewModel(
            selectedDate: Date(),
            memo: "점심 식사",
            isFavorite: true
        )
    )
    .padding(.horizontal, 16)
}
