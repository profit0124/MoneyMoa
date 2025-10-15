//
//  FetchTransactionTemplatesUseCaseImpl.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/18/25.
//

import Foundation

public class FetchTransactionTemplatesUseCaseImpl: FetchTransactionTemplatesUseCase {
    private let templateReader: TransactionTemplateReader

    public init(templateReader: TransactionTemplateReader) {
        self.templateReader = templateReader
    }

    // MARK: - UseCase Methods

    public func execute(with period: RecurrencePeriod? = nil) async throws -> [TransactionTemplateDTO] {
        if let period {
            return try await templateReader.fetchTemplatesByRecurrencePeriod(period)
        } else {
            return try await templateReader.fetchAllTemplates()
        }
    }
}
