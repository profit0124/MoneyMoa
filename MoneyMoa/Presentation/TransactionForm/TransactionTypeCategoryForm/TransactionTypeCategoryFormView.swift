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
        CategoryListView(viewModel: viewModel.categoryListViewModel)
    }
}

#Preview {
    TransactionTypeCategoryFormView(
        viewModel: MockDIContainer().makeTransactionTypeCategoryFormViewModel()
    )
    .environment(AppRouter())
}
