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

    // MARK: UseCases
    private var createPaymentMethodUseCase: CreatePaymentMethodUseCase
    private var updatePaymentMethodUseCase: UpdatePaymentMethodUseCase
    private var deletePaymentMethodUseCase: DeletePaymentMethodUseCase
    private var paymentMethodEventPublisher: any PaymentMethodEventPublisher

    // MARK: Mode
    private let selectedPaymentMethod: PaymentMethodDTO?

    // MARK: Form State
    var name: String
    var selectedKind: PaymentMethodKind

    // MARK: Alert State
    var showingDeleteConfirmation: Bool = false
    var showingErrorAlert: Bool = false {
        didSet {
            if !showingErrorAlert {
                errorMessage = nil
            }
        }
    }
    var errorMessage: String?

    var isCreateMode: Bool {
        selectedPaymentMethod == nil
    }

    var isValid: Bool {
        let basicValidation = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        if isCreateMode {
            return basicValidation
        } else {
            return basicValidation && hasChanges
        }
    }

    private var hasChanges: Bool {
        guard let selectedPaymentMethod = selectedPaymentMethod else { return true }
        return name.trimmingCharacters(in: .whitespacesAndNewlines) != selectedPaymentMethod.name ||
               selectedKind != selectedPaymentMethod.kind
    }

    init(
        createPaymentMethodUseCase: CreatePaymentMethodUseCase,
        updatePaymentMethodUseCase: UpdatePaymentMethodUseCase,
        deletePaymentMethodUseCase: DeletePaymentMethodUseCase,
        paymentMethodEventPublisher: any PaymentMethodEventPublisher,
        selectedPaymentMethod: PaymentMethodDTO? = nil
    ) {
        self.createPaymentMethodUseCase = createPaymentMethodUseCase
        self.updatePaymentMethodUseCase = updatePaymentMethodUseCase
        self.deletePaymentMethodUseCase = deletePaymentMethodUseCase
        self.paymentMethodEventPublisher = paymentMethodEventPublisher
        self.selectedPaymentMethod = selectedPaymentMethod
        self.name = selectedPaymentMethod?.name ?? ""
        self.selectedKind = selectedPaymentMethod?.kind ?? .credit
    }

    enum Action {
        case tappedSubmitButton(AppRouter)
        case showDeleteConfirmation
        case deletePaymentMethod(AppRouter)
        case handleError(Error)
    }

    func send(_ action: Action) {
        switch action {
        case .tappedSubmitButton(let router):
            handleTappedSubmitButton(router)

        case .showDeleteConfirmation:
            showingDeleteConfirmation = true

        case .deletePaymentMethod(let router):
            handleDeletePaymentMethod(router)

        case .handleError(let error):
            handleError(error)
        }
    }

    private func handleTappedSubmitButton(_ router: AppRouter) {
        Task {
            do {
                let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

                if let selectedPaymentMethod = selectedPaymentMethod {
                    // Update 모드
                    try await handleUpdateMode(selectedPaymentMethod: selectedPaymentMethod, name: trimmedName)
                } else {
                    // Create 모드
                    try await handleCreateMode(name: trimmedName)
                }

                await router.dismissModal()
            } catch {
                self.send(.handleError(error))
            }
        }
    }

    private func handleCreateMode(name: String) async throws {
        let paymentMethod = PaymentMethodDTO(
            name: name,
            kind: selectedKind
        )
        try await createPaymentMethodUseCase.execute(paymentMethod)

        paymentMethodEventPublisher.publish(.init(type: .created, paymentMethod: paymentMethod))
    }

    private func handleUpdateMode(selectedPaymentMethod: PaymentMethodDTO, name: String) async throws {
        let updatedPaymentMethod = PaymentMethodDTO(
            id: selectedPaymentMethod.id,
            name: name,
            kind: selectedKind,
            iconName: selectedKind.iconName,
            orderIndex: selectedPaymentMethod.orderIndex,
            isActive: selectedPaymentMethod.isActive
        )

        try await updatePaymentMethodUseCase.execute(updatedPaymentMethod)

        paymentMethodEventPublisher.publish(.init(type: .updated, paymentMethod: updatedPaymentMethod))
    }

    private func handleDeletePaymentMethod(_ router: AppRouter) {
        Task {
            do {
                guard let selectedPaymentMethod = selectedPaymentMethod else { return }

                try await deletePaymentMethodUseCase.execute(selectedPaymentMethod.id)

                paymentMethodEventPublisher.publish(.init(type: .deleted, paymentMethod: selectedPaymentMethod))

                await router.dismissModal()
            } catch {
                self.send(.handleError(error))
            }
        }
    }

    private func handleError(_ error: Error) {
        if let creationError = error as? PaymentMethodCreationError {
            switch creationError {
            case .emptyName:
                errorMessage = "결제수단명을 입력해주세요."
            case .duplicateName:
                errorMessage = "이미 존재하는 결제수단명입니다."
            }
        } else if let updateError = error as? PaymentMethodUpdateError {
            switch updateError {
            case .emptyName:
                errorMessage = "결제수단명을 입력해주세요."
            case .duplicateName:
                errorMessage = "이미 존재하는 결제수단명입니다."
            }
        } else if let repositoryError = error as? RepositoryError {
            switch repositoryError {
            case .hasActiveTemplates:
                errorMessage = "현재 해당 항목을 사용 중인 거래 템플릿이 있습니다.\n템플릿을 먼저 삭제한 후 다시 시도해주세요."
            case .custom(let message):
                errorMessage = message
            default:
                errorMessage = "알 수 없는 오류가 발생했습니다.\n잠시 후 다시 시도해주세요."
            }
        } else {
            errorMessage = "알 수 없는 오류가 발생했습니다.\n잠시 후 다시 시도해주세요."
        }
        showingErrorAlert = true
    }
}
