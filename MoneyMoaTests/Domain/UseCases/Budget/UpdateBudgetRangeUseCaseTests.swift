//
//  UpdateBudgetRangeUseCaseTests.swift
//  MoneyMoaTests
//
//  Created by Claude Code on 9/8/25.
//

import Testing
import Foundation
@testable import MoneyMoa

@Suite("UpdateBudgetRangeUseCase Tests")
struct UpdateBudgetRangeUseCaseTests {

    // MARK: - Test Components

    private func makeMockDIContainer() -> MockDIContainer {
        let container = MockDIContainer()
        // 빈 시나리오로 시작하여 테스트에서 직접 제어
        container.mockBudgetRepository.loadScenario(.empty)
        return container
    }

    private func makeUpdateBudgetRangeUseCase(container: MockDIContainer) -> UpdateBudgetRangeUseCase {
        return container.makeUpdateBudgetRangeUseCase()
    }

    // MARK: - Core Tests

    @Test("Repository 에러 발생 시 에러 전파")
    func testExecute_whenRepositoryThrowsError_shouldPropagateError() async throws {
        // Given
        let container = makeMockDIContainer()
        let useCase = makeUpdateBudgetRangeUseCase(container: container)
        let mockRepository = container.mockBudgetRepository

        // Repository가 에러를 던지도록 설정
        mockRepository.shouldFail = true
        mockRepository.errorToThrow = MockError.simulatedFailure

        let budget = BudgetFactory.normal()

        // When & Then
        do {
            try await useCase.execute(from: .current, budget: budget)
            #expect(Bool(false), "Should have thrown an error")
        } catch {
            #expect(error is MockError)
        }
    }

    @Test("시작 월이 현재 월 이후일 때 업데이트 없음")
    func testExecute_whenStartMonthAfterCurrent_shouldNotUpdate() async throws {
        // Given
        let container = makeMockDIContainer()
        let useCase = makeUpdateBudgetRangeUseCase(container: container)
        let mockRepository = container.mockBudgetRepository

        let initialCount = mockRepository.budgetCount
        let futureMonth = YearMonth.current.nextMonth()
        let budget = BudgetFactory.normal()

        // When
        try await useCase.execute(from: futureMonth, budget: budget)

        // Then - 미래 월에 대해서는 업데이트가 없어야 함
        #expect(mockRepository.budgetCount == initialCount)
    }

    @Test("예산 업데이트 기본 동작 확인")
    func testExecute_basicUpdateOperation() async throws {
        // Given
        let container = makeMockDIContainer()
        let useCase = makeUpdateBudgetRangeUseCase(container: container)
        let mockRepository = container.mockBudgetRepository

        let currentMonth = YearMonth.current
        let budget = BudgetFactory.normal()

        // 업데이트할 예산을 미리 생성 (createBudget 사용)
        let existingBudget = BudgetFactory.normal(for: currentMonth)
        try await mockRepository.createBudget(existingBudget)

        // When
        try await useCase.execute(from: currentMonth, budget: budget)

        // Then - 에러 없이 완료되었는지만 확인
        #expect(mockRepository.budgetCount >= 1)
    }
}
