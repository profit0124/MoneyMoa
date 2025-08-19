//
//  PaymentMethodFormViewModel.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/18/25.
//

import Foundation
import Observation
import Combine

@Observable
final class PaymentMethodFormViewModel: Identifiable {
    let id = UUID()
    var createPaymentMethodUseCase: CreatePaymentMethodUseCase
    var name: String = ""
    var selectedKind: PaymentMethodKind = .credit
    var createPublisher = PassthroughSubject<PaymentMethodDTO, Never>()

    init(createPaymentMethodUseCase: CreatePaymentMethodUseCase,
         name: String = "",
         selectedKind: PaymentMethodKind = .credit,
    ) {
        self.createPaymentMethodUseCase = createPaymentMethodUseCase
        self.name = name
        self.selectedKind = selectedKind
    }

    enum Action {
        case createPaymentMethod
    }

    func send(_ action: Action) {
        Task {
            do {
                switch action {
                case .createPaymentMethod:
                    try await createdPaymentMethod()
                }
            } catch {
                print("error")
            }
        }

    }

    private func createdPaymentMethod() async throws {
        let dto = PaymentMethodDTO(name: name, kind: selectedKind)
        try await createPaymentMethodUseCase.execute(dto)
        resetForm()
        createPublisher.send(dto)
    }

    private func resetForm() {
        self.name = ""
        self.selectedKind = .credit
    }

}
