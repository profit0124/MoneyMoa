//
//  CreateTemplateFromBudgetUseCaseTests.swift
//  MoneyMoaTests
//
//  Created by Claude Code on 9/8/25.
//

import Testing
import Foundation
@testable import MoneyMoa

@Suite("CreateTemplateFromBudgetUseCase Tests")
struct CreateTemplateFromBudgetUseCaseTests {
    
    // MARK: - Test Components
    
    private func makeMockDIContainer() -> MockDIContainer {
        return MockDIContainer()
    }
    
    private func makeCreateTemplateFromBudgetUseCase(container: MockDIContainer) -> CreateTemplateFromBudgetUseCase {
        return container.makeCreateBudgetTemplateUseCase()
    }
    
    // MARK: - Core Tests
    
    @Test("예산으로 템플릿 생성 - Repository 메서드 호출 확인")
    func testExecute_callsRepositoryCreateMethod() async throws {
        // Given
        let container = makeMockDIContainer()
        let useCase = makeCreateTemplateFromBudgetUseCase(container: container)
        let mockRepository = container.mockBudgetTemplateRepository
        
        let budget = BudgetFactory.normal()
        
        // When
        try await useCase.execute(budget)
        
        // Then - 에러 없이 실행 완료 확인
        #expect(mockRepository.hasTemplate) // 템플릿이 생성되었는지 확인
    }
    
    @Test("Repository 에러 발생 시 에러 전파")
    func testExecute_whenRepositoryThrowsError_shouldPropagateError() async throws {
        // Given
        let container = makeMockDIContainer()
        let useCase = makeCreateTemplateFromBudgetUseCase(container: container)
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
    
    @Test("BudgetDTO가 BudgetTemplateDTO로 변환되어 전달")
    func testExecute_convertsAndPassesBudgetAsTemplate() async throws {
        // Given
        let container = makeMockDIContainer()
        let useCase = makeCreateTemplateFromBudgetUseCase(container: container)
        let mockRepository = container.mockBudgetTemplateRepository
        
        let budget = BudgetFactory.normal()
        let expectedTemplate = budget.toBudgetTemplateDTO()
        
        // When
        try await useCase.execute(budget)
        
        // Then - 변환된 템플릿이 repository에 전달되었는지 확인
        let createdTemplate = mockRepository.currentTemplate
        #expect(createdTemplate != nil)
        #expect(createdTemplate?.totalAmount == expectedTemplate.totalAmount)
        #expect(createdTemplate?.categoryBudgetTemplates.count == expectedTemplate.categoryBudgetTemplates.count)
    }
}
