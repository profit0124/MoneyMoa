//
//  SettingView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/10/25.
//

import SwiftUI

struct SettingsView: View {
    let router: AppRouter
    
    var body: some View {
        VStack {
            Text("Settings View")
                .font(.largeTitle)
                .padding()
            
            Button("Budget Template") {
                router.push(.settingsBudget)
            }
            .padding()
            
            Spacer()
        }
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Close") {
                    router.dismissModal()
                }
            }
        }
    }
}
