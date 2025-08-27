//
//  CategorySelectorView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/25/25.
//

import SwiftUI

struct CategorySelectorView: View {

    @Environment(AppRouter.self) private var router
    @State private var viewModel: CategorySelectorViewModel

    init(viewModel: CategorySelectorViewModel) {
        self._viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.categories.isEmpty {
                emptyStateView
            } else {
                categoryListView
            }
        }
        .navigationTitle("카테고리 선택")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("닫기") {
                    router.dismissModal()
                }
            }
        }
        .onAppear {
            viewModel.send(.onAppear)
        }
    }
    
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("카테고리를 불러오는 중...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("카테고리가 없습니다")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var categoryListView: some View {
        List {
            ForEach(TransactionType.allCases, id: \.self) { transactionType in
                if let categories = viewModel.categoriesByTransactionType[transactionType], !categories.isEmpty {
                    Section(header: sectionHeader(for: transactionType)) {
                        ForEach(categories, id: \.id) { category in
                            categoryRow(category)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    @ViewBuilder
    private func sectionHeader(for transactionType: TransactionType) -> some View {
        HStack(spacing: 8) {
            Image(systemName: transactionType.icon)
                .foregroundColor(transactionType.color)
                .font(.subheadline)
            
            Text(transactionType.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
    
    @ViewBuilder
    private func categoryRow(_ category: CategoryDTO) -> some View {
        Button {
            viewModel.send(.selectCategory(category, router))
        } label: {
            HStack(spacing: 12) {
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
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 선택 표시
                if category.id == viewModel.selectedCategory.id {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CoordinatorHost(container: MockDIContainer(), start: .settings(.categorySelector(.mockFood)))
}
