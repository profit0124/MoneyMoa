//
//  CategoryFormView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/26/25.
//

import SwiftUI

struct CategoryFormView: View {

    @Environment(AppRouter.self) private var router
    @State private var viewModel: CategoryFormViewModel

    init(viewModel: CategoryFormViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                TransactionTypeSelectionView(selectedTransactionType: $viewModel.selectedTransactionType)
                    .padding(4)
                    .clipped(antialiased: false)

                categoryNameSection

                if viewModel.selectedCategory == nil {
                    subCategoryNameSection
                }

                IconSelectionView(color: viewModel.selectedTransactionType.color, selectedIcon: $viewModel.categoryIconName)

                if viewModel.selectedCategory != nil {
                    subCategoriesSection
                }
            }
        }
        .padding(.horizontal, 16)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("저장") {
                    viewModel.send(.tappedSubmitButton(router))
                }
                .disabled(!viewModel.isValid)
            }

            if viewModel.selectedCategory != nil {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(role: .destructive) {
                        viewModel.send(.showDeleteConfirmation)
                    } label: {
                        Text("삭제")
                    }
                }
            }
        }
        .alert("서브카테고리 추가", isPresented: $viewModel.showingAddSubCategoryAlert) {
            TextField("서브카테고리 이름", text: $viewModel.newSubCategoryName)
            Button("추가") {
                viewModel.send(.addSubCategory)
            }
            Button("취소", role: .cancel) {
                viewModel.send(.cancelAddSubCategory)
            }
        } message: {
            if let errorMessage = viewModel.alertErrorMessage {
                Text(errorMessage)
            } else {
                Text("새로운 서브카테고리를 추가하세요.")
            }
        }
        .alert("카테고리 삭제", isPresented: $viewModel.showingDeleteConfirmation) {
            Button("삭제", role: .destructive) {
                viewModel.send(.deleteCategory(router))
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("이 카테고리를 삭제하시겠습니까?\n연결된 모든 서브카테고리도 함께 삭제됩니다.")
        }
        .alert("오류", isPresented: $viewModel.showingErrorAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "알 수 없는 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.")
        }
    }

    @ViewBuilder
    private var categoryNameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("카테고리")
                .font(.footnote)
                .foregroundStyle(.secondary)

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

    @ViewBuilder
    private var subCategoryNameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("서브카테고리")
                .font(.footnote)
                .foregroundStyle(.secondary)

            TextField("서브카티고리 이름", text: $viewModel.newSubCategoryName)
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
    private var subCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("서브카테고리")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button(action: {
                    viewModel.send(.showAddSubCategoryAlert)
                }, label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(viewModel.selectedTransactionType.color)
                        .font(.title3)
                })
            }
            
            // 추가된 서브카테고리 목록
            if !viewModel.addedSubCategories.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(viewModel.addedSubCategories, id: \.id) { subCategory in
                        subCategoryCard(subCategory)
                    }
                }
            }
            
            // 기존 서브카테고리 목록 (수정 모드일 때)
            if !viewModel.subCategories.isEmpty {
                Text("기존 서브카테고리")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(viewModel.subCategories, id: \.id) { subCategory in
                        subCategoryCard(subCategory, isExisting: true)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func subCategoryCard(_ subCategory: SubCategoryDTO, isExisting: Bool = false) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(viewModel.selectedTransactionType.color.opacity(0.2))
                .frame(width: 8, height: 8)
            
            Text(subCategory.name)
                .font(.subheadline)
                .foregroundStyle(.primary)
            
            Spacer()
            
            if !isExisting {
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        viewModel.addedSubCategories.removeAll { $0.id == subCategory.id }
                    }
                }, label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                })
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(viewModel.selectedTransactionType.color.opacity(0.3), lineWidth: 1)
        }
    }
}

#Preview("ADD") {
    CoordinatorHost(
        container: MockDIContainer(),
        start: .settings(.categoryForm(.configuration, nil, .variableExpense))
    )
}

#Preview("Updagte") {
    CoordinatorHost(container: MockDIContainer(), start: .settings(.categoryForm(.configuration, .mockExpense, .variableExpense)))
}

#Preview("ADD From Selection") {
    CoordinatorHost(container: MockDIContainer(), start: .settings(.categoryForm(.selection, nil, .variableExpense)))
}
