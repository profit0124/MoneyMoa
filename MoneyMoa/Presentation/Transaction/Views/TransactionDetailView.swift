//
//  TransactionDetailView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/10/25.
//

import SwiftUI

struct TransactionDetailView: View {
    let transaction: TransactionDTO
    @Environment(AppRouter.self) private var router
    
    var body: some View {
        VStack {
            Text("Transaction Detail View")
                .font(.largeTitle)
                .padding()
            
            Text("ID: \(transaction.id)")
                .padding()
            
            Text("Amount: \(transaction.amount)")
                .padding()
            
            Button("Edit") {
                router.push(.transactionUpdate(transaction))
            }
            .padding()
            
            Spacer()
        }
        .navigationTitle("Transaction Detail")
    }
}
