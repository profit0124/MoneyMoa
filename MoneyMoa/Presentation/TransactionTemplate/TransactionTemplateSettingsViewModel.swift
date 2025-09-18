//
//  TransactionTemplateSettingsViewModel.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/18/25.
//

import Foundation

@Observable
final class TransactionTemplateSettingsViewModel {
    var templates: [TransactionTemplateDTO] = []
    var showingAddTemplate = false
    var templateToEdit: TransactionTemplateDTO?
    var templateToDelete: TransactionTemplateDTO?
    var showDeleteAlert = false

    enum Action {
        case onAppear
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear:
            onAppear()
        }
    }

    private func onAppear() {
        Task {
            do {
                templates = try await MockDIContainer(configuration: .realistic).mockTransactionTemplateRepository.fetchAllTemplates()
            } catch {

            }
        }
    }
}
