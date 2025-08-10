//
//  BudgetTemplateView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/10/25.
//

import SwiftUI

struct BudgetTemplateView: View {
    @Environment(AppRouter.self) private var router
    
    var body: some View {
        VStack {
            Text("Budget Template View")
                .font(.largeTitle)
                .padding()
            
            Spacer()
        }
        .navigationTitle("Budget Template")
    }
}

#Preview {
    NavigationStack {
        BudgetTemplateView()
            .environment(AppRouter())
    }
    
}
