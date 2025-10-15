//
//  CreateTransactionTemplateUseCaseImpl.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/24/25.
//

import Foundation

final class CreateTransactionTemplateUseCaseImpl: CreateTransactionTemplateUseCase {
    private let templateWriter: TransactionTemplateWriter

    init(templateWriter: TransactionTemplateWriter) {
        self.templateWriter = templateWriter
    }

    func execute(_ template: TransactionTemplateDTO) async throws {
        // 비즈니스 로직 검증: 금액 유효성 검사
        guard template.amount > 0 else {
            throw TransactionTemplateCreationError.invalidAmount
        }

        // 반복 패턴 유효성 검사
        guard template.recurrencePattern.isValid else {
            throw TransactionTemplateCreationError.invalidRecurrencePattern
        }

        // nextDueDate 계산 (실행 상태를 기반으로 산출)
        let calculatedNextDueDate = template.calculatedNextDueDate
        
        // nextDueDate가 업데이트된 템플릿 생성
        let updatedTemplate = TransactionTemplateDTO(
            id: template.id,
            amount: template.amount,
            place: template.place,
            memo: template.memo,
            transactionType: template.transactionType,
            recurrencePeriod: template.recurrencePeriod,
            createdAt: template.createdAt,
            lastAddedAt: template.lastAddedAt,
            nextDueDate: calculatedNextDueDate,
            timeContext: template.timeContext,
            subCategory: template.subCategory,
            paymentMethod: template.paymentMethod,
            recurrencePattern: template.recurrencePattern,
            executionState: template.executionState
        )

        // 템플릿 저장
        try await templateWriter.insertTemplate(updatedTemplate, shouldSave: true)
    }
}

// MARK: - Error Types

enum TransactionTemplateCreationError: Error {
    case invalidAmount
    case invalidRecurrencePattern
    case templateWriterNotAvailable

    var localizedDescription: String {
        switch self {
        case .invalidAmount:
            return "금액이 유효하지 않습니다."
        case .invalidRecurrencePattern:
            return "반복 패턴이 유효하지 않습니다."
        case .templateWriterNotAvailable:
            return "템플릿 저장 기능을 사용할 수 없습니다."
        }
    }
}
