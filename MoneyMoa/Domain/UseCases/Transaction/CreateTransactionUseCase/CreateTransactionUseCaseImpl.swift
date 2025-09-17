//
//  CreateTransactionUseCaseImpl.swift
//  MoneyMoa
//
//  Created by profit on 8/11/25.
//

import Foundation

final class CreateTransactionUseCaseImpl: CreateTransactionUseCase {
    private let transactionWriter: TransactionWriter
    private let templateWriter: TransactionTemplateWriter

    init(
        transactionWriter: TransactionWriter,
        templateWriter: TransactionTemplateWriter

    ) {
        self.transactionWriter = transactionWriter
        self.templateWriter = templateWriter
    }

    func execute(_ transaction: TransactionDTO, with recurrencePeriod: RecurrencePeriod? = nil) async throws {
        // 비즈니스 로직 검증: 금액 유효성 검사
        guard transaction.amount > 0 else {
            throw TransactionCreationError.invalidAmount
        }

        var transaction = transaction
        if let recurrencePeriod {
            let template = transaction.toTemplateDTO(recurrencePeriod: recurrencePeriod)
            try await templateWriter.insertTemplate(template, shouldSave: false)
            transaction = addTemplateToTransaction(transaction, template)
        }
        
        try await transactionWriter.insertTransaction(transaction, shouldSave: true)
    }

    private func addTemplateToTransaction(_ transaction: TransactionDTO, _ template: TransactionTemplateDTO) -> TransactionDTO {
        return TransactionDTO(
            id: transaction.id,
            amount: transaction.amount,
            date: transaction.date,  // 로컬 시간으로 변환된 값
            place: transaction.place,
            memo: transaction.memo,
            transactionType: transaction.transactionType,
            subCategory: transaction.subCategory,
            paymentMethod: transaction.paymentMethod,
            timeContext: transaction.timeContext,
            transactionTemplate: template
        )
    }
}

// MARK: - Error Types

enum TransactionCreationError: Error {
    case invalidAmount
    case templateWriterNotAvailable
}
