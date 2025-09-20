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
            Text("Template 생성 화면")
        }
        .sheet(item: $viewModel.templateToEdit) { template in
            Text("Template 수정 화면: \(template.id)")
        }
        .alert("템플릿 삭제", isPresented: $viewModel.showDeleteAlert) {
            Button("취소", role: .cancel) {
                viewModel.send(.cancelDelete)
            }
            Button("삭제", role: .destructive) {
                deleteTemplate()
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
                transactionTemplateCard(template)
            }
        }
    }

    @ViewBuilder
    private func transactionTemplateCard(_ template: TransactionTemplateDTO) -> some View {
        Button {
            print("on tap")
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                // Header with place and delete button
                cardHeaderSection(template)

                Divider()

                // Content
                cardContentSection(template)

            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private func cardHeaderSection(_ template: TransactionTemplateDTO) -> some View {
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
                viewModel.send(.deleteTemplate(template))
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
    }

    @ViewBuilder
    private func cardContentSection(_ template: TransactionTemplateDTO) -> some View {
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
                    Text(memo)
                        .font(.subheadline)
                        .lineLimit(1)
                }.foregroundColor(.secondary)
            }

            // Recurrence Info
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "repeat")
                        .font(.caption)
                    Text(template.formattedRecurrence)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.blue)

                if let nextDateText = template.nextDueDateText {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.caption)

                        Text("다음 예정: \(nextDateText)")
                            .font(.caption)
                    }
                    .foregroundColor(.orange)
                }
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Actions
    private func deleteTemplate() {
        withAnimation {
            viewModel.send(.confirmDelete)
        }
    }
}

// MARK: - Preview
#Preview {
    CoordinatorHost(container: MockDIContainer(configuration: .normal), start: .settingTransactionTemplate)
}
