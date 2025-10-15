//
//  UpdateTransactionUseCaseImpl.swift
//  MoneyMoa
//
//  Created by profit on 8/20/25.
//

import Foundation

final class UpdateTransactionUseCaseImpl: UpdateTransactionUseCase {
    private let transactionWriter: TransactionWriter
    private let templateWriter: TransactionTemplateWriter

    init(
        transactionWriter: TransactionWriter,
        templateWriter: TransactionTemplateWriter
    ) {
        self.transactionWriter = transactionWriter
        self.templateWriter = templateWriter
    }

    func execute(
        _ transaction: TransactionDTO,
        strategy: TemplateUpdateStrategy = .none
    ) async throws {
        // 비즈니스 로직 검증: 금액 유효성 검사
        guard transaction.amount > 0 else {
            throw TransactionUpdateError.invalidAmount
        }

        // 전략에 따른 템플릿 처리
        try await handleTemplateStrategy(transaction: transaction, strategy: strategy)

        // 거래 수정 (Repository에서 SubCategory, PaymentMethod 존재 검증 수행)
        try await transactionWriter.updateTransaction(transaction)

    }

    // MARK: - Strategy Handling

    private func handleTemplateStrategy(
        transaction: TransactionDTO,
        strategy: TemplateUpdateStrategy
    ) async throws {
        switch strategy {
        case .updateWithTemplate:
            guard let template = transaction.transactionTemplate else { return }
            let syncedTemplate = syncTemplateData(from: transaction, original: template)
            try await templateWriter.updateTemplate(syncedTemplate)

        case .none:
            break
        }
    }

    // MARK: - Template Operations

    /// 템플릿 데이터 동기화 - 데이터만 동기화, 패턴과 nextDueDate 유지
    private func syncTemplateData(
        from transaction: TransactionDTO,
        original template: TransactionTemplateDTO
    ) -> TransactionTemplateDTO {
        let newPattern = RecurrencePattern(from: transaction.date, period: template.recurrencePattern.period, calendar: transaction.timeContext.calendar)
        let nextDueDate = newPattern.calculateNextOccurrence() ?? template.nextDueDate

        return TransactionTemplateDTO(
            id: template.id,
            amount: transaction.amount,
            place: transaction.place,
            memo: transaction.memo,
            transactionType: transaction.transactionType,
            recurrencePeriod: template.recurrencePeriod,
            createdAt: template.createdAt,
            lastAddedAt: template.lastAddedAt,
            nextDueDate: nextDueDate,
            timeContext: template.timeContext,
            subCategory: transaction.subCategory,
            paymentMethod: transaction.paymentMethod,
            recurrencePattern: newPattern,
            executionState: template.executionState
        )
    }
}

// MARK: - Error Types

enum TransactionUpdateError: Error {
    case invalidAmount
    case transactionNotFound
}
