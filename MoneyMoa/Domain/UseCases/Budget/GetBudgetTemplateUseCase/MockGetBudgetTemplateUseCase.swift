//
//  MockGetBudgetTemplateUseCase.swift
//  MoneyMoa
//
//  Created by Claude on 8/4/25.
//

import Foundation

// MARK: - MockGetBudgetTemplateUseCase

public final class MockGetBudgetTemplateUseCase: GetBudgetTemplateUseCase {
    
    // MARK: - Mock Configuration
    
    /// Mock 템플릿 존재 여부
    public var hasTemplate: Bool = true
    
    /// Mock 템플릿 데이터
    public var mockTemplate: BudgetTemplateDTO?
    
    /// Mock 딜레이 시뮬레이션 (나노초)
    public var mockDelay: UInt64 = 50_000_000 // 0.05초
    
    // MARK: - Initialization
    
    public init() {
        setupDefaultMockTemplate()
    }
    
    // MARK: - UseCase Implementation
    
    public func execute() async throws -> BudgetTemplateDTO? {
        // Mock 딜레이 시뮬레이션
        try await Task.sleep(nanoseconds: mockDelay)
        
        return hasTemplate ? mockTemplate : nil
    }
    
    // MARK: - Mock Configuration Methods
    
    /// Mock 템플릿을 설정합니다
    public func setMockTemplate(_ template: BudgetTemplateDTO?) {
        mockTemplate = template
        hasTemplate = template != nil
    }
    
    /// 템플릿 없음 시나리오로 설정합니다
    public func configureNoTemplateScenario() {
        hasTemplate = false
        mockTemplate = nil
    }
    
    /// 템플릿 있음 시나리오로 설정합니다
    public func configureHasTemplateScenario() {
        hasTemplate = true
        setupDefaultMockTemplate()
    }
    
    /// Mock 딜레이를 설정합니다
    public func setMockDelay(nanoseconds: UInt64) {
        mockDelay = nanoseconds
    }
    
    // MARK: - Private Helper Methods
    
    /// 기본 Mock 템플릿을 설정합니다
    private func setupDefaultMockTemplate() {
        mockTemplate = .mockStandard
    }
}
