//
//  TransactionTemplateSettingsViewModelTests.swift
//  MoneyMoaTests
//
//  Created by Sooik Kim on 10/15/25.
//

import Testing
import Foundation
import Combine
@testable import MoneyMoa

@MainActor
struct TransactionTemplateSettingsVMTests {

    private func makeViewModel(
        fetchUseCase: StubFetchTemplatesUseCase,
        deleteUseCase: SpyDeleteTemplateUseCase,
        eventPublisher: TestTransactionTemplateEventPublisher
    ) -> TransactionTemplateSettingsViewModel {
        TransactionTemplateSettingsViewModel(
            transactionTemplateEventPublisher: eventPublisher,
            fetchTemplatesUseCase: fetchUseCase,
            deleteTemplateUseCase: deleteUseCase
        )
    }

    @Test("onAppear 호출 시 템플릿을 로드한다")
    func testOnAppearLoadsTemplates() async throws {
        // Given
        let template = TestDataFactory.createTransactionTemplate(
            amount: 10_000,
            subCategory: .mockFoodExpense,
            paymentMethod: .mockCreditCard
        )
        let fetchUseCase = StubFetchTemplatesUseCase(result: .success([template]))
        let deleteUseCase = SpyDeleteTemplateUseCase()
        let eventPublisher = TestTransactionTemplateEventPublisher()
        let viewModel = makeViewModel(fetchUseCase: fetchUseCase, deleteUseCase: deleteUseCase, eventPublisher: eventPublisher)

        // When
        viewModel.send(.onAppear)
        try await Task.sleep(for: .milliseconds(30))

        // Then
        #expect(fetchUseCase.executeCallCount == 1)
        #expect(viewModel.templates == [template])
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isLoading == false)
    }

    @Test("onAppear 실패 시 에러 메시지를 설정한다")
    func testOnAppearFailureSetsErrorMessage() async throws {
        // Given
        let fetchUseCase = StubFetchTemplatesUseCase(result: .failure(StubError.fetchFailed))
        let deleteUseCase = SpyDeleteTemplateUseCase()
        let eventPublisher = TestTransactionTemplateEventPublisher()
        let viewModel = makeViewModel(fetchUseCase: fetchUseCase, deleteUseCase: deleteUseCase, eventPublisher: eventPublisher)

        // When
        viewModel.send(.onAppear)
        try await Task.sleep(for: .milliseconds(30))

        // Then
        #expect(fetchUseCase.executeCallCount == 1)
        #expect(viewModel.templates.isEmpty)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isLoading == false)
    }

    @Test("템플릿 이벤트가 발생하면 목록을 다시 로드한다")
    func testEventPublisherTriggersReload() async throws {
        // Given
        let initialTemplate = TestDataFactory.createTransactionTemplate(
            amount: 5_000,
            subCategory: .mockFoodExpense,
            paymentMethod: .mockCreditCard
        )
        let updatedTemplate = TestDataFactory.createTransactionTemplate(
            amount: 12_000,
            subCategory: .mockFoodExpense,
            paymentMethod: .mockCreditCard
        )

        let fetchUseCase = StubFetchTemplatesUseCase(result: .success([initialTemplate]))
        let deleteUseCase = SpyDeleteTemplateUseCase()
        let eventPublisher = TestTransactionTemplateEventPublisher()
        let viewModel = makeViewModel(fetchUseCase: fetchUseCase, deleteUseCase: deleteUseCase, eventPublisher: eventPublisher)

        viewModel.send(.onAppear)
        try await Task.sleep(for: .milliseconds(30))

        // When
        fetchUseCase.result = .success([updatedTemplate])
        eventPublisher.publish(TransactionTemplateEvent(type: .updated, template: updatedTemplate))
        try await Task.sleep(for: .milliseconds(30))

        // Then
        #expect(fetchUseCase.executeCallCount == 2)
        #expect(viewModel.templates == [updatedTemplate])
    }

    @Test("삭제 흐름이 성공적으로 완료된다")
    func testDeleteTemplateFlow() async throws {
        // Given
        let template = TestDataFactory.createTransactionTemplate(
            subCategory: .mockFoodExpense,
            paymentMethod: .mockCreditCard
        )
        let fetchUseCase = StubFetchTemplatesUseCase(result: .success([template]))
        let deleteUseCase = SpyDeleteTemplateUseCase()
        let eventPublisher = TestTransactionTemplateEventPublisher()
        let viewModel = makeViewModel(fetchUseCase: fetchUseCase, deleteUseCase: deleteUseCase, eventPublisher: eventPublisher)

        // 목록을 로드해 상태 초기화
        viewModel.send(.onAppear)
        try await Task.sleep(for: .milliseconds(30))

        // When
        viewModel.send(.deleteTemplate(template))

        // Then
        #expect(viewModel.showDeleteAlert)
        #expect(viewModel.templateToDelete == template)

        // When
        viewModel.send(.confirmDelete)
        try await Task.sleep(for: .milliseconds(30))

        // Then
        #expect(deleteUseCase.executeCallCount == 1)
        #expect(deleteUseCase.lastDeletedId == template.id)
        #expect(fetchUseCase.executeCallCount == 2)

        let event = try #require(eventPublisher.publishedEvents.first)
        #expect(event.type == .deleted)
        #expect(event.template.id == template.id)

        #expect(viewModel.templateToDelete == nil)
        #expect(viewModel.showDeleteAlert == false)
    }

    @Test("삭제 취소 시 상태가 초기화된다")
    func testCancelDeleteResetsState() async throws {
        // Given
        let template = TestDataFactory.createTransactionTemplate(
            subCategory: .mockFoodExpense,
            paymentMethod: .mockCreditCard
        )
        let fetchUseCase = StubFetchTemplatesUseCase(result: .success([template]))
        let deleteUseCase = SpyDeleteTemplateUseCase()
        let eventPublisher = TestTransactionTemplateEventPublisher()
        let viewModel = makeViewModel(fetchUseCase: fetchUseCase, deleteUseCase: deleteUseCase, eventPublisher: eventPublisher)

        viewModel.send(.onAppear)
        try await Task.sleep(for: .milliseconds(20))
        fetchUseCase.result = .success([template])

        viewModel.send(.deleteTemplate(template))

        // When
        viewModel.send(.cancelDelete)

        // Then
        #expect(viewModel.templateToDelete == nil)
        #expect(viewModel.showDeleteAlert == false)
    }
}

// MARK: - Test Doubles

private enum StubError: Error {
    case fetchFailed
}

@MainActor
private final class StubFetchTemplatesUseCase: FetchTransactionTemplatesUseCase {
    var executeCallCount = 0
    var result: Result<[TransactionTemplateDTO], Error>

    init(result: Result<[TransactionTemplateDTO], Error>) {
        self.result = result
    }

    func execute(with period: RecurrencePeriod?) async throws -> [TransactionTemplateDTO] {
        executeCallCount += 1
        switch result {
        case .success(let templates):
            return templates
        case .failure(let error):
            throw error
        }
    }
}

@MainActor
private final class SpyDeleteTemplateUseCase: DeleteTransactionTemplateUseCase {
    private(set) var executeCallCount = 0
    private(set) var lastDeletedId: UUID?
    var error: Error?

    func execute(templateId: UUID) async throws {
        executeCallCount += 1
        if let error { throw error }
        lastDeletedId = templateId
    }
}
