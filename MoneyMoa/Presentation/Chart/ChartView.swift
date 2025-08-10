//
//  ChartView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/10/25.
//

import SwiftUI

struct ChartView: View {
    @Environment(AppRouter.self) private var router
    
    var body: some View {
        VStack {
            Text("Chart View")
                .font(.largeTitle)
                .padding()
            
            Spacer()
        }
        .navigationTitle("Charts")
    }
}
