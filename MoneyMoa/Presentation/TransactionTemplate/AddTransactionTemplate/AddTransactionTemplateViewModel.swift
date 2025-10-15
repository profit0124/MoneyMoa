//
//  AddTransactionTemplateViewModel.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/24/25.
//

import Foundation
import SwiftUI

@Observable
final class AddTransactionTemplateViewModel {

    private let transactionTemplateEventPublisher: TransactionTemplateEventPublisher

    // MARK: - Dependencies

    private let createTransactionTemplateUseCase: CreateTransactionTemplateUseCase

    let amountPlacePaymentViewModel: AmountPlacePaymentMethodFormViewModel
    let transactionTypeSelectionViewModel: TransactionTypeCategoryFormViewModel
    let templatePatternFormViewModel: TemplatePatternFormViewModel

    // MARK: - UI State

    private var completedStep = Set<TransactionTemplateStep>()
    var currentStep: TransactionTemplateStep = .amountPlacePaymentMethod
    var filteredCompletedStep: [TransactionTemplateStep] {
        completedStep.filter({ $0.stepNumber < currentStep.stepNumber }).sorted { $0.stepNumber < $1.stepNumber }
    }

    // MARK: - Computed Properties for Data Binding

    var currentMemo: String {
        templatePatternFormViewModel.memo
    }

    var currentRecurrencePattern: RecurrencePattern {
        templatePatternFormViewModel.recurrencePattern
    }

    var isValid: Bool {
        switch currentStep {
        case .amountPlacePaymentMethod:
            amountPlacePaymentViewModel.isValid
        case .transactionTypeCategory:
            transactionTypeSelectionViewModel.isValid
        case .patternAdditional:
            templatePatternFormViewModel.isValid
        }
    }

    var buttonTitle: String {
        switch currentStep {
        case .amountPlacePaymentMethod:
            "다음"
        case .transactionTypeCategory:
            "다음"
        case .patternAdditional:
            "템플릿 생성"
        }
    }

    // MARK: - Init

    public init(
        transactionTemplateEventPublisher: TransactionTemplateEventPublisher,
        createTransactionTemplateUseCase: CreateTransactionTemplateUseCase,
        amountPlacePaymentViewModel: AmountPlacePaymentMethodFormViewModel,
        transactionTypeSelectionViewModel: TransactionTypeCategoryFormViewModel,
        templatePatternFormViewModel: TemplatePatternFormViewModel
    ) {
        self.transactionTemplateEventPublisher = transactionTemplateEventPublisher
        self.createTransactionTemplateUseCase = createTransactionTemplateUseCase
        self.amountPlacePaymentViewModel = amountPlacePaymentViewModel
        self.transactionTypeSelectionViewModel = transactionTypeSelectionViewModel
        self.templatePatternFormViewModel = templatePatternFormViewModel
    }

    enum Action {
        case buttonTapped(() -> Void)
    }

    func send(_ action: Action) {
        switch action {
        case .buttonTapped(let completion):
            handleButtonTapped(completion)
        }
    }

    private func handleButtonTapped(_ completion: @escaping () -> Void) {
        switch currentStep {
        case .amountPlacePaymentMethod:
            completedStep.insert(.amountPlacePaymentMethod)
            currentStep = .transactionTypeCategory
        case .transactionTypeCategory:
            completedStep.insert(.transactionTypeCategory)
            currentStep = .patternAdditional
        case .patternAdditional:
            createTransactionTemplate(completion)
        }
    }

    private func createTransactionTemplate(_ completion: @escaping () -> Void) {
        if let amount = amountPlacePaymentViewModel.amount,
           let paymentMethod = amountPlacePaymentViewModel.selectedPaymentMethod,
           let subCategory = transactionTypeSelectionViewModel.selectedSubCategory {

            let transactionTemplateDTO = TransactionTemplateDTO(
                amount: amount,
                place: amountPlacePaymentViewModel.place,
                memo: templatePatternFormViewModel.memo,
                transactionType: transactionTypeSelectionViewModel.selectedTransactionType,
                recurrencePeriod: templatePatternFormViewModel.recurrencePattern.period,
                createdAt: Date(), // 현재 시점에 템플릿 생성
                subCategory: subCategory,
                paymentMethod: paymentMethod,
                recurrencePattern: templatePatternFormViewModel.recurrencePattern,
                executionState: TemplateExecutionState(
                    lastExecutedAt: nil,
                    executionCount: 0
                )
            )

            Task {
                do {
                    try await createTransactionTemplateUseCase.execute(transactionTemplateDTO)
                    transactionTemplateEventPublisher.publish(.init(type: .created, template: transactionTemplateDTO))
                    await MainActor.run {
                        completion()
                    }
                } catch {
                    print("템플릿 생성 실패: \(error)")
                }
            }
        }
    }
}

// MARK: - TransactionTemplateStep

enum TransactionTemplateStep: CaseIterable {
    case amountPlacePaymentMethod
    case transactionTypeCategory
    case patternAdditional

    var title: String {
        switch self {
        case .amountPlacePaymentMethod:
            return "금액 및 결제정보"
        case .transactionTypeCategory:
            return "거래유형 및 카테고리"
        case .patternAdditional:
            return "반복 패턴 및 추가정보"
        }
    }

    var subtitle: String {
        switch self {
        case .amountPlacePaymentMethod:
            return "금액, 장소, 결제수단을 입력하세요"
        case .transactionTypeCategory:
            return "거래유형과 카테고리를 선택하세요"
        case .patternAdditional:
            return "반복 패턴, 실행 시간, 메모를 설정하세요"
        }
    }

    var icon: String {
        switch self {
        case .amountPlacePaymentMethod:
            return "wonsign.circle.fill"
        case .transactionTypeCategory:
            return "tag.circle.fill"
        case .patternAdditional:
            return "repeat.circle.fill"
        }
    }

    var stepNumber: Int {
        switch self {
        case .amountPlacePaymentMethod:
            return 1
        case .transactionTypeCategory:
            return 2
        case .patternAdditional:
            return 3
        }
    }
}
