//
//  TransactionTemplateSettingsViewModel.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/18/25.
//

import Foundation

@Observable
final class TransactionTemplateSettingsViewModel {
    private(set) var templates: [TransactionTemplateDTO] = []
    var showingAddTemplate = false
    var templateToEdit: TransactionTemplateDTO?
    private(set) var templateToDelete: TransactionTemplateDTO?
    var showDeleteAlert = false
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let fetchTemplatesUseCase: FetchTransactionTemplatesUseCase
    private let deleteTemplateUseCase: DeleteTransactionTemplateUseCase

    init(
        fetchTemplatesUseCase: FetchTransactionTemplatesUseCase,
        deleteTemplateUseCase: DeleteTransactionTemplateUseCase
    ) {
        self.fetchTemplatesUseCase = fetchTemplatesUseCase
        self.deleteTemplateUseCase = deleteTemplateUseCase
    }

    enum Action {
        case onAppear
        case deleteTemplate(TransactionTemplateDTO)
        case confirmDelete
        case cancelDelete
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear:
            loadTemplates()
        case .deleteTemplate(let template):
            templateToDelete = template
            showDeleteAlert = true
        case .confirmDelete:
            deleteTemplate()
        case .cancelDelete:
            templateToDelete = nil
            showDeleteAlert = false
        }
    }

    private func loadTemplates() {
        Task { @MainActor in
            isLoading = true
            errorMessage = nil

            defer {
                isLoading = false
            }

            do {
                templates = try await fetchTemplatesUseCase.execute(with: nil)
            } catch {
                errorMessage = "템플릿을 불러오는데 실패했습니다: \(error.localizedDescription)"
            }
        }
    }

    private func deleteTemplate() {
        Task { @MainActor in
            if let templateToDelete {
                do {
                    try await deleteTemplateUseCase.execute(templateId: templateToDelete.id)
                    self.loadTemplates()
                    self.templateToDelete = nil
                    showDeleteAlert = false
                } catch {
                    errorMessage = "템플릿 삭제에 실패했습니다: \(error.localizedDescription)"
                    self.templateToDelete = nil
                    showDeleteAlert = false
                }
            }
        }
    }
}
