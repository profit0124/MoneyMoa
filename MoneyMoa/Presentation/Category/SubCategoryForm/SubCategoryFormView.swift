//
//  SubCategoryFormView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/25/25.
//

import SwiftUI

struct SubCategoryFormView: View {
    
    @State var viewModel: SubCategoryFormViewModel
    @Environment(AppRouter.self) private var router

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            categorySection
            subCategoryNameSection
            Spacer()
        }
        .padding(16)
        .navigationTitle(viewModel.selectedSubCategoryDTO == nil ? "새 서브카테고리" : "서브카테고리 편집")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("취소") {
                    router.dismissModal()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("저장") {
                     viewModel.send(.submit(router))
                }
                .disabled(!viewModel.isValid)
                .foregroundColor(viewModel.isValid ? .blue : .gray)
            }
        }
        .onChange(of: router.sheet, { _, newValue in
            if newValue == nil {
                viewModel.send(.unsubscribe)
            }
        })
    }
    
    @ViewBuilder
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("카테고리")
                .font(.headline)
                .fontWeight(.semibold)
            
            Button {
                viewModel.send(.showCategorySelector(router))
            } label: {
                HStack(spacing: 12) {
                    // 카테고리 아이콘
                    Image(systemName: viewModel.selectedCategory.iconName)
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(viewModel.selectedCategory.transactionType.color)
                        .cornerRadius(6)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.selectedCategory.transactionType.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(viewModel.selectedCategory.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    @ViewBuilder
    private var subCategoryNameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("서브카테고리명")
                .font(.headline)
                .fontWeight(.semibold)
            
            TextField("서브카테고리명을 입력하세요", text: $viewModel.subCategoryName)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .autocorrectionDisabled()
            
            if viewModel.subCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.subCategoryName.isEmpty {
                Text("서브카테고리명을 입력해주세요")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
}

#Preview {
    CoordinatorHost(container: MockDIContainer(), start: .settings(.subCategoryForm(.mockFood, nil)))
}

#Preview("Edit Mode") {
    CoordinatorHost(container: MockDIContainer(), start: .settings(.subCategoryForm(.mockFood, .mockFoodExpense)))
}
