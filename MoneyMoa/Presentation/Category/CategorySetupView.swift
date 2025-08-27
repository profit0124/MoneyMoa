//
//  CategorySettingView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/25/25.
//

import SwiftUI

struct CategorySetupView: View {

    @State private var viewModel: CategoryListViewModel

    init(viewModel: CategoryListViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            CategoryListView(viewModel: viewModel)
                .padding(16)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("카테고리 설정")
    }
}

#Preview {
    CoordinatorHost(container: MockDIContainer(), start: .settings(.category))
}
