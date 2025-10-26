//
//  PaymentMethodManagementView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 10/20/25.
//

import SwiftUI

struct PaymentMethodManagementView: View {

    @Environment(AppRouter.self) private var router
    @State private var viewModel: PaymentMethodManagementViewModel

    init(viewModel: PaymentMethodManagementViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                paymentMethodListSection
            }
            .padding(16)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("결제수단 관리")
        .alert("오류", isPresented: $viewModel.showingErrorAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .onAppear {
            viewModel.send(.onAppear)
        }
    }

    @ViewBuilder
    private var paymentMethodListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("결제수단")
                .font(.headline)
                .fontWeight(.semibold)

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(40)
            } else if viewModel.paymentMethods.isEmpty {
                emptyPaymentMethodList
            } else {
                paymentMethodGrid
                createPaymentMethodButton
            }
        }
    }

    @ViewBuilder
    private var emptyPaymentMethodList: some View {
        VStack(spacing: 16) {
            Image(systemName: "creditcard.and.123")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("등록된 결제수단이 없습니다")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("새 결제수단을 만들어보세요")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button("새 결제수단 만들기") {
                viewModel.send(.createPaymentMethod(router))
            }
            .font(.subheadline)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.blue)
            .cornerRadius(8)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var paymentMethodGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            ForEach(viewModel.paymentMethods, id: \.id) { paymentMethod in
                paymentMethodCard(paymentMethod)
            }
        }
    }

    @ViewBuilder
    private func paymentMethodCard(_ paymentMethod: PaymentMethodDTO) -> some View {
        Button {
            viewModel.send(.editPaymentMethod(paymentMethod, router))
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: paymentMethod.displayIconName)
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(paymentMethod.kind.color)
                        .cornerRadius(10)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(paymentMethod.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Text(paymentMethod.kind.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                if !paymentMethod.isActive {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)

                        Text("비활성")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(paymentMethod.isActive ? Color.clear : Color.orange.opacity(0.3), lineWidth: 1)
            }
        }
    }

    @ViewBuilder
    private var createPaymentMethodButton: some View {
        Button {
            viewModel.send(.createPaymentMethod(router))
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)

                Text("새 결제수단 만들기")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(.blue)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

#Preview {
    CoordinatorHost(container: MockDIContainer(), start: .settings(.paymentMethodManagement))
}
