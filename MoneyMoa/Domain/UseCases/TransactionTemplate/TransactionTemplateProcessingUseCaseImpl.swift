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
                // 몇 번의 Transaction을 생성해야 하는지 계산
                let missedOccurrences = calculateMissedOccurrences(
                    template: template,
                    upToDate: upToDate
                )

                // 누락된 만큼 Transaction들 생성
                for i in 0..<missedOccurrences {
                    let occurrenceDate = template.recurrencePeriod.calculateOccurenceDate(
                        from: template.createdAt,
                        processCount: template.processedCount + i
                    ) ?? upToDate

                    let transaction = template.toTransaction(date: occurrenceDate)
                    try await transactionWriter.insertTransaction(transaction)
                    totalProcessedCount += 1
                }

                // 템플릿 처리 상태 업데이트
                let newProcessedCount = template.processedCount + missedOccurrences
                let lastOccurrenceDate = template.recurrencePeriod.calculateOccurenceDate(
                    from: template.createdAt,
                    processCount: newProcessedCount - 1
                ) ?? upToDate

                let nextDueDate = template.recurrencePeriod.calculateOccurenceDate(
                    from: template.createdAt,
                    processCount: newProcessedCount
                )

                try await templateRepository.updateTemplateProcessing(
                    id: template.id,
                    processedCount: newProcessedCount,
                    lastAddedAt: lastOccurrenceDate,
                    nextDueDate: nextDueDate
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

    /// 현재 시점까지 누락된 처리 횟수 계산
    private func calculateMissedOccurrences(
        template: TransactionTemplateDTO,
        upToDate: Date
    ) -> Int {
        guard let nextDueDate = template.nextDueDate else { return 0 }
        guard nextDueDate <= upToDate else { return 0 }

        let calendar = template.timeContext.calendar
        let createdAt = template.createdAt

        switch template.recurrencePeriod {
        case .none:
            return 0

        case .weekly:
            // nextDueDate와 upToDate 사이의 날짜 차이 계산
            let daysDifference = calendar.dateComponents([.day], from: nextDueDate, to: upToDate).day ?? 0
            // 몇 주인지 계산 (올림: 1일이라도 지나면 1주로 카운트)
            let weeksPassed = (daysDifference / 7) + (daysDifference % 7 > 0 ? 1 : 0)
            return max(0, weeksPassed)

        case .monthly:
            // createdAt에서 upToDate까지 총 몇 개월 지났는지 계산
            let totalMonthsPassed = monthsAheadForRecurrence(from: createdAt, to: upToDate, calendar: calendar)
            // 전체 기대 횟수에서 이미 처리된 횟수를 뺌
            let totalExpectedCount = totalMonthsPassed + 1 // +1은 첫 번째 달 포함
            return max(0, totalExpectedCount - template.processedCount)

        case .yearly:
            // createdAt에서 upToDate까지 총 몇 년 지났는지 계산
            let totalYearsPassed = yearsAheadForRecurrence(from: createdAt, to: upToDate, calendar: calendar)
            // 전체 기대 횟수에서 이미 처리된 횟수를 뺌
            let totalExpectedCount = totalYearsPassed + 1 // +1은 첫 번째 년 포함
            return max(0, totalExpectedCount - template.processedCount)
        }
    }

    /// 'from'에서 'to'가 몇 개월 뒤인지(스케줄 의미, 앵커 고정)
    /// - 규칙: m = (연*12+월 차이), candidate = from + m개월
    ///         candidate > to 이면 m -= 1
    private func monthsAheadForRecurrence(from: Date, to: Date, calendar: Calendar) -> Int {
        let f = calendar.dateComponents([.year, .month], from: from)
        let t = calendar.dateComponents([.year, .month], from: to)

        guard let fromYear = f.year, let fromMonth = f.month,
              let toYear = t.year, let toMonth = t.month else {
            return 0
        }

        var m = (toYear - fromYear) * 12 + (toMonth - fromMonth)
        if let candidate = calendar.date(byAdding: .month, value: m, to: from),
           candidate > to {
            m -= 1
        }
        return max(0, m)
    }

    /// 'from'에서 'to'가 몇 년 뒤인지(스케줄 의미, 앵커 고정)
    /// - 규칙: y = (년 차이), candidate = from + y년
    ///         candidate > to 이면 y -= 1
    private func yearsAheadForRecurrence(from: Date, to: Date, calendar: Calendar) -> Int {
        let f = calendar.dateComponents([.year], from: from)
        let t = calendar.dateComponents([.year], from: to)

        guard let fromYear = f.year, let toYear = t.year else {
            return 0
        }

        var y = toYear - fromYear
        if let candidate = calendar.date(byAdding: .year, value: y, to: from),
           candidate > to {
            y -= 1
        }
        return max(0, y)
    }
}
