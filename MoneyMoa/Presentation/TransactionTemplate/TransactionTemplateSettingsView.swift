//
//  TransactionTemplateSettingsView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/18/25.
//

import SwiftUI

struct TransactionTemplateSettingsView: View {
    @Environment(AppRouter.self) private var router

    @State private var viewModel: TransactionTemplateSettingsViewModel

    init(viewModel: TransactionTemplateSettingsViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection

                if viewModel.templates.isEmpty {
                    emptyStateView
                } else {
                    templatesList
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("반복 거래 템플릿")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.showingAddTemplate = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.blue)
                }
            }
        }
        .onAppear {
            viewModel.send(.onAppear)
        }
        .sheet(isPresented: $viewModel.showingAddTemplate) {
            // TODO: Add Template Creation View
            Text("Template 생성 화면")
        }
        .sheet(item: $viewModel.templateToEdit) { template in
            // TODO: Add Template Edit View
            Text("Template 수정 화면: \(template.id)")
        }
        .alert("템플릿 삭제", isPresented: $viewModel.showDeleteAlert) {
            Button("취소", role: .cancel) {
                viewModel.templateToDelete = nil
            }
            Button("삭제", role: .destructive) {
                if let template = viewModel.templateToDelete {
                    deleteTemplate(template)
                }
            }
        } message: {
            Text("이 템플릿을 삭제하시겠습니까?\n관련된 거래 내역은 유지됩니다.")
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "repeat.circle.fill")
                .font(.system(size: 48, weight: .medium))
                .foregroundStyle(LinearGradient(
                    colors: [.indigo, .blue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            Text("반복 거래를 관리하세요")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            Text("정기적으로 발생하는 수입과 지출을 템플릿으로 관리할 수 있습니다")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(.secondary.opacity(0.5))

            Text("아직 반복 거래가 없습니다")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("+ 버튼을 눌러 새로운 템플릿을 추가해보세요")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Templates List
    private var templatesList: some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.templates) { template in
                TransactionTemplateCard(
                    template: template,
                    onTap: {
                        viewModel.templateToEdit = template
                    },
                    onDelete: {
                        viewModel.templateToDelete = template
                        viewModel.showDeleteAlert = true
                    }
                )
            }
        }
    }

    // MARK: - Actions
    private func deleteTemplate(_ template: TransactionTemplateDTO) {
        withAnimation {
            viewModel.templateToDelete = nil
        }
    }
}

// MARK: - Transaction Template Card
struct TransactionTemplateCard: View {
    let template: TransactionTemplateDTO
    let onTap: () -> Void
    let onDelete: () -> Void

    private var formattedRecurrence: String {
        let calendar = template.timeContext.calendar

        switch template.recurrencePeriod {
        case .none:
            return "반복 없음"
        case .weekly:
            let createdAt = template.createdAt
            let weekday = calendar.component(.weekday, from: createdAt)
            let weekdaySymbols = calendar.weekdaySymbols
            return "매주 \(weekdaySymbols[weekday - 1])"

        case .monthly:
            let createdAt = template.createdAt
            let day = calendar.component(.day, from: createdAt)
            return "매월 \(day)일"

        case .yearly:
            let createdAt = template.createdAt
            let month = calendar.component(.month, from: createdAt)
            let day = calendar.component(.day, from: createdAt)
            return "매년 \(month)월 \(day)일"
        }
    }

    private var nextDueDateText: String? {
        guard let nextDate = template.nextDueDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.doesRelativeDateFormatting = true
        return formatter.string(from: nextDate)
    }

    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Header with place and delete button
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        // Place as main title
                        Text(template.place ?? "사용처 정보 없음")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(template.place != nil ? .primary : .secondary)

                        // Category and payment method as subtitle
                        HStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Image(systemName: template.subCategory.categoryIconName)
                                    .font(.caption)
                                    .foregroundColor(template.transactionType.color)

                                Text(template.subCategory.name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(template.paymentMethod.name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    // Delete button
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.red.opacity(0.8))
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                            )
                    }
                }
                .padding(16)

                Divider()
                    .padding(.horizontal, 16)

                // Content
                VStack(alignment: .leading, spacing: 12) {
                    // Amount
                    HStack {
                        Text(template.transactionType == .income ? "수입" : "지출")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(template.transactionType == .income ? .green : .red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill((template.transactionType == .income ? Color.green : Color.red).opacity(0.1))
                            )

                        Spacer()

                        Text("\(template.amount.formatted(.currency(code: "KRW")))")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }

                    // Memo
                    if let memo = template.memo, !memo.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "note.text")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(memo)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }

                    // Recurrence Info
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "repeat")
                                .font(.caption)
                                .foregroundColor(.blue)
                            Text(formattedRecurrence)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }

                        if let nextDateText = nextDueDateText {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                Text("다음 예정: \(nextDateText)")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(16)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        TransactionTemplateSettingsView(viewModel: TransactionTemplateSettingsViewModel())
    }
    .environment(AppRouter())
}
