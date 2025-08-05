//
//  ContentView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/25/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        MainView(viewModel: .init(
            getMonthlyTransactionsUseCase: MockGetMonthlyTransactionsUseCase(),
            getExpenseSumUntilDateUseCase: MockGetExpenseSumUntilDateUseCase(),
            getMonthlyBudgetUseCase: MockGetMonthlyBudgetUseCase(),
            getBudgetTemplateUseCase: MockGetBudgetTemplateUseCase(),
            createBudgetFromTemplateUseCase: MockCreateBudgetFromTemplateUseCase()
        ))
    }
}

#Preview {
    ContentView()
}
