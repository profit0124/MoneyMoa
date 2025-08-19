//
//  UpdateTransactionView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/10/25.
//

import SwiftUI

struct UpdateTransactionView: View {
    let transaction: TransactionDTO
    @Environment(AppRouter.self) private var router
    
    var body: some View {
        VStack {
            Text("Update Transaction View")
                .font(.largeTitle)
                .padding()
            
            Text("Editing: \(transaction.id)")
                .padding()
            
            Button("Save") {
                router.pop()
            }
            .padding()
            
            Spacer()
        }
        .navigationTitle("Edit Transaction")
    }
}
