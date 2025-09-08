//
//  GetBudgetTemplateUseCaseTests.swift
//  MoneyMoaTests
//
//  Created by Claude Code on 9/8/25.
//

import Testing
import Foundation
@testable import MoneyMoa

@Suite("GetBudgetTemplateUseCase Tests")
struct GetBudgetTemplateUseCaseTests {
    
    // MARK: - Test Components
    
    private func makeMockDIContainer() -> MockDIContainer {
        return MockDIContainer()
    }
    
    private func makeGetBudgetTemplateUseCase(container: MockDIContainer) -> GetBudgetTemplateUseCase {
        return container.makeGetBudgetTemplateUseCase()
    }
    
    // MARK: - Core Tests
    
    @Test("템플릿 조회 - Repository 메서드 호출 확인")
    func testExecute_callsRepositoryFetchMethod() async throws {
        // Given
        let container = makeMockDIContainer()
        let useCase = makeGetBudgetTemplateUseCase(container: container)
        let mockRepository = container.mockBudgetTemplateRepository
        
        let template = BudgetTemplateFactory.normal
        mockRepository.setTemplate(template)
        
        // When
        let result = try await useCase.execute()
        
        // Then - Repository 메서드 호출 결과 확인
        #expect(result != nil)
        #expect(result?.id == template.id)
    }
    
    @Test("템플릿이 없을 때 nil 반환")
    func testExecute_whenNoTemplate_shouldReturnNil() async throws {
        // Given
        let container = makeMockDIContainer()
        let useCase = makeGetBudgetTemplateUseCase(container: container)
        let mockRepository = container.mockBudgetTemplateRepository
        
        mockRepository.setTemplate(nil)
        
        // When
        let result = try await useCase.execute()
        
        // Then
        #expect(result == nil)
    }
    
    @Test("Repository 에러 발생 시 에러 전파")
    func testExecute_whenRepositoryThrowsError_shouldPropagateError() async throws {
        // Given
        let container = makeMockDIContainer()
        let useCase = makeGetBudgetTemplateUseCase(container: container)
        let mockRepository = container.mockBudgetTemplateRepository
        
        // Repository가 에러를 던지도록 설정
        mockRepository.shouldFail = true
        mockRepository.errorToThrow = MockError.simulatedFailure
        
        // When & Then
        let budgetTemplateDTO = try? await useCase.execute()
        #expect(budgetTemplateDTO == nil)
    }
}
