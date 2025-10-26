//
//  PaymentMethodManagementViewModel.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 10/20/25.
//

import Foundation
import Observation
import Combine

@Observable
final class PaymentMethodManagementViewModel {

    // MARK: UseCases
    private let getAllPaymentMethodsUseCase: GetAllPaymentMethodsUseCase
    private let paymentMethodEventPublisher: any PaymentMethodEventPublisher

    // MARK: State
    var paymentMethods: [PaymentMethodDTO] = []
    var isLoading: Bool = false

    var showingErrorAlert: Bool = false {
        didSet {
            if !showingErrorAlert {
                errorMessage = nil
            }
        }
    }
    var errorMessage: String?

    private var cancellables: Set<AnyCancellable> = []

    init(
        getAllPaymentMethodsUseCase: GetAllPaymentMethodsUseCase,
        paymentMethodEventPublisher: any PaymentMethodEventPublisher
    ) {
        self.getAllPaymentMethodsUseCase = getAllPaymentMethodsUseCase
        self.paymentMethodEventPublisher = paymentMethodEventPublisher

        setupPaymentMethodEventSubscription()
    }

    enum Action {
        case onAppear
        case editPaymentMethod(PaymentMethodDTO, AppRouter)
        case createPaymentMethod(AppRouter)
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear:
            onAppear()

        case .editPaymentMethod(let paymentMethod, let router):
            handleEditPaymentMethod(paymentMethod, router)

        case .createPaymentMethod(let router):
            handleCreatePaymentMethod(router)
        }
    }

    private func onAppear() {
        if paymentMethods.isEmpty {
            Task {
                await fetchPaymentMethods()
            }
        }
    }

    private func fetchPaymentMethods() async {
        isLoading = true
        do {
            self.paymentMethods = try await getAllPaymentMethodsUseCase.execute()
        } catch {
            errorMessage = "결제수단 목록을 불러오는데 실패했습니다.\n잠시 후 다시 시도해주세요."
            showingErrorAlert = true
        }
        isLoading = false
    }

    private func handleEditPaymentMethod(_ paymentMethod: PaymentMethodDTO, _ router: AppRouter) {
        Task {
            await router.present(.settings(.paymentMethodForm(paymentMethod)), as: .sheet)
        }
    }

    private func handleCreatePaymentMethod(_ router: AppRouter) {
        Task {
            await router.present(.settings(.paymentMethodForm(nil)), as: .sheet)
        }
    }

    private func setupPaymentMethodEventSubscription() {
        paymentMethodEventPublisher.paymentMethodEvents
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] paymentMethodEvent in
                guard let self = self else { return }

                switch paymentMethodEvent.type {
                case .created:
                    self.paymentMethods.append(paymentMethodEvent.paymentMethod)

                case .updated:
                    if let index = self.paymentMethods.firstIndex(where: { $0.id == paymentMethodEvent.paymentMethod.id }) {
                        self.paymentMethods[index] = paymentMethodEvent.paymentMethod
                    }

                case .deleted:
                    self.paymentMethods.removeAll { $0.id == paymentMethodEvent.paymentMethod.id }
                }
            })
            .store(in: &cancellables)
    }
}
