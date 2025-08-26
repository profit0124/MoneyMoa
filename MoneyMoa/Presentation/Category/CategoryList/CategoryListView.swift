//
//  CategoryListView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/25/25.
//

import SwiftUI

struct CategoryListView: View {

    @Environment(AppRouter.self) private var router
    @Bindable var viewModel: CategoryListViewModel

    var body: some View {
            VStack(spacing: 16) {
                TransactionTypeSelectionView(
                    selectedTransactionType: Binding(get: {
                        viewModel.selectedTransactionType
                    }, set: {
                        viewModel.send(.selectTransactionType($0))
                    }))

                categoryListSection
            }
            .onAppear {
                viewModel.send(.onAppear)
            }
            .onChange(of: router.sheet, { _, newValue in
                if newValue == nil {
                    viewModel.send(.onAppear)
                }

            })
    }

    @ViewBuilder
    private var categoryListSection: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            Text("카테고리")

            LazyVStack(spacing: 12) {
                if viewModel.categories.isEmpty {
                    emptyCategoryList
                } else {
                    ForEach(viewModel.categories, id: \.self) { category in
                        categoryCard(category)
                    }

                    categoryCreationButton
                }
            }
        }
    }

    @ViewBuilder
    private var emptyCategoryList: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("카테고리가 없습니다")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("새 카테고리를 만들어보세요")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button("새 카테고리 만들기") {
                // 카테고리 만들기 Action
            }
            .font(.subheadline)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(viewModel.selectedTransactionType.color)
            .cornerRadius(8)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func categoryCard(_ category: CategoryDTO) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            categoryHeader(category)

            subCategorySection(category: category)
        }
        .padding(16)
        .background {
            Color(.systemBackground)
        }
        .cornerRadius(12)

        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    @ViewBuilder
    private func categoryHeader(_ category: CategoryDTO) -> some View {
        HStack {
            // 카테고리 아이콘
            Image(systemName: category.iconName)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(category.transactionType.color)
                .cornerRadius(6)

            // 카테고리 이름
            Text(category.name)
                .font(.subheadline)
                .fontWeight(.medium)

            Spacer()
        }
        .onTapGesture {
            // configuration mode 일 경우 categoryUpdate Sheet opne
        }
        .overlay(alignment: .trailing) {
            addActionButton {
                viewModel.send(.addSubCategory(category, router))
            }
        }
    }

    @ViewBuilder
    private func addActionButton(_ action: @escaping () -> Void) -> some View {
        HStack(spacing: 8) {
            Button(action: {
                action()
            }, label: {
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
            })
        }
    }

    @ViewBuilder
    private var categoryCreationButton: some View {
        Button("새 카테고리 + 서브카테고리 만들기") {
//            viewModel.send(.presentCategoryForm(nil))
        }
        .font(.subheadline)
        .foregroundColor(.blue)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }

    @ViewBuilder
    private func subCategorySection(category: CategoryDTO) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 4) {
            ForEach(category.subCategories, id: \.id) { subCategory in
                subCategoryCard(category: category, subCategory: subCategory)
            }
        }
    }

    @ViewBuilder
    private func subCategoryCard(category: CategoryDTO, subCategory: SubCategoryDTO) -> some View {
        Button(action: {
            viewModel.send(.selectSubCategory(category, subCategory, router))
        }, label: {
            Text(subCategory.name)
                .font(.subheadline)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
        })
        .foregroundStyle(viewModel.selectedSubCategory == subCategory ? Color.green : .primary)
        .overlay {
            if viewModel.selectedSubCategory == subCategory {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.green, lineWidth: 2)
            }
        }
    }
}

#Preview("Configuration") {
    CategoryListView(viewModel: .init(getCategoriesUseCase: MockGetCategoriesByTypeUseCase()))
        .environment(AppRouter())
}

#Preview("Selection") {
    CategoryListView(viewModel: .init(getCategoriesUseCase: MockGetCategoriesByTypeUseCase(), mode: .selection))
        .environment(AppRouter())
}
