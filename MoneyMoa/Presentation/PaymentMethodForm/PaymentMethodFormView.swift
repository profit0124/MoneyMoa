//
//  PaymentMethodFormView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/18/25.
//

import SwiftUI

struct PaymentMethodFormView: View {

    @Environment(AppRouter.self) private var router
    @Bindable var viewModel: PaymentMethodFormViewModel

    var body: some View {
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
        .navigationTitle(viewModel.isCreateMode ? "새 결제수단" : "결제수단 수정")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("저장") {
                    viewModel.send(.tappedSubmitButton(router))
                }
                .disabled(!viewModel.isValid)
            }

            if !viewModel.isCreateMode {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(role: .destructive) {
                        viewModel.send(.showDeleteConfirmation)
                    } label: {
                        Text("삭제")
                    }
                }
            }
        }
        .alert("결제수단 삭제", isPresented: $viewModel.showingDeleteConfirmation) {
            Button("삭제", role: .destructive) {
                viewModel.send(.deletePaymentMethod(router))
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("이 결제수단을 삭제하시겠습니까?")
        }
        .alert("오류", isPresented: $viewModel.showingErrorAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "알 수 없는 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.")
        }
    }
}

#Preview("Create") {
    CoordinatorHost(
        container: MockDIContainer(),
        start: .settings(.paymentMethodForm(nil))
    )
}

#Preview("Update") {
    CoordinatorHost(
        container: MockDIContainer(),
        start: .settings(.paymentMethodForm(.mockCreditCard))
    )
}
