//
//  AddTransactionView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/10/25.
//

import SwiftUI

struct AddTransactionView: View {
    let router: AppRouter
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Add Transaction View")
                    .font(.largeTitle)
                    .padding()
                
                Spacer()
                
                Button("Save & Close") {
                    router.dismissModal()
                }
                .padding()
            }
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        router.dismissModal()
                    }
                }
            }
        }
    }
}
