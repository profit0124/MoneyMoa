//
//  DeleteTransactionTemplateUseCaseImpl.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/18/25.
//

import Foundation

final class DeleteTransactionTemplateUseCaseImpl: DeleteTransactionTemplateUseCase {
    private let templateWriter: TransactionTemplateWriter

    init(templateWriter: TransactionTemplateWriter) {
        self.templateWriter = templateWriter
    }

    func execute(templateId: UUID) async throws {
        try await templateWriter.deleteTemplate(id: templateId)
    }
}
