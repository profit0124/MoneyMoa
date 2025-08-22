//
//  BudgetSetupView.swift
//  MoneyMoa
//
//  Created by Claude on 8/21/25.
//

import SwiftUI

struct BudgetSetupView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: BudgetSetupViewModel
    
    init(viewModel: BudgetSetupViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        ZStack {
            if viewModel.isLoading {
                LoadingView(message: "데이터를 불러오는 중...")
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // 총 예산 설정
                        totalBudgetSection

                        // 카테고리별 예산 분할
                        categoryBudgetSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
            }
        }
        .navigationTitle("\(viewModel.yearMonth.year)년 \(viewModel.yearMonth.month)월 예산 설정")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                let buttonTitle = viewModel.budget == nil ? "저장" : "수정"
                Button(buttonTitle) {
                    viewModel.send(.doneButtonTapped {
                        router.pop()
                    })
                }
                .disabled(!viewModel.isValid)
                .fontWeight(.semibold)
            }
        }
        .alert("오류", isPresented: $viewModel.showError) {
            Button("확인") { }
        } message: {
            Text(viewModel.errorMessage ?? "알 수 없는 오류가 발생했습니다.")
        }
        .confirmationDialog("예산 수정", isPresented: $viewModel.showUpdateConfirmation, titleVisibility: .visible) {
            Button("\(viewModel.yearMonth.month)월만 수정") {
                viewModel.send(.updateBudget(.withoutTemplate) {
                    router.pop()
                })
            }
            
            Button("\(viewModel.yearMonth.month)월 이후 모두 적용") {
                viewModel.send(.updateBudget(.withTemplate) {
                    router.pop()
                })
            }
            
            Button("취소", role: .cancel) { }
        } message: {
            Text("\(viewModel.yearMonth.year)년 \(viewModel.yearMonth.month)월 예산이 이미 설정되어 있습니다.\n어떻게 수정하시겠습니까?")
        }
        .onAppear {
            viewModel.send(.onAppear)
        }
    }

    // MARK: - TotalBudgetSection

    private var totalBudgetSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("월 예산 총액")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                HStack {
                    DecimalTextField("예산 금액을 입력하세요", decimal: $viewModel.totalAmount)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Text("원")
                        .foregroundColor(.secondary)
                }

                if let amount = viewModel.totalAmount, amount > 0 {
                    Text("총 예산: \(amount.formattedAmountWithWon)")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }

    // MARK: - CategoryBudgetSection

    var categoryBudgetSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 헤더
            HStack {
                Text("카테고리별 예산 분할")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                // + 버튼
                Button {
                    viewModel.showingCategorySelection = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 20))
                }
                .disabled(viewModel.availableCategories.isEmpty)
            }

            // 카테고리 목록 또는 Empty View
            if viewModel.categoryBudgets.isEmpty {
                categoryBudgetEmptyView
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.categoryBudgets, id: \.id) { template in
                        categoryBudgetRow(template)
                    }
                }

                // 예산 분할 요약
                budgetSummaryCard
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .sheet(isPresented: $viewModel.showingCategorySelection) {
            CategorySelectionView(
                availableCategories: viewModel.availableCategories,
                onCategoriesSelected: { selectedCategories in
                    viewModel.send(.addCategoryBudgets(selectedCategories))
                }
            )
        }
    }

    // MARK: - CategoryBudgetEmptyView

    private var categoryBudgetEmptyView: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Image(systemName: "chart.pie")
                    .font(.system(size: 40))
                    .foregroundColor(.gray.opacity(0.6))

                Text("부분 예산 설정으로\n꼼꼼하게 관리해보세요")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.vertical, 20)

            Button {
                viewModel.showingCategorySelection = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.white)
                    Text("카테고리 추가하기")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue)
                )
            }
            .disabled(viewModel.availableCategories.isEmpty)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }

    // MARK: - CategoryBudgetRow

    private func categoryBudgetRow(_ categoryBudget: CategoryBudgetDTO) -> some View {
        HStack(spacing: 12) {
            // 카테고리 이름
            Text(categoryBudget.categoryName)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()

            // 예산 입력 필드
            HStack(spacing: 4) {
                DecimalTextField("금액을 입력하세요", decimal: Binding(get: {
                    categoryBudget.amount
                }, set: {
                    viewModel.send(.updateCategoryBudgetAmount(categoryBudget, $0 ?? 0))
                }))
                .keyboardType(.numberPad)
                .font(.subheadline)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 100)
                .multilineTextAlignment(.trailing)

                Text("원")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // 삭제 버튼
            Button(action: {
                viewModel.send(.removeCategoryBudgetDTO(categoryBudget))
            }, label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 20))
            })
        }
        .padding(.vertical, 8)
    }

    // MARK: - BudgetSummaryCard

    private var budgetSummaryCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("예산 분할 현황")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                Spacer()
            }

            VStack(spacing: 8) {
                budgetSummaryRow(
                    title: "총 예산",
                    amount: viewModel.totalAmount ?? 0,
                    color: .primary
                )

                budgetSummaryRow(
                    title: "분할된 예산",
                    amount: viewModel.totalCategoryBudgetTemplate,
                    color: .blue
                )

                Divider()

                budgetSummaryRow(
                    title: "남은 예산",
                    amount: viewModel.remainingAmount,
                    color: viewModel.remainingAmount >= 0 ? .green : .red
                )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }

    // MARK: - BudgetSummaryRow

    private func budgetSummaryRow(title: String, amount: Decimal, color: Color) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Text(amount.formattedAmountWithWon)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

// MARK: - CategorySelectionView

private struct CategorySelectionView: View {
    let availableCategories: [CategoryDTO]
    let onCategoriesSelected: ([CategoryDTO]) -> Void
    
    @State private var selectedCategories: Set<UUID> = []
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(availableCategories, id: \.id) { category in
                HStack {
                    Text(category.name)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    if selectedCategories.contains(category.id) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(.gray)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if selectedCategories.contains(category.id) {
                        selectedCategories.remove(category.id)
                    } else {
                        selectedCategories.insert(category.id)
                    }
                }
            }
            .navigationTitle("카테고리 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("추가") {
                        let selected = availableCategories.filter { selectedCategories.contains($0.id) }
                        onCategoriesSelected(selected)
                        dismiss()
                    }
                    .disabled(selectedCategories.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BudgetSetupView(viewModel: MockDIContainer().makeBudgetSetupViewModel(yearMonth: YearMonth.current))
            .environment(AppRouter())
    }
}
