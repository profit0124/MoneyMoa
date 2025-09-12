//
//  BudgetRepositoryAdapterTests.swift
//  MoneyMoaTests
//
//  Created by Claude Code on 9/9/25.
//

import Testing
import Foundation
@testable import MoneyMoa

@Suite("BudgetRepositoryAdapter Tests")
struct BudgetRepositoryAdapterTests {
    
    // MARK: - Test Components
    
    private func makeMockDIContainer() -> MockDIContainer {
        return MockDIContainer()
    }
    
    private func makeBudgetRepositoryAdapter(
        budgetRepo: MockBudgetRepository,
        txRepo: MockTransactionRepository
    ) -> BudgetRepositoryAdapter {
        return BudgetRepositoryAdapter(budgetRepo: budgetRepo, txRepo: txRepo)
    }
    
    private func createTestRange() -> DateRange {
        let cal = Calendar.current
        let start = cal.date(from: DateComponents(year: 2025, month: 6, day: 1))!
        let end = cal.date(from: DateComponents(year: 2025, month: 8, day: 31))!
        return DateRange(start: start, end: end, calendar: cal)
    }
    
    private func createSingleMonthRange() -> DateRange {
        // CI 환경 호환성을 위해 고정된 날짜 사용
        return FixedDateHelper.fixedMonthRange
    }
    
    // MARK: - fetchBudgets Tests
    
    @Test("정상 케이스: 여러 월의 예산을 카테고리별로 올바르게 그룹핑")
    func testFetchBudgets_Normal_Success() async throws {
        // Given
        let container = makeMockDIContainer()
        let budgetRepo = container.mockBudgetRepository
        let txRepo = container.mockTransactionRepository
        let adapter = makeBudgetRepositoryAdapter(budgetRepo: budgetRepo, txRepo: txRepo)
        
        // multipleMonths 시나리오로 여러 월 예산 데이터 준비
        budgetRepo.loadScenario(.multipleMonths)
        let range = createTestRange() // 6~8월
        
        // When
        let result = try await adapter.fetchBudgets(range: range)
        
        // Then
        #expect(!result.isEmpty, "예산 데이터가 반환되어야 함")
        
        // 각 카테고리별로 월별 예산이 올바르게 매핑되었는지 확인
        for (categoryId, monthlyBudgets) in result {
            #expect(!categoryId.isEmpty, "카테고리 ID가 존재해야 함")
            #expect(!monthlyBudgets.isEmpty, "월별 예산이 존재해야 함")
            
            for (yearMonth, amount) in monthlyBudgets {
                #expect(amount > 0, "예산 금액이 0보다 커야 함")
                #expect(range.months().contains(yearMonth), "범위 내의 월이어야 함")
            }
        }
    }
    
    @Test("빈 예산: 예산이 없는 경우 빈 딕셔너리 반환")
    func testFetchBudgets_Empty_Success() async throws {
        // Given
        let container = makeMockDIContainer()
        let budgetRepo = container.mockBudgetRepository
        let txRepo = container.mockTransactionRepository
        let adapter = makeBudgetRepositoryAdapter(budgetRepo: budgetRepo, txRepo: txRepo)
        
        budgetRepo.loadScenario(.empty)
        let range = createTestRange()
        
        // When
        let result = try await adapter.fetchBudgets(range: range)
        
        // Then
        #expect(result.isEmpty, "빈 예산의 경우 빈 딕셔너리를 반환해야 함")
    }
    
    @Test("단일 월 예산: normal 시나리오로 단일 월 예산 처리")
    func testFetchBudgets_SingleMonth_Success() async throws {
        // Given
        let container = makeMockDIContainer()
        let budgetRepo = container.mockBudgetRepository
        let txRepo = container.mockTransactionRepository
        let adapter = makeBudgetRepositoryAdapter(budgetRepo: budgetRepo, txRepo: txRepo)
        
        // 테스트에서 사용할 고정된 월
        let range = createSingleMonthRange()
        let targetMonth = YearMonth(date: range.start, calendar: Calendar.current)
        
        // 해당 월에 대한 예산을 명시적으로 생성
        let budget = BudgetFactory.normal(for: targetMonth)
        budgetRepo.setBudgets([budget])
        
        // When
        let result = try await adapter.fetchBudgets(range: range)
        
        // Then
        #expect(!result.isEmpty, "단일 월 예산이 반환되어야 함")
        
        // normal 시나리오는 5개 카테고리를 가져야 함 (BudgetFactory.normal 기준)
        #expect(result.count == 5, "normal 시나리오는 5개 카테고리를 가져야 함")
        
        // 각 카테고리가 하나의 월(현재 월)만 가져야 함
        for (_, monthlyBudgets) in result {
            #expect(monthlyBudgets.count == 1, "단일 월이므로 하나의 월만 존재해야 함")
        }
    }
    
    @Test("Repository 에러: BudgetRepository 에러 시 예외 전파")
    func testFetchBudgets_RepositoryError_ThrowsError() async throws {
        // Given
        let container = makeMockDIContainer()
        let budgetRepo = container.mockBudgetRepository
        let txRepo = container.mockTransactionRepository
        let adapter = makeBudgetRepositoryAdapter(budgetRepo: budgetRepo, txRepo: txRepo)
        
        // Repository가 실패하도록 설정
        budgetRepo.shouldFail = true
        budgetRepo.errorToThrow = MockError.simulatedFailure
        
        let range = createTestRange()
        
        // When & Then
        do {
            _ = try await adapter.fetchBudgets(range: range)
            #expect(Bool(false), "에러가 발생해야 함")
        } catch {
            switch error {
            case MockError.simulatedFailure:
                // 예상된 에러
                break
            default:
                #expect(Bool(false), "예상치 못한 에러 타입: \(error)")
            }
        }
    }
    
    // MARK: - fetchBudgetVsExpenseByMonth Tests
    
    @Test("정상 케이스: 예산 vs 지출 월별 비교 데이터 생성")
    func testFetchBudgetVsExpenseByMonth_Normal_Success() async throws {
        // Given
        let container = makeMockDIContainer()
        let budgetRepo = container.mockBudgetRepository
        let txRepo = container.mockTransactionRepository
        let adapter = makeBudgetRepositoryAdapter(budgetRepo: budgetRepo, txRepo: txRepo)
        
        let range = createSingleMonthRange() // 8월
        let targetMonth = YearMonth(date: range.start, calendar: Calendar.current)
        
        // 테스트 월에 맞는 예산과 거래 생성
        let budget = BudgetFactory.normal(for: targetMonth)
        budgetRepo.setBudgets([budget])
        
        // 테스트 월에 맞는 거래 생성
        let testDate = FixedDateHelper.fixedDate
        try await txRepo.insertTransaction(
            TransactionFactory.create(
                amount: 200000,
                date: testDate,
                transactionType: .variableExpense,
                subCategory: .mockFoodExpense,
                paymentMethod: .mockCash
            )
        )
        
        // When
        let result = try await adapter.fetchBudgetVsExpenseByMonth(range: range)
        
        // Then
        #expect(result.count == 1, "단일 월이므로 결과가 1개여야 함")
        
        let row = result[0]
        #expect(row.budget > 0, "예산이 있어야 함")
        #expect(row.expense == 200000, "지출이 예상값과 일치해야 함")
        
        #expect(Calendar.current.isDate(row.monthStart, equalTo: range.start, toGranularity: .month),
               "monthStart가 요청한 범위의 월과 같아야 함")
    }
    
    @Test("여러 월 처리: 3개월 범위의 예산 vs 지출 데이터")
    func testFetchBudgetVsExpenseByMonth_MultipleMonths_Success() async throws {
        // Given
        let container = makeMockDIContainer()
        let budgetRepo = container.mockBudgetRepository
        let txRepo = container.mockTransactionRepository
        let adapter = makeBudgetRepositoryAdapter(budgetRepo: budgetRepo, txRepo: txRepo)
        
        budgetRepo.loadScenario(.multipleMonths)
        txRepo.loadScenario(.normal())
        
        let range = createTestRange() // 6~8월
        
        // When
        let result = try await adapter.fetchBudgetVsExpenseByMonth(range: range)
        
        // Then
        #expect(result.count == 3, "3개월 범위이므로 결과가 3개여야 함")
        
        // 월별로 정렬되어 있는지 확인 (오래된 월부터)
        for i in 0..<(result.count - 1) {
            #expect(result[i].monthStart < result[i + 1].monthStart,
                   "월별 데이터가 시간순으로 정렬되어야 함")
        }
        
        // 각 월의 데이터가 유효한지 확인
        for row in result {
            #expect(row.budget >= 0, "예산은 0 이상이어야 함")
            #expect(row.expense >= 0, "지출은 0 이상이어야 함")
        }
    }
    
    @Test("예산 없음: 예산이 0인 경우에도 정상 처리")
    func testFetchBudgetVsExpenseByMonth_NoBudget_Success() async throws {
        // Given
        let container = makeMockDIContainer()
        let budgetRepo = container.mockBudgetRepository
        let txRepo = container.mockTransactionRepository
        let adapter = makeBudgetRepositoryAdapter(budgetRepo: budgetRepo, txRepo: txRepo)
        
        let range = createSingleMonthRange()
        
        // 예산 없이 거래만 생성
        let testDate = FixedDateHelper.fixedDate
        try await txRepo.insertTransaction(
            TransactionFactory.create(
                amount: 150000,
                date: testDate,
                transactionType: .variableExpense,
                subCategory: .mockFoodExpense,
                paymentMethod: .mockCash
            )
        )
        
        // When
        let result = try await adapter.fetchBudgetVsExpenseByMonth(range: range)
        
        // Then
        #expect(result.count == 1, "결과가 1개여야 함")
        
        let row = result[0]
        #expect(row.budget == 0, "예산이 없으므로 0이어야 함")
        #expect(row.expense == 150000, "지출이 예상값과 일치해야 함")
    }
    
    @Test("거래 없음: 거래가 없는 경우 지출이 0")
    func testFetchBudgetVsExpenseByMonth_NoTransactions_Success() async throws {
        // Given
        let container = makeMockDIContainer()
        let budgetRepo = container.mockBudgetRepository
        let txRepo = container.mockTransactionRepository
        let adapter = makeBudgetRepositoryAdapter(budgetRepo: budgetRepo, txRepo: txRepo)
        
        let range = createSingleMonthRange()
        let targetMonth = YearMonth(date: range.start, calendar: Calendar.current)
        
        // 해당 월에 대한 예산을 명시적으로 생성
        let budget = BudgetFactory.normal(for: targetMonth)
        budgetRepo.setBudgets([budget])
        txRepo.loadScenario(.empty) // 거래 없음
        
        // When
        let result = try await adapter.fetchBudgetVsExpenseByMonth(range: range)
        
        // Then
        #expect(result.count == 1, "결과가 1개여야 함")
        
        let row = result[0]
        #expect(row.budget > 0, "normal 시나리오이므로 예산이 0보다 커야 함")
        #expect(row.expense == 0, "거래가 없으므로 지출이 0이어야 함")
    }
    
    @Test("BudgetRepository 에러: BudgetRepository 에러 시 예외 전파")
    func testFetchBudgetVsExpenseByMonth_BudgetRepositoryError_ThrowsError() async throws {
        // Given
        let container = makeMockDIContainer()
        let budgetRepo = container.mockBudgetRepository
        let txRepo = container.mockTransactionRepository
        let adapter = makeBudgetRepositoryAdapter(budgetRepo: budgetRepo, txRepo: txRepo)
        
        budgetRepo.shouldFail = true
        budgetRepo.errorToThrow = MockError.simulatedFailure
        txRepo.loadScenario(.normal())
        
        let range = createSingleMonthRange()
        
        // When & Then
        do {
            _ = try await adapter.fetchBudgetVsExpenseByMonth(range: range)
            #expect(Bool(false), "에러가 발생해야 함")
        } catch {
            switch error {
            case MockError.simulatedFailure:
                // 예상된 에러
                break
            default:
                #expect(Bool(false), "예상치 못한 에러 타입: \(error)")
            }
        }
    }
    
    @Test("TransactionRepository 에러: TransactionRepository 에러 시 예외 전파")
    func testFetchBudgetVsExpenseByMonth_TransactionRepositoryError_ThrowsError() async throws {
        // Given
        let container = makeMockDIContainer()
        let budgetRepo = container.mockBudgetRepository
        let txRepo = container.mockTransactionRepository
        let adapter = makeBudgetRepositoryAdapter(budgetRepo: budgetRepo, txRepo: txRepo)
        
        budgetRepo.loadScenario(.normal)
        txRepo.shouldFail = true
        txRepo.errorToThrow = MockError.simulatedFailure
        
        let range = createSingleMonthRange()
        
        // When & Then
        do {
            _ = try await adapter.fetchBudgetVsExpenseByMonth(range: range)
            #expect(Bool(false), "에러가 발생해야 함")
        } catch {
            switch error {
            case MockError.simulatedFailure:
                // 예상된 에러
                break
            default:
                #expect(Bool(false), "예상치 못한 에러 타입: \(error)")
            }
        }
    }
    
    @Test("지출 타입 합계: 고정비 + 변동비 합계가 올바르게 계산됨")
    func testFetchBudgetVsExpenseByMonth_ExpenseCalculation_Success() async throws {
        // Given
        let container = makeMockDIContainer()
        let budgetRepo = container.mockBudgetRepository
        let txRepo = container.mockTransactionRepository
        let adapter = makeBudgetRepositoryAdapter(budgetRepo: budgetRepo, txRepo: txRepo)
        
        let range = createSingleMonthRange()
        let targetMonth = YearMonth(date: range.start, calendar: Calendar.current)
        
        // 예산 생성
        let budget = BudgetFactory.normal(for: targetMonth)
        budgetRepo.setBudgets([budget])
        
        // 다양한 지출 타입의 거래 생성
        let testDate = FixedDateHelper.fixedDate
        let fixedAmount: Decimal = 100000
        let variableAmount: Decimal = 250000
        
        try await txRepo.insertTransaction(
            TransactionFactory.create(
                amount: fixedAmount,
                date: testDate,
                transactionType: .fixedExpense,
                subCategory: .mockHousingRent,
                paymentMethod: .mockTransfer
            )
        )
        try await txRepo.insertTransaction(
            TransactionFactory.create(
                amount: variableAmount,
                date: testDate,
                transactionType: .variableExpense,
                subCategory: .mockFoodExpense,
                paymentMethod: .mockCash
            )
        )
        
        // When
        let result = try await adapter.fetchBudgetVsExpenseByMonth(range: range)
        
        // Then
        #expect(result.count == 1, "결과가 1개여야 함")
        
        let row = result[0]
        let expectedExpense = fixedAmount + variableAmount
        
        #expect(row.expense == expectedExpense, 
               "계산된 지출이 고정비 + 변동비 합계와 일치해야 함")
    }
}
