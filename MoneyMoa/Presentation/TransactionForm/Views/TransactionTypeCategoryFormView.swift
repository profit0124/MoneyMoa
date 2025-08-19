//
//  TransactionTypeCategoryFormView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/18/25.
//

import SwiftUI

struct TransactionTypeCategoryFormView: View {

    @Bindable var viewModel: TransactionTypeCategoryFormViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            transactionTypeSection
            categorySelectionSection
        }
        .onAppear {
            viewModel.send(.onAppear)
        }
        .sheet(
            item: $viewModel.categoryFormViewModel,
            onDismiss: {
                viewModel.send(.dismissCategoryForm)
            },
            content: {
                CategoryFormView(viewModel: $0)
                    .padding(16)
            }
        )
    }

    @ViewBuilder
    private var transactionTypeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("거래 유형")
                .font(.headline)
                .fontWeight(.semibold)

            HStack(spacing: 8) {
                ForEach(TransactionType.allCases, id: \.self) { type in
                    transactionTypeButton(type)
                }
            }
        }
    }
    
    @ViewBuilder
    private func transactionTypeButton(_ type: TransactionType) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.send(.setTransactionType(type))
            }
        }, label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(type.color.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: type.icon)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(type.color)
                }
                
                Text(type.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(
                        color: viewModel.selectedTransactionType == type ? 
                            type.color.opacity(0.3) : Color.black.opacity(0.05),
                        radius: viewModel.selectedTransactionType == type ? 8 : 2,
                        x: 0,
                        y: viewModel.selectedTransactionType == type ? 4 : 1
                    )
            }
            .overlay {
                if viewModel.selectedTransactionType == type {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(type.color, lineWidth: 2)
                }
            }
            .scaleEffect(viewModel.selectedTransactionType == type ? 1.05 : 1.0)
        })
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private var categorySelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("카테고리 선택")
                .font(.headline)
                .fontWeight(.semibold)
            VStack(alignment: .leading, spacing: 12) {
                if !viewModel.categories.isEmpty {
                    ForEach(viewModel.categories, id: \.id) { category in
                        categoryCard(category)
                    }
                } else {
                    emptyCategory
                }

                categoryCreationButton
            }
        }
    }

    @ViewBuilder
    private var emptyCategory: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder.badge.plus")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("카테고리가 없습니다")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("새 카테고리를 만들어보세요")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    @ViewBuilder
    private var categoryCreationButton: some View {
        Button("새 카테고리 + 서브카테고리 만들기") {
            viewModel.send(.presentCategoryForm(nil))
        }
        .font(.subheadline)
        .foregroundColor(.blue)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }

    @ViewBuilder
    private func categoryCard(_ category: CategoryDTO) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: category.iconName)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(viewModel.selectedTransactionType.color)
                    .cornerRadius(6)

                Text(category.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Button {
                    viewModel.send(.presentCategoryForm(category))
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("추가")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 4) {
                ForEach(category.subCategories, id: \.id) { subCategory in
                    subCategoryCard(subCategory)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    @ViewBuilder
    private func subCategoryCard(_ subCategory: SubCategoryDTO) -> some View {
        Button {
            viewModel.send(.setSubCategory(subCategory))
        } label: {
            Text(subCategory.name)
                .font(.subheadline)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
        .foregroundStyle(viewModel.selectedSubCategory == subCategory ? Color.green : .primary)
        .overlay {
            if viewModel.selectedSubCategory == subCategory {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.green, lineWidth: 2)
            }
        }
    }
}

#Preview {
    TransactionTypeCategoryFormView(
        viewModel: .init(
            getCategoriesByTypeUseCase: MockGetCategoriesByTypeUseCase(),
            createCategoryUseCase: MockCreateCategoryUseCase(),
            createSubCategoryUseCase: MockCreateSubCategoryUseCase()
        )
    )
}
