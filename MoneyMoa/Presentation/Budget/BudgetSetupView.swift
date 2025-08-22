//
//  BudgetSetupView.swift
//  MoneyMoa
//
//  Created by Claude on 8/21/25.
//

import SwiftUI

struct BudgetSetupView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel = BudgetSetupViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    LoadingView(message: "데이터를 불러오는 중...")
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // 총 예산 설정
                            TotalBudgetSection(
                                totalBudgetAmount: Binding(
                                    get: { viewModel.totalAmount ?? 0 },
                                    set: { viewModel.totalAmount = $0 > 0 ? $0 : nil }
                                )
                            )
                            
                            // 카테고리별 예산 분할
                            CategoryBudgetSection(
                                viewModel: viewModel
                            )
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                    }
                }
            }
            .navigationTitle("예산 설정")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("저장") {
                        viewModel.send(.createBudgetTemplate)
                        // TODO: 저장 성공 시 router.pop() 호출
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
        }
        .onAppear {
            viewModel.send(.onAppear)
        }
    }
}

// MARK: - TotalBudgetSection

private struct TotalBudgetSection: View {
    @Binding var totalBudgetAmount: Decimal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("월 예산 총액")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                HStack {
                    TextField("예산 금액을 입력하세요", value: $totalBudgetAmount, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Text("원")
                        .foregroundColor(.secondary)
                }
                
                if totalBudgetAmount > 0 {
                    Text("총 예산: \(totalBudgetAmount.formattedAmountWithWon)")
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
}

// MARK: - CategoryBudgetSection

private struct CategoryBudgetSection: View {
    @Bindable var viewModel: BudgetSetupViewModel
    @State private var showingCategorySelection = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 헤더
            HStack {
                Text("카테고리별 예산 분할")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // + 버튼
                Button {
                    showingCategorySelection = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 20))
                }
                .disabled(viewModel.availableCategories.isEmpty)
            }
            
            // 카테고리 목록 또는 Empty View
            if viewModel.categoryBudgetTemplates.isEmpty {
                CategoryBudgetEmptyView(viewModel: viewModel)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.categoryBudgetTemplates, id: \.id) { template in
                        CategoryBudgetRow(
                            template: template,
                            onAmountChanged: { newAmount in
                                viewModel.send(.updateCategoryBudgetAmount(template, newAmount))
                            },
                            onDelete: {
                                viewModel.send(.deleteCategoryBudgetTemplate(template))
                            }
                        )
                    }
                }
                
                // 예산 분할 요약
                BudgetSummaryCard(
                    totalAmount: viewModel.totalAmount ?? 0,
                    allocatedAmount: viewModel.totalCategoryBudgetTemplate,
                    remainingAmount: viewModel.remainingAmount
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .sheet(isPresented: $showingCategorySelection) {
            CategorySelectionView(
                availableCategories: viewModel.availableCategories,
                onCategoriesSelected: { selectedCategories in
                    viewModel.send(.addCategoryBudgetTemplate(selectedCategories))
                }
            )
        }
    }
}

// MARK: - CategoryBudgetEmptyView

private struct CategoryBudgetEmptyView: View {
    @Bindable var viewModel: BudgetSetupViewModel
    @State private var showingCategorySelection = false
    
    var body: some View {
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
                showingCategorySelection = true
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
            .sheet(isPresented: $showingCategorySelection) {
                CategorySelectionView(
                    availableCategories: viewModel.availableCategories,
                    onCategoriesSelected: { selectedCategories in
                        viewModel.send(.addCategoryBudgetTemplate(selectedCategories))
                    }
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - CategoryBudgetRow

private struct CategoryBudgetRow: View {
    let template: CategoryBudgetTemplateDTO
    let onAmountChanged: (Decimal) -> Void
    let onDelete: () -> Void
    
    @State private var amountText: String = ""
    
    var body: some View {
        HStack(spacing: 12) {
            // 카테고리 이름
            Text(template.categoryName)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            // 예산 입력 필드
            HStack(spacing: 4) {
                TextField("0", text: $amountText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 100)
                    .multilineTextAlignment(.trailing)
                    .onChange(of: amountText) { _, newValue in
                        if let amount = Decimal(string: newValue) {
                            onAmountChanged(amount)
                        }
                    }
                
                Text("원")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // 삭제 버튼
            Button(action: onDelete) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 20))
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            amountText = template.amount > 0 ? "\(template.amount)" : ""
        }
        .onChange(of: template.amount) { _, newAmount in
            amountText = newAmount > 0 ? "\(newAmount)" : ""
        }
    }
}

// MARK: - BudgetSummaryCard

private struct BudgetSummaryCard: View {
    let totalAmount: Decimal
    let allocatedAmount: Decimal
    let remainingAmount: Decimal
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("예산 분할 현황")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                BudgetSummaryRow(
                    title: "총 예산",
                    amount: totalAmount,
                    color: .primary
                )
                
                BudgetSummaryRow(
                    title: "분할된 예산",
                    amount: allocatedAmount,
                    color: .blue
                )
                
                Divider()
                
                BudgetSummaryRow(
                    title: "남은 예산",
                    amount: remainingAmount,
                    color: remainingAmount >= 0 ? .green : .red
                )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - BudgetSummaryRow

private struct BudgetSummaryRow: View {
    let title: String
    let amount: Decimal
    let color: Color
    
    var body: some View {
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
        BudgetSetupView()
            .environment(AppRouter())
    }
}
