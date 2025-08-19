//
//  PaymentMethodFormView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/18/25.
//

import SwiftUI

struct PaymentMethodFormView: View {

    @Bindable var viewModel: PaymentMethodFormViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("결제수단 정보") {
                    TextField("결제수단 이름", text: $viewModel.name)

                    Picker("종류", selection: $viewModel.selectedKind) {
                        ForEach(PaymentMethodKind.allCases, id: \.self) { kind in
                            HStack(spacing: 8) {
                                Image(systemName: kind.iconName)
                                    .font(.caption)

                                Text(kind.displayName)
                                    .tag(kind)
                            }
                        }
                    }
                }
            }
            .navigationTitle("새 결제수단")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        viewModel.send(.createPaymentMethod)
                    }
                    .disabled(viewModel.name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    PaymentMethodFormView(viewModel: .init(createPaymentMethodUseCase: MockCreatePaymentMethodUseCase()))
}
