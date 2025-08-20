//
//  AmountPlacePaymentMethodFormView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/18/25.
//

import SwiftUI

enum AmountPlacePaymentMethodFormField: Hashable {
    case amount
    case place
    case paymentMethod
}

struct AmountPlacePaymentMethodFormView: View {

    @Bindable var viewModel: AmountPlacePaymentMethodFormViewModel
    @FocusState var focusField: AmountPlacePaymentMethodFormField?

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            amountSection
            placeSection
            paymentMethodSection
        }
        .sheet(item: $viewModel.paymentMethodFormViewModel, onDismiss: {
            viewModel.send(.unsubscribe)
        }, content: { paymentMethodFormViewModel in
            PaymentMethodFormView(viewModel: paymentMethodFormViewModel)
        })
        .onAppear {
            viewModel.send(.onAppear)
        }
        .onChange(of: viewModel.focusField, { _, newValue in
            if focusField != newValue {
                focusField = newValue
            }
        })
        .onChange(of: focusField, { _, newValue in
            if viewModel.focusField != newValue {
                viewModel.focusField = newValue
            }
        })
    }

    @ViewBuilder
    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("금액")
                .font(.headline)
                .fontWeight(.semibold)

            HStack(spacing: 12) {
                TextField("금액을 입력하세요.", text: Binding(get: {
                    viewModel.formattedAmount
                }, set: {
                    viewModel.send(.setDecimalAmount($0))
                }))
                    .keyboardType(.decimalPad)
                    .focused($focusField, equals: .amount)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.leading)
                    .textFieldStyle(.plain)

                Text("원")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 2)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .frame(height: 2)
                    .foregroundStyle(
                        self.focusField == .amount ? .primary : Color(.systemGray6)
                    )
            }
        }
    }

    @ViewBuilder
    private var placeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("장소")
                .font(.headline)
                .fontWeight(.semibold)

            TextField("거래 장소 또는 대상을 입력하세요", text: $viewModel.place)
                .focused($focusField, equals: .place)
                .fontWeight(.bold)
                .multilineTextAlignment(.leading)
                .textFieldStyle(.plain)
                .padding(.bottom, 4)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .frame(height: 2)
                        .foregroundStyle(
                            self.focusField == .place ? .primary : Color(.systemGray6)
                        )
            }
        }
    }

    @ViewBuilder
    private var paymentMethodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("결제수단")
                .font(.headline)
                .fontWeight(.semibold)

            if !viewModel.paymentMethodOptions.isEmpty {
                paymentMethodGrid(2)
            }

            Button("새 결제수단 만들기") {
                viewModel.send(.presentPaymentMethodForm)
            }
            .font(.subheadline)
            .foregroundStyle(.blue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
    }

    @ViewBuilder
    private func paymentMethodGrid(_ count: Int) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: count)) {
            ForEach(viewModel.paymentMethodOptions, id: \.id) { method in
                paymentMethodCard(method)
            }
        }
    }

    @ViewBuilder
    private func paymentMethodCard(_ method: PaymentMethodDTO) -> some View {
        Button {
            viewModel.send(.setSelectedPaymentMethod(method))
        } label: {
            HStack(spacing: 12) {
                Image(systemName: method.displayIconName)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(method.kind.color)
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(method.name)
                        .lineLimit(1)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    Text(method.kind.displayName)
                        .lineLimit(1)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if viewModel.selectedPaymentMethod == method {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(12)
        .background {
            viewModel.selectedPaymentMethod == method ? Color.green.opacity(0.1) : Color(.systemGray6)
        }
        .cornerRadius(8)
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    viewModel.selectedPaymentMethod == method ? Color.green : Color.clear, lineWidth: 2
                )
        }
    }
}

#Preview {
    AmountPlacePaymentMethodFormView(
        viewModel:
            AmountPlacePaymentMethodFormViewModel(
                getActivePaymentMethodsUseCase: MockGetActivePaymentMethodsUseCase(),
                createPaymentMethodUseCase: MockCreatePaymentMethodUseCase()
            )
    )
    .padding(.horizontal, 16)
}
