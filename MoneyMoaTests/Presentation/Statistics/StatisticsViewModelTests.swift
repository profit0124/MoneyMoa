//
//  StatisticsViewModelTests.swift
//  MoneyMoaTests
//
//  Created by Sooik Kim on 9/10/25.
//

import Testing
import Foundation
@testable import MoneyMoa

@Suite("StatisticsViewModel Tests")
struct StatisticsViewModelTests {
    
    // MARK: - Test Setup
    
    private func createViewModel(
        useCase: GetStatisticsDashboardUseCase? = nil
    ) -> StatisticsViewModel {
        let mockUseCase = useCase ?? MockGetStatisticsDashboardUseCase()
        return StatisticsViewModel(getStatisticsDashboardUseCase: mockUseCase)
    }
    
    private func createMockDashboardData(
        hasTransaction: Bool = true,
        hasBudget: Bool = true,
        hasCategory: Bool = true
    ) -> StatisticsDashboardDTO {
        return StatisticsDashboardDTO(
            overview: .init(
                monthly: hasTransaction ? [
                    MonthlyPointDTO(
                        monthStart: Date(),
                        income: 1000000,
                        expense: 600000,
                        savingsRate: 40.0,
                        previousMonthChange: 0
                    )
                ] : [],
                daily: hasTransaction ? [
                    DailyPointDTO(date: Date(), amount: 50000, movingAverage: 50000, isWeekend: false)
                ] : [],
                burndown: []
            ),
            category: .init(
                ratios: hasCategory ? [
                    CategoryRatioDTO(categoryId: "cat1", categoryName: "식비", ratio: 0.6, amount: 300000)
                ] : [],
                monthlyStacks: []
            ),
            payment: .init(ratios: []),
            pattern: .init(
                weekly: .init(days: []),
                typeRatio: .init(income: 0.6, expense: 0.4),
                merchants: .init(entries: [])
            ),
            budget: .init(
                byMonth: hasBudget ? [
                    BudgetVsExpenseDTO(monthStart: Date(), budget: 1000000, expense: 600000)
                ] : [],
                byCategory: hasBudget ? [
                    CategoryBudgetVsExpenseDTO(
                        categoryId: "cat1",
                        categoryName: "식비",
                        budget: 500000,
                        expense: 300000,
                        usageRate: 0.6,
                        status: .normal,
                        monthCount: 1
                    )
                ] : []
            )
        )
    }
    
    // MARK: - Initialization Tests
    
    @Test("초기화: 기본 상태 설정")
    func testInitialization_DefaultState() {
        // Given & When
        let viewModel = createViewModel()
        
        // Then - 기본 상태 확인
        #expect(viewModel.selectedDateRange == .thisMonth)
        #expect(viewModel.selectedGrouping == .daily)
        #expect(viewModel.showCustomDatePicker == false)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
        
        // 빈 대시보드 데이터로 초기화
        #expect(viewModel.dashboardData.overview.monthly.isEmpty)
        #expect(viewModel.dashboardData.overview.daily.isEmpty)
        #expect(viewModel.dashboardData.category.ratios.isEmpty)
        #expect(viewModel.dashboardData.budget.byMonth.isEmpty)
    }
    
    // MARK: - Data Existence Check Tests
    
    @Test("데이터 존재 여부: hasTransactionData")
    func testHasTransactionData() {
        // Given
        let viewModel = createViewModel()
        
        // When - 거래 데이터가 있는 경우
        viewModel.dashboardData = createMockDashboardData(hasTransaction: true)
        
        // Then
        #expect(viewModel.hasTransactionData == true)
        
        // When - 거래 데이터가 없는 경우
        viewModel.dashboardData = createMockDashboardData(hasTransaction: false)
        
        // Then
        #expect(viewModel.hasTransactionData == false)
    }
    
    @Test("데이터 존재 여부: hasBudgetData")
    func testHasBudgetData() {
        // Given
        let viewModel = createViewModel()
        
        // When - 예산 데이터가 있는 경우
        viewModel.dashboardData = createMockDashboardData(hasBudget: true)
        
        // Then
        #expect(viewModel.hasBudgetData == true)
        
        // When - 예산 데이터가 없는 경우
        viewModel.dashboardData = createMockDashboardData(hasBudget: false)
        
        // Then
        #expect(viewModel.hasBudgetData == false)
    }
    
    @Test("데이터 존재 여부: hasAnyCategoryData")
    func testHasAnyCategoryData() {
        // Given
        let viewModel = createViewModel()
        
        // When - 카테고리 데이터가 있는 경우
        viewModel.dashboardData = createMockDashboardData(hasCategory: true)
        
        // Then
        #expect(viewModel.hasAnyCategoryData == true)
        
        // When - 카테고리 데이터가 없는 경우
        viewModel.dashboardData = createMockDashboardData(hasCategory: false)
        
        // Then
        #expect(viewModel.hasAnyCategoryData == false)
    }
    
    // MARK: - Date Range Management Tests
    
    @Test("날짜 범위 관리: currentDateRange - 프리셋")
    func testCurrentDateRange_Preset() {
        // Given
        let viewModel = createViewModel()
        viewModel.selectedDateRange = .thisMonth
        
        // When
        let currentRange = viewModel.currentDateRange
        let expectedRange = DateRangePreset.thisMonth.resolve()
        
        // Then
        #expect(currentRange.start == expectedRange.start)
        #expect(currentRange.end == expectedRange.end)
        #expect(currentRange.grouping == expectedRange.grouping)
    }
    
    @Test("날짜 범위 관리: currentDateRange - 커스텀")
    func testCurrentDateRange_Custom() {
        // Given
        let viewModel = createViewModel()
        let cal = Calendar.current
        let start = cal.date(from: DateComponents(year: 2025, month: 6, day: 1))!
        let end = cal.date(from: DateComponents(year: 2025, month: 9, day: 1))!
        let customRange = DateRange(start: start, end: end, calendar: cal)
        
        viewModel.customDateRange = customRange
        viewModel.selectedDateRange = .custom(start, end)
        
        // When
        let currentRange = viewModel.currentDateRange
        
        // Then
        #expect(currentRange.start == customRange.start)
        #expect(currentRange.end == customRange.end)
        #expect(currentRange.grouping == customRange.grouping)
    }
    
    @Test("날짜 범위 포맷팅: formattedDateRange")
    func testFormattedDateRange() {
        // Given
        let viewModel = createViewModel()
        viewModel.selectedDateRange = .thisMonth
        
        // When
        let formatted = viewModel.formattedDateRange
        
        // Then
        #expect(!formatted.isEmpty) // 포맷팅된 문자열이 비어있지 않음
        #expect(formatted.contains("25.")) // 연도가 포함되어 있는지 확인 (YY.MM.DD 형식)
    }
    
    // MARK: - Action Tests - updateDateRange
    
    @Test("액션 테스트: updateDateRange - 그룹핑 자동 업데이트")
    func testUpdateDateRange_AutoGrouping() async {
        // Given
        let mockUseCase = MockGetStatisticsDashboardUseCase()
        mockUseCase.result = .success(createMockDashboardData())
        let viewModel = createViewModel(useCase: mockUseCase)
        
        // When - 단일 월 범위 선택 (daily 그룹핑 예상)
        viewModel.send(.updateDateRange(.thisMonth))
        
        // Then
        #expect(viewModel.selectedDateRange == .thisMonth)
        #expect(viewModel.selectedGrouping == .daily) // 단일 월은 daily
        
        // When - 다중 월 범위 선택 (monthly 그룹핑 예상)
        viewModel.send(.updateDateRange(.sixMonths))
        
        // Then
        #expect(viewModel.selectedDateRange == .sixMonths)
        #expect(viewModel.selectedGrouping == .monthly) // 다중 월은 monthly
    }
    
    @Test("액션 테스트: updateCustomDateRange")
    func testUpdateCustomDateRange() async {
        // Given
        let mockUseCase = MockGetStatisticsDashboardUseCase()
        mockUseCase.result = .success(createMockDashboardData())
        let viewModel = createViewModel(useCase: mockUseCase)
        
        let cal = Calendar.current
        let start = cal.date(from: DateComponents(year: 2025, month: 6, day: 1))!
        let end = cal.date(from: DateComponents(year: 2025, month: 9, day: 1))!
        let customRange = DateRange(start: start, end: end, calendar: cal)
        
        // When
        viewModel.send(.updateCustomDateRange(customRange))
        
        // Then
        #expect(viewModel.customDateRange.start == customRange.start)
        #expect(viewModel.customDateRange.end == customRange.end)
        
        if case .custom(let customStart, let customEnd) = viewModel.selectedDateRange {
            #expect(customStart == start)
            #expect(customEnd == end)
        } else {
            #expect(Bool(false), "selectedDateRange should be custom")
        }
    }
    
    @Test("액션 테스트: updateGrouping")
    func testUpdateGrouping() async {
        // Given
        let mockUseCase = MockGetStatisticsDashboardUseCase()
        mockUseCase.result = .success(createMockDashboardData())
        let viewModel = createViewModel(useCase: mockUseCase)
        
        // When
        viewModel.send(.updateGrouping(.monthly))
        
        // Then
        #expect(viewModel.selectedGrouping == .monthly)
    }
    
    // MARK: - Loading State Tests
    
    @Test("로딩 상태: loadDashboard 성공")
    func testLoadDashboard_Success() async {
        // Given
        let mockUseCase = MockGetStatisticsDashboardUseCase()
        let expectedData = createMockDashboardData()
        mockUseCase.result = .success(expectedData)
        let viewModel = createViewModel(useCase: mockUseCase)
        
        // When
        viewModel.send(.loadDashboard)
        
        // 잠시 대기하여 비동기 로딩 완료
        try? await Task.sleep(for: .milliseconds(100))
        
        // Then
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.dashboardData.overview.monthly.count == expectedData.overview.monthly.count)
        #expect(viewModel.hasTransactionData == true)
    }
    
    @Test("로딩 상태: loadDashboard 실패")
    func testLoadDashboard_Failure() async {
        // Given
        let mockUseCase = MockGetStatisticsDashboardUseCase()
        let expectedError = MockError.simulatedFailure
        mockUseCase.result = .failure(expectedError)
        let viewModel = createViewModel(useCase: mockUseCase)
        
        // When
        viewModel.send(.loadDashboard)
        
        // 잠시 대기하여 비동기 로딩 완료
        try? await Task.sleep(for: .milliseconds(100))
        
        // Then
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.errorMessage?.contains("Simulated failure") == true)
    }
    
    @Test("로딩 상태: 로딩 중 상태 확인")
    func testLoadDashboard_LoadingState() async {
        // Given
        let mockUseCase = MockGetStatisticsDashboardUseCase()
        mockUseCase.delay = 0.5 // 500ms 지연
        mockUseCase.result = .success(createMockDashboardData())
        let viewModel = createViewModel(useCase: mockUseCase)
        
        // When
        viewModel.send(.loadDashboard)
        
        // 로딩 상태가 true가 될 때까지 폴링
        var attempts = 0
        while !viewModel.isLoading && attempts < 10 {
            try? await Task.sleep(for: .milliseconds(20))
            attempts += 1
        }
        
        // 로딩 상태 확인
        #expect(viewModel.isLoading == true)
        #expect(viewModel.errorMessage == nil)
        
        // 로딩 완료까지 대기 (폴링 방식)
        attempts = 0
        while viewModel.isLoading && attempts < 30 { // 최대 600ms 대기
            try? await Task.sleep(for: .milliseconds(20))
            attempts += 1
        }
        
        #expect(viewModel.isLoading == false)
    }
    
    // MARK: - Integration Tests
    
    @Test("통합 테스트: 날짜 범위 변경 시 자동 재로딩")
    func testIntegration_DateRangeChangeTriggersReload() async {
        // Given
        let mockUseCase = MockGetStatisticsDashboardUseCase()
        mockUseCase.result = .success(createMockDashboardData())
        let viewModel = createViewModel(useCase: mockUseCase)
        
        let initialCallCount = mockUseCase.callCount
        
        // When - 날짜 범위 변경
        viewModel.send(.updateDateRange(.threeMonths))
        
        // 비동기 로딩 완료 대기
        try? await Task.sleep(for: .milliseconds(100))
        
        // Then
        #expect(mockUseCase.callCount > initialCallCount) // UseCase가 재호출됨
        #expect(viewModel.selectedDateRange == .threeMonths)
        #expect(viewModel.selectedGrouping == .monthly) // 3개월은 monthly 그룹핑
    }
    
    @Test("통합 테스트: 모든 데이터 타입 존재 여부 동시 확인")
    func testIntegration_AllDataTypesCheck() {
        // Given
        let viewModel = createViewModel()
        
        // When - 모든 데이터가 있는 경우
        viewModel.dashboardData = createMockDashboardData(
            hasTransaction: true,
            hasBudget: true,
            hasCategory: true
        )
        
        // Then
        #expect(viewModel.hasTransactionData == true)
        #expect(viewModel.hasBudgetData == true)
        #expect(viewModel.hasAnyCategoryData == true)
        
        // When - 모든 데이터가 없는 경우
        viewModel.dashboardData = createMockDashboardData(
            hasTransaction: false,
            hasBudget: false,
            hasCategory: false
        )
        
        // Then
        #expect(viewModel.hasTransactionData == false)
        #expect(viewModel.hasBudgetData == false)
        #expect(viewModel.hasAnyCategoryData == false)
    }
    
    // MARK: - Edge Cases Tests
    
    @Test("엣지 케이스: 빈 대시보드 데이터 처리")
    func testEdgeCase_EmptyDashboardData() {
        // Given
        let viewModel = createViewModel()
        let emptyData = StatisticsDashboardDTO(
            overview: .init(monthly: [], daily: [], burndown: []),
            category: .init(ratios: [], monthlyStacks: []),
            payment: .init(ratios: []),
            pattern: .init(weekly: .init(days: []), typeRatio: .init(income: 0.0, expense: 0.0), merchants: .init(entries: [])),
            budget: .init(byMonth: [], byCategory: [])
        )
        
        // When
        viewModel.dashboardData = emptyData
        
        // Then
        #expect(viewModel.hasTransactionData == false)
        #expect(viewModel.hasBudgetData == false)
        #expect(viewModel.hasAnyCategoryData == false)
        
        // 포맷팅은 여전히 작동해야 함
        #expect(!viewModel.formattedDateRange.isEmpty)
        #expect(viewModel.currentDateRange.start <= viewModel.currentDateRange.end)
    }
    
    @Test("엣지 케이스: 에러 메시지 재설정")
    func testEdgeCase_ErrorMessageReset() async {
        // Given
        let mockUseCase = MockGetStatisticsDashboardUseCase()
        let viewModel = createViewModel(useCase: mockUseCase)
        
        // 첫 번째 로딩에서 에러 발생
        mockUseCase.result = .failure(MockError.simulatedFailure)
        viewModel.send(.loadDashboard)
        try? await Task.sleep(for: .milliseconds(100))
        
        #expect(viewModel.errorMessage != nil) // 에러 메시지 있음
        
        // When - 두 번째 로딩에서 성공
        mockUseCase.result = .success(createMockDashboardData())
        viewModel.send(.loadDashboard)
        try? await Task.sleep(for: .milliseconds(100))
        
        // Then
        #expect(viewModel.errorMessage == nil) // 에러 메시지가 리셋됨
        #expect(viewModel.hasTransactionData == true)
    }
}

// MARK: - Mock Classes

final class MockGetStatisticsDashboardUseCase: GetStatisticsDashboardUseCase {
    var result: Result<StatisticsDashboardDTO, Error> = .success(
        StatisticsDashboardDTO(
            overview: .init(monthly: [], daily: [], burndown: []),
            category: .init(ratios: [], monthlyStacks: []),
            payment: .init(ratios: []),
            pattern: .init(weekly: .init(days: []), typeRatio: .init(income: 0.0, expense: 0.0), merchants: .init(entries: [])),
            budget: .init(byMonth: [], byCategory: [])
        )
    )

    var delay: TimeInterval = 0
    var callCount = 0
    var lastRange: DateRange?

    func execute(range: DateRange) async throws -> StatisticsDashboardDTO {
        callCount += 1
        lastRange = range

        if delay > 0 {
            try await Task.sleep(for: .seconds(delay))
        }

        switch result {
        case .success(let data):
            return data
        case .failure(let error):
            throw error
        }
    }
}
