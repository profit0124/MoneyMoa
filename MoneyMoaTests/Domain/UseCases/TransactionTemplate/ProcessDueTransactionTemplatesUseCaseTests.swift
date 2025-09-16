//
//  ProcessDueTransactionTemplatesUseCaseTests.swift
//  MoneyMoaTests
//
//  Created by Sooik Kim on 9/16/25.
//

import XCTest
@testable import MoneyMoa

final class ProcessDueTemplatesUseCaseTests: XCTestCase {

    private var templateRepository: MockTransactionTemplateRepository!
    private var transactionRepository: MockTransactionRepository!
    private var useCase: TransactionTemplateProcessingUseCase!

    override func setUpWithError() throws {
        templateRepository = MockTransactionTemplateRepository(scenario: .empty)
        transactionRepository = MockTransactionRepository(scenario: .empty)
        useCase = TransactionTemplateProcessingUseCaseImpl(
            templateRepository: templateRepository,
            transactionWriter: transactionRepository
        )
    }

    override func tearDownWithError() throws {
        templateRepository = nil
        transactionRepository = nil
        useCase = nil
    }

    // MARK: - Basic Functionality Tests

    func testExecute_withNoDueTemplates_returnsZero() async throws {
        // Given: 빈 템플릿 설정
        templateRepository.loadScenario(.empty)

        // When
        let result = try await useCase.execute(upToDate: Date())

        // Then
        XCTAssertEqual(result, 0)
    }

    func testExecute_withDueTemplates_createsTransactionsAndUpdatesTemplates() async throws {
        // Given: 처리 대상 템플릿들 설정
        templateRepository.loadScenario(.dueOnly)
        let initialTemplateCount = templateRepository.getTemplateCount()

        // When
        let result = try await useCase.execute(upToDate: Date())

        // Then
        XCTAssertGreaterThan(result, 0)
        XCTAssertEqual(templateRepository.getTemplateCount(), initialTemplateCount) // 템플릿은 유지
    }

    // MARK: - Monthly Template Tests

    func testExecute_withMonthlyTemplate_calculatesMissedOccurrencesCorrectly() async throws {
        // Given: 현재 시점에서 처리 대상인 월간 템플릿
        let now = Date()
        let twoMonthsAgo = Calendar.current.date(byAdding: .month, value: -2, to: now)!

        // 2개월 전에 생성되어 1번만 처리된 템플릿 (즉, 1개월치 누락)
        let monthlyTemplate = createCustomTemplateWithCreatedAt(
            recurrencePeriod: .monthly,
            createdAt: twoMonthsAgo,
            processedCount: 1,
            nextDueDate: Calendar.current.date(byAdding: .month, value: -1, to: now)! // 1개월 전이 nextDueDate
        )

        templateRepository.loadScenario(.empty)
        templateRepository.removeAllTemplates()
        try await templateRepository.insertTemplate(monthlyTemplate)

        // When
        let result = try await useCase.execute(upToDate: now)

        // Then
        XCTAssertEqual(result, 2) // 2개의 Transaction 생성 (8월, 9월분 누락)

        // 템플릿이 업데이트되었는지 확인
        let updatedTemplates = try await templateRepository.fetchAllTemplates()
        let updatedTemplate = updatedTemplates.first!
        XCTAssertEqual(updatedTemplate.processedCount, 3) // 1 + 2 = 3
        XCTAssertNotNil(updatedTemplate.nextDueDate)
        if let nextDue = updatedTemplate.nextDueDate {
            XCTAssertGreaterThan(nextDue, now) // 다음 스케줄은 미래
        }
    }

    // MARK: - Yearly Template Tests

    func testExecute_withYearlyTemplate_calculatesMissedOccurrencesCorrectly() async throws {
        // Given: 1년 전에 생성되어 처리 대상인 연간 템플릿
        let now = Date()
        let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: now)!

        // 1년 전에 생성되어 1번 처리된 템플릿 (즉, 오늘이 다음 처리일)
        let yearlyTemplate = createCustomTemplateWithCreatedAt(
            recurrencePeriod: .yearly,
            createdAt: oneYearAgo,
            processedCount: 1,
            nextDueDate: now // 오늘이 nextDueDate
        )

        templateRepository.loadScenario(.empty)
        templateRepository.removeAllTemplates()
        try await templateRepository.insertTemplate(yearlyTemplate)

        // When
        let result = try await useCase.execute(upToDate: now)

        // Then
        XCTAssertEqual(result, 1) // 1개의 Transaction 생성

        // 템플릿이 업데이트되었는지 확인
        let updatedTemplates = try await templateRepository.fetchAllTemplates()
        let updatedTemplate = updatedTemplates.first!
        XCTAssertEqual(updatedTemplate.processedCount, 2) // 1 + 1 = 2
    }

    // MARK: - Multiple Templates Tests

    func testExecute_withMultipleDueTemplates_processesAllCorrectly() async throws {
        // Given: 여러 처리 대상 템플릿들
        templateRepository.loadScenario(.dueOnly)
        let initialCount = templateRepository.getTemplateCount()

        // When
        let result = try await useCase.execute(upToDate: Date())

        // Then
        XCTAssertGreaterThan(result, 0)
        XCTAssertEqual(templateRepository.getTemplateCount(), initialCount) // 템플릿 개수 유지
    }

    // MARK: - Edge Cases Tests

    func testExecute_withTemplateHavingNilNextDueDate_skipsTemplate() async throws {
        // Given: nextDueDate가 nil인 템플릿 (일회성 템플릿)
        let nilDateTemplate = createCustomTemplate(
            recurrencePeriod: .none, // 일회성으로 설정
            nextDueDate: nil,
            processedCount: 1
        )

        templateRepository.loadScenario(.empty)
        templateRepository.removeAllTemplates()
        try await templateRepository.insertTemplate(nilDateTemplate)

        // When
        let result = try await useCase.execute(upToDate: Date())

        // Then
        XCTAssertEqual(result, 0) // 처리되지 않음
    }

    func testExecute_withFutureNextDueDate_skipsTemplate() async throws {
        // Given: nextDueDate가 미래인 템플릿
        let now = Date()
        let futureDate = Calendar.current.date(byAdding: .day, value: 5, to: now)!

        let template = TransactionTemplateFactory.random()
        let futureTemplate = TransactionTemplateDTO(
            id: template.id,
            amount: template.amount,
            place: template.place,
            memo: template.memo,
            transactionType: template.transactionType,
            recurrencePeriod: .monthly,
            createdAt: template.createdAt,
            processedCount: template.processedCount,
            lastAddedAt: template.lastAddedAt,
            nextDueDate: futureDate,
            timeContext: template.timeContext,
            subCategory: template.subCategory,
            paymentMethod: template.paymentMethod
        )

        templateRepository.loadScenario(.empty)
        templateRepository.removeAllTemplates()
        try await templateRepository.insertTemplate(futureTemplate)

        // When
        let result = try await useCase.execute(upToDate: now)

        // Then
        XCTAssertEqual(result, 0) // 처리되지 않음
    }

    // MARK: - Error Handling Tests

    func testExecute_withRepositoryError_continuesProcessingOtherTemplates() async throws {
        // Given: 일부 템플릿에서 에러가 발생하도록 설정
        templateRepository.loadScenario(.dueOnly)
        transactionRepository.shouldFail = true

        // When & Then: 에러가 발생해도 크래시되지 않음
        let result = try await useCase.execute(upToDate: Date())
        XCTAssertEqual(result, 0) // 에러로 인해 처리되지 않음
    }

    // MARK: - Weekly Template Tests

    func testExecute_withWeeklyTemplate_calculatesMissedOccurrencesCorrectly() async throws {
        // Given: 10일 전이 nextDueDate인 Weekly 템플릿
        let now = Date()
        let tenDaysAgo = Calendar.current.date(byAdding: .day, value: -10, to: now)!

        let weeklyTemplate = TestDataFactory.createTransactionTemplate(
            amount: 50000,
            place: "주간구독",
            memo: "주간 서비스",
            transactionType: .fixedExpense,
            recurrencePeriod: .weekly,
            processedCount: 1,
            lastAddedAt: nil,
            nextDueDate: tenDaysAgo,
            subCategory: CategoryFactory.createSubCategory(
                name: "구독서비스",
                transactionType: .fixedExpense,
                parentCategory: CategoryFactory.createCategory(
                    name: "구독", iconName: "tv", transactionType: .fixedExpense, orderIndex: 0
                ),
                orderIndex: 0
            ),
            paymentMethod: PaymentMethodFactory.create(name: "신용카드", kind: .credit)
        )

        templateRepository.loadScenario(.empty)
        templateRepository.removeAllTemplates()
        try await templateRepository.insertTemplate(weeklyTemplate)

        // When
        let result = try await useCase.execute(upToDate: now)

        // Then
        // 10일 전부터 오늘까지: 약 1-2주 정도의 처리 예상
        XCTAssertGreaterThan(result, 0)
        XCTAssertLessThanOrEqual(result, 3) // 최대 3주 정도
    }

    // MARK: - Performance Tests

    func testExecute_withManyTemplates_performsEfficiently() async throws {
        // Given: 많은 수의 템플릿
        templateRepository.loadScenario(.custom(count: 100))

        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await useCase.execute(upToDate: Date())
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

        // Then
        XCTAssertLessThan(timeElapsed, 1.0) // 1초 이내 처리
        XCTAssertGreaterThanOrEqual(result, 0)
    }
}

// MARK: - Helper Extensions

private extension ProcessDueTemplatesUseCaseTests {

    func createCustomTemplate(
        recurrencePeriod: RecurrencePeriod,
        nextDueDate: Date?,
        processedCount: Int = 1
    ) -> TransactionTemplateDTO {
        return TestDataFactory.createTransactionTemplate(
            amount: 10000,
            place: "테스트",
            memo: "테스트 메모",
            transactionType: .fixedExpense,
            recurrencePeriod: recurrencePeriod,
            processedCount: processedCount,
            lastAddedAt: nil,
            nextDueDate: nextDueDate,
            subCategory: CategoryFactory.createSubCategory(
                name: "테스트카테고리",
                transactionType: .fixedExpense,
                parentCategory: CategoryFactory.createCategory(
                    name: "테스트", iconName: "test", transactionType: .fixedExpense, orderIndex: 0
                ),
                orderIndex: 0
            ),
            paymentMethod: PaymentMethodFactory.create(name: "테스트카드", kind: .credit)
        )
    }

    func createCustomTemplateWithCreatedAt(
        recurrencePeriod: RecurrencePeriod,
        createdAt: Date,
        processedCount: Int = 1,
        nextDueDate: Date?
    ) -> TransactionTemplateDTO {
        return TransactionTemplateDTO(
            amount: 10000,
            place: "테스트",
            memo: "테스트 메모",
            transactionType: .fixedExpense,
            recurrencePeriod: recurrencePeriod,
            createdAt: createdAt,
            processedCount: processedCount,
            lastAddedAt: createdAt,
            nextDueDate: nextDueDate,
            subCategory: CategoryFactory.createSubCategory(
                name: "테스트카테고리",
                transactionType: .fixedExpense,
                parentCategory: CategoryFactory.createCategory(
                    name: "테스트", iconName: "test", transactionType: .fixedExpense, orderIndex: 0
                ),
                orderIndex: 0
            ),
            paymentMethod: PaymentMethodFactory.create(name: "테스트카드", kind: .credit)
        )
    }
}
