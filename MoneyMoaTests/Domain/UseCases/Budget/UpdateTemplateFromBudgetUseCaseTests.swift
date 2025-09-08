//
//  UpdateTemplateFromBudgetUseCaseTests.swift
//  MoneyMoaTests
//
//  Created by Claude Code on 9/8/25.
//

import Testing
import Foundation
@testable import MoneyMoa

@Suite("UpdateTemplateFromBudgetUseCase Tests")
struct UpdateTemplateFromBudgetUseCaseTests {
    
    // MARK: - Test Components
    
    private func makeMockDIContainer() -> MockDIContainer {
        return MockDIContainer()
    }
    
    private func makeUpdateTemplateFromBudgetUseCase(container: MockDIContainer) -> UpdateTemplateFromBudgetUseCase {
        return container.makeUpdateBudgetTemplateUseCase()
    }
    
    // MARK: - Core Tests
    
    @Test("예산으로 템플릿 업데이트 - Repository 메서드 호출 확인")
    func testExecute_callsRepositoryUpdateMethod() async throws {
        // Given
        let container = makeMockDIContainer()
        let useCase = makeUpdateTemplateFromBudgetUseCase(container: container)
        let mockRepository = container.mockBudgetTemplateRepository
        mockRepository.loadScenario(.lowIncome)

        let budget = BudgetFactory.normal()
        
        // When
        try await useCase.execute(budget)
        
        // Then - 에러 없이 실행 완료 확인
        #expect(mockRepository.hasTemplate == true)
        #expect(mockRepository.currentTemplate?.totalAmount == budget.totalAmount)
    }
    
    @Test("Repository 에러 발생 시 에러 전파")
    func testExecute_whenRepositoryThrowsError_shouldPropagateError() async throws {
        // Given
        let container = makeMockDIContainer()
        let useCase = makeUpdateTemplateFromBudgetUseCase(container: container)
        let mockRepository = container.mockBudgetTemplateRepository
        
        // Repository가 에러를 던지도록 설정
        mockRepository.shouldFail = true
        mockRepository.errorToThrow = MockError.simulatedFailure
        
        let budget = BudgetFactory.normal()
        
        // When & Then
        do {
            try await useCase.execute(budget)
            #expect(Bool(false), "Should have thrown an error")
        } catch {
            #expect(error is MockError)
        }
    }
}
