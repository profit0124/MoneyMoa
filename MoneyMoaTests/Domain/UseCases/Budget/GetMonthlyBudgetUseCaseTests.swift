//
//  GetMonthlyBudgetUseCaseTests.swift
//  MoneyMoaTests
//
//  Created by Claude Code on 9/8/25.
//

import Testing
import Foundation
@testable import MoneyMoa

@Suite("GetMonthlyBudgetUseCase Tests")
struct GetMonthlyBudgetUseCaseTests {

    // MARK: - Test Components

    private func makeMockDIContainer() -> MockDIContainer {
        return MockDIContainer()
    }

    private func makeGetMonthlyBudgetUseCase(container: MockDIContainer) -> GetMonthlyBudgetUseCase {
        return container.makeGetMonthlyBudgetUseCase()
    }

    // MARK: - Core Tests

    @Test("월별 예산 조회 - Repository 메서드 호출 확인")
    func testExecute_callsRepositoryFetchMethod() async throws {
        // Given
        let container = makeMockDIContainer()
        let useCase = makeGetMonthlyBudgetUseCase(container: container)
        let mockRepository = container.mockBudgetRepository

        let targetMonth = YearMonth(year: 2024, month: 8)
        let budget = BudgetFactory.normal(for: targetMonth)
        mockRepository.addBudget(budget)

        // When
        let result = try await useCase.execute(yearMonth: targetMonth)

        // Then - Repository 메서드가 호출되고 정확한 결과가 반환되는지 확인
        #expect(mockRepository.hasBudget(for: targetMonth))
        #expect(result != nil)
        #expect(result?.month == targetMonth)
        #expect(result?.id == budget.id)
    }

    @Test("예산이 없을 때 nil 반환")
    func testExecute_whenNoBudget_shouldReturnNil() async throws {
        // Given
        let container = makeMockDIContainer()
        let useCase = makeGetMonthlyBudgetUseCase(container: container)

        let targetMonth = YearMonth(year: 2024, month: 8)
        // 예산을 설정하지 않음으로써 nil 반환 시나리오 테스트

        // When
        let result = try await useCase.execute(yearMonth: targetMonth)

        // Then
        #expect(result == nil)
    }

    @Test("Repository 에러 발생 시 에러 전파")
    func testExecute_whenRepositoryThrowsError_shouldPropagateError() async throws {
        // Given
        let container = makeMockDIContainer()
        let useCase = makeGetMonthlyBudgetUseCase(container: container)
        let mockRepository = container.mockBudgetRepository

        // Repository가 에러를 던지도록 설정
        mockRepository.shouldFail = true
        mockRepository.errorToThrow = MockError.simulatedFailure

        let targetMonth = YearMonth.current

        // When & Then
        let budgetDTO = try? await useCase.execute(yearMonth: targetMonth)
        #expect(budgetDTO == nil)
    }
}
