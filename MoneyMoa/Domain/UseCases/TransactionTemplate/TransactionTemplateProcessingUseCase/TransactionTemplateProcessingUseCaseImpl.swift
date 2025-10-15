//
//  ProcessDueTemplatesUseCaseImpl.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/16/25.
//

import Foundation

// MARK: - Implementation

public final class TransactionTemplateProcessingUseCaseImpl: TransactionTemplateProcessingUseCase {

    private let templateRepository: TransactionTemplateRepository
    private let transactionWriter: TransactionWriter

    public init(
        templateRepository: TransactionTemplateRepository,
        transactionWriter: TransactionWriter
    ) {
        self.templateRepository = templateRepository
        self.transactionWriter = transactionWriter
    }

    public func execute(upToDate: Date = Date()) async throws -> Int {
        // 처리 예정인 템플릿들 조회
        let dueTemplates = try await templateRepository.fetchTemplatesDueForProcessing(before: upToDate)

        var totalProcessedCount = 0

        for template in dueTemplates {
            do {
                // RecurrenceCalculator를 사용하여 발생일들 계산
                let dueOccurrences = template.getDueOccurrences(upToDate: upToDate)

                guard !dueOccurrences.isEmpty else {
                    continue
                }

                // 발생일별로 Transaction 생성
                for occurrenceDate in dueOccurrences {
                    let transaction = template.toTransaction(date: occurrenceDate)
                    try await transactionWriter.insertTransaction(transaction, shouldSave: true)
                    totalProcessedCount += 1
                }

                // 템플릿 상태 업데이트 (마지막 실행일로 기록)
                let lastExecutionDate = dueOccurrences.last ?? upToDate
                let updatedTemplate = template.recordExecution(at: lastExecutionDate)

                try await templateRepository.updateTemplateProcessing(
                    id: template.id,
                    executionState: updatedTemplate.executionState,
                    lastAddedAt: lastExecutionDate,
                    nextDueDate: updatedTemplate.calculatedNextDueDate
                )

            } catch {
                // 개별 템플릿 처리 실패는 로그만 남기고 계속 진행
                print("Failed to process template \(template.id): \(error)")
                continue
            }
        }

        return totalProcessedCount
    }

    // MARK: - Private Helpers

    // RecurrenceCalculator를 사용하므로 별도의 helper 메서드 불필요
}
