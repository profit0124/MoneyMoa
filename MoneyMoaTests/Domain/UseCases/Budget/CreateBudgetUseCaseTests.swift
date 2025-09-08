//
//  CreateBudgetUseCaseTests.swift
//  MoneyMoaTests
//
//  Created by Claude Code on 9/8/25.
//

import Testing
import Foundation
@testable import MoneyMoa

@Suite("CreateBudgetUseCase Tests")
struct CreateBudgetUseCaseTests {
    
    // MARK: - Test Components
    
    private func makeMockDIContainer() -> MockDIContainer {
        return MockDIContainer()
    }
    
    private func makeCreateBudgetUseCase(container: MockDIContainer) -> CreateBudgetUseCase {
        return container.makeCreateBudgetUseCase()
    }
    
    // MARK: - Success Tests
    
    @Test("정상적인 예산 생성")
    func testCreateBudget_Success() async throws {
        // Given
        let container = makeMockDIContainer()
        let useCase = makeCreateBudgetUseCase(container: container)
        let mockRepository = container.mockBudgetRepository
        
        let budget = BudgetFactory.normal(for: YearMonth(year: 2024, month: 8))
        
        // When
        let result = try await useCase.execute(budget)
        
        // Then
        #expect(result.id == budget.id)
        #expect(result.month == budget.month)
        #expect(result.totalAmount == budget.totalAmount)
        #expect(result.categoryBudgets.count == budget.categoryBudgets.count)
        
        // Repository에 저장되었는지 확인
        #expect(mockRepository.hasBudget(for: budget.month))
        #expect(mockRepository.budgetCount == 1)
    }
    
    @Test("카테고리 예산이 포함된 예산 생성")
    func testCreateBudgetWithCategoryBudgets_Success() async throws {
        // Given
        let container = makeMockDIContainer()
        let useCase = makeCreateBudgetUseCase(container: container)
        let mockRepository = container.mockBudgetRepository
        
        let budget = BudgetFactory.createRealistic(for: YearMonth.current)
        
        // When
        let result = try await useCase.execute(budget)
        
        // Then
        #expect(result.totalAmount == budget.totalAmount)
        #expect(result.categoryBudgets.count == budget.categoryBudgets.count)
        
        // 카테고리 예산이 올바르게 복사되었는지 확인
        for (original, created) in zip(budget.categoryBudgets, result.categoryBudgets) {
            #expect(created.amount == original.amount)
            #expect(created.categoryID == original.categoryID)
            #expect(created.categoryName == original.categoryName)
        }
        
        // Repository에 저장되었는지 확인
        #expect(mockRepository.hasBudget(for: budget.month))
    }
    
    @Test("최소 예산 생성")
    func testCreateMinimalBudget_Success() async throws {
        // Given
        let container = makeMockDIContainer()
        let useCase = makeCreateBudgetUseCase(container: container)
        let mockRepository = container.mockBudgetRepository
        
        let budget = BudgetFactory.minimal()
        
        // When
        let result = try await useCase.execute(budget)
        
        // Then
        #expect(result.totalAmount == budget.totalAmount)
        #expect(result.categoryBudgets.count == budget.categoryBudgets.count)
        #expect(mockRepository.hasBudget(for: budget.month))
    }
    
    @Test("높은 소득 수준 예산 생성")
    func testCreateHighIncomeBudget_Success() async throws {
        // Given
        let container = makeMockDIContainer()
        let useCase = makeCreateBudgetUseCase(container: container)
        let mockRepository = container.mockBudgetRepository
        
        let budget = BudgetFactory.highIncome(for: YearMonth(year: 2024, month: 12))
        
        // When
        let result = try await useCase.execute(budget)
        
        // Then
        #expect(result.totalAmount == 5_000_000)
        #expect(result.categoryBudgets.count == 8)
        #expect(mockRepository.hasBudget(for: budget.month))
        
        // 카테고리 총액이 올바른지 확인
        let categorySum = result.categoryBudgets.reduce(0) { $0 + $1.amount }
        #expect(categorySum <= result.totalAmount)
    }
    
    // MARK: - Error Tests
    
    @Test("Repository 에러 시뮬레이션")
    func testCreateBudget_RepositoryError() async throws {
        // Given
        let container = makeMockDIContainer()
        let useCase = makeCreateBudgetUseCase(container: container)
        let mockRepository = container.mockBudgetRepository
        
        // Repository가 실패하도록 설정
        mockRepository.shouldFail = true
        mockRepository.errorToThrow = MockError.simulatedFailure
        
        let budget = BudgetFactory.normal()
        
        // When & Then
        do {
            _ = try await useCase.execute(budget)
            #expect(Bool(false), "Should have thrown an error")
        } catch {
            switch error {
            case MockError.simulatedFailure:
                // Expected error
                break
            default:
                #expect(Bool(false), "Unexpected error type: \(error)")
            }
        }
    }
    
    @Test("중복 예산 생성 시도 (같은 달)")
    func testCreateDuplicateBudget_Error() async throws {
        // Given
        let container = makeMockDIContainer()
        let useCase = makeCreateBudgetUseCase(container: container)
        let mockRepository = container.mockBudgetRepository
        
        let month = YearMonth(year: 2024, month: 9)
        let budget1 = BudgetFactory.normal(for: month)
        let budget2 = BudgetFactory.minimal(for: month)
        
        // When - 첫 번째 예산 생성 성공
        _ = try await useCase.execute(budget1)
        #expect(mockRepository.budgetCount == 1)
        
        // Then - 같은 달에 두 번째 예산 생성 시도 시 에러
        do {
            _ = try await useCase.execute(budget2)
            #expect(Bool(false), "Should have thrown an error for duplicate budget")
        } catch {
            // 중복 생성 에러 예상
            #expect(mockRepository.budgetCount == 1, "Should still have only one budget")
        }
    }
    
    // MARK: - Validation Tests
    
    @Test("카테고리 예산 합계가 총 예산을 초과하는 경우")
    func testCreateBudget_CategoryBudgetsExceedTotal_Error() async throws {
        // Given
        let container = makeMockDIContainer()
        let useCase = makeCreateBudgetUseCase(container: container)
        
        let budgetId = UUID()
        let excessiveCategoryBudgets = [
            CategoryBudgetDTO(amount: 800_000, categoryID: UUID(), categoryName: "식비", budgetId: budgetId),
            CategoryBudgetDTO(amount: 600_000, categoryID: UUID(), categoryName: "교통비", budgetId: budgetId),
            CategoryBudgetDTO(amount: 700_000, categoryID: UUID(), categoryName: "쇼핑", budgetId: budgetId)
        ]
        
        let budget = BudgetDTO(
            id: budgetId,
            month: YearMonth.current,
            totalAmount: 1_000_000, // 총액 100만원인데 카테고리 합계는 210만원
            categoryBudgets: excessiveCategoryBudgets
        )
        
        // When & Then
        do {
            _ = try await useCase.execute(budget)
            #expect(Bool(false), "Should have thrown validation error")
        } catch {
            // 검증 에러 발생 확인
            #expect(true, "Validation error occurred as expected")
        }
    }
    
    @Test("빈 카테고리 예산으로 예산 생성")
    func testCreateBudgetWithEmptyCategories_Success() async throws {
        // Given
        let container = makeMockDIContainer()
        let useCase = makeCreateBudgetUseCase(container: container)
        let mockRepository = container.mockBudgetRepository
        
        let budget = BudgetFactory.empty()
        
        // When
        let result = try await useCase.execute(budget)
        
        // Then
        #expect(result.totalAmount == 0)
        #expect(result.categoryBudgets.isEmpty)
        #expect(mockRepository.hasBudget(for: budget.month))
    }
    
    // MARK: - Edge Cases
    
    @Test("극한 값으로 예산 생성")
    func testCreateBudget_EdgeValues() async throws {
        // Given
        let container = makeMockDIContainer()
        let useCase = makeCreateBudgetUseCase(container: container)
        let mockRepository = container.mockBudgetRepository
        
        let budget = BudgetFactory.edge()
        
        // When
        let result = try await useCase.execute(budget)
        
        // Then
        #expect(result.totalAmount == budget.totalAmount)
        #expect(result.categoryBudgets.count == budget.categoryBudgets.count)
        #expect(mockRepository.hasBudget(for: budget.month))
    }
    
    @Test("미래 날짜로 예산 생성")
    func testCreateBudgetForFutureDate_Success() async throws {
        // Given
        let container = makeMockDIContainer()
        let useCase = makeCreateBudgetUseCase(container: container)
        let mockRepository = container.mockBudgetRepository
        
        let futureMonth = YearMonth(year: 2025, month: 12)
        let budget = BudgetFactory.normal(for: futureMonth)
        
        // When
        let result = try await useCase.execute(budget)
        
        // Then
        #expect(result.month == futureMonth)
        #expect(mockRepository.hasBudget(for: futureMonth))
    }
    
    @Test("과거 날짜로 예산 생성")
    func testCreateBudgetForPastDate_Success() async throws {
        // Given
        let container = makeMockDIContainer()
        let useCase = makeCreateBudgetUseCase(container: container)
        let mockRepository = container.mockBudgetRepository
        
        let pastMonth = YearMonth(year: 2023, month: 1)
        let budget = BudgetFactory.normal(for: pastMonth)
        
        // When
        let result = try await useCase.execute(budget)
        
        // Then
        #expect(result.month == pastMonth)
        #expect(mockRepository.hasBudget(for: pastMonth))
    }
    
    // MARK: - Multiple Budget Tests
    
    @Test("여러 개의 예산을 순차적으로 생성")
    func testCreateMultipleBudgets_Sequential() async throws {
        // Given
        let container = makeMockDIContainer()
        let useCase = makeCreateBudgetUseCase(container: container)
        let mockRepository = container.mockBudgetRepository
        
        let budgets = BudgetFactory.multipleMonths(count: 5)
        
        // When
        var createdBudgets: [BudgetDTO] = []
        for budget in budgets {
            let created = try await useCase.execute(budget)
            createdBudgets.append(created)
        }
        
        // Then
        #expect(createdBudgets.count == 5)
        #expect(mockRepository.budgetCount == 5)
        
        for (original, created) in zip(budgets, createdBudgets) {
            #expect(created.month == original.month)
            #expect(created.totalAmount == original.totalAmount)
        }
    }
    
    // MARK: - Delay Tests
    
    @Test("지연이 있는 Repository 테스트")
    func testCreateBudget_WithDelay() async throws {
        // Given
        let container = makeMockDIContainer()
        let useCase = makeCreateBudgetUseCase(container: container)
        let mockRepository = container.mockBudgetRepository
        
        // 0.1초 지연 설정
        mockRepository.delay = 0.1
        
        let budget = BudgetFactory.normal()
        let startTime = Date()
        
        // When
        let result = try await useCase.execute(budget)
        let endTime = Date()
        
        // Then
        let elapsed = endTime.timeIntervalSince(startTime)
        #expect(elapsed >= 0.1, "Should have waited at least 0.1 seconds")
        #expect(result.id == budget.id)
        #expect(mockRepository.hasBudget(for: budget.month))
    }
}
