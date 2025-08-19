//
//  CategoryFormView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/18/25.
//

import SwiftUI

struct CategoryFormView: View {

    @Bindable var viewModel: CategoryFormViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                transactionTypeSection
                categorySection
                subCategorySection

                if viewModel.category == nil {
                    iconSelectionGrid
                }
                Spacer()
            }
            .navigationTitle("새 카테고리")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        viewModel.send(.createCategory)
                    }
                    .disabled(!viewModel.isValid)
                }
            }
        }
    }

    @ViewBuilder
    private var transactionTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("거래정보 유형")
                .font(.footnote)

            Text("거래유형: \(viewModel.transactionType)")
                .font(.footnote)
                .padding(.vertical, 8)
                .padding(.leading, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                }
        }
        .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("카테고리")
                .font(.footnote)
                .foregroundStyle(.secondary)

            if let category = viewModel.category {
                HStack(spacing: 8) {
                    Image(systemName: category.iconName)
                    Text(category.name)
                }
                .font(.subheadline)
                .padding(.vertical, 8)
                .padding(.leading, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                }

            } else {
                TextField("카티고리 이름", text: $viewModel.categoryName)
                    .font(.subheadline)
                    .padding(.vertical, 8)
                    .padding(.leading, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    }
            }
        }
    }

    @ViewBuilder
    private var subCategorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("서브카테고리")
                .font(.footnote)
                .foregroundStyle(.secondary)

            TextField("서브카티고리 이름", text: $viewModel.subCategoryName)
                .font(.subheadline)
                .padding(.vertical, 8)
                .padding(.leading, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                }
        }
    }

    @ViewBuilder
    private var iconSelectionGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("아이콘 선택")
                .font(.footnote)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                let selectedCategoryIconName = viewModel.selectedCategoryIconName
                ForEach(viewModel.availableCategoryIconNames, id: \.self) { icon in
                    Button {
                        viewModel.send(.setSelectedCategoryIconName(icon))
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: icon)
                                .font(.title2)
                                .foregroundColor(selectedCategoryIconName == icon ? Color.white : .blue)
                                .frame(width: 44, height: 44)
                                .background(selectedCategoryIconName == icon ? Color.blue : Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
            }
        }
    }
}

#Preview {
    CategoryFormView(
        viewModel: .init(
            createCategoryUseCase: MockCreateCategoryUseCase(),
            createSubCategoryUseCase: MockCreateSubCategoryUseCase(),
            transactionType: .fixedExpense,
            category: nil
        )
    )
}

#Preview {
    CategoryFormView(
        viewModel: .init(
            createCategoryUseCase: MockCreateCategoryUseCase(),
            createSubCategoryUseCase: MockCreateSubCategoryUseCase(),
            transactionType: .fixedExpense,
            category: CategoryDTO.mockExpense
        )
    )
}
