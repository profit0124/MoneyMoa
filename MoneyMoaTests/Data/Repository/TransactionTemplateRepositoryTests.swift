//
//  TransactionTemplateRepositoryTests.swift
//  MoneyMoaTests
//
//  Created by Sooik Kim on 9/15/25.
//

import XCTest
import SwiftData
@testable import MoneyMoa

final class TransactionTemplateRepositoryTests: XCTestCase {

    private var database: Database!
    private var repository: TransactionTemplateRepositoryImpl!
    private var templateReader: TransactionTemplateReader!
    private var templateWriter: TransactionTemplateWriter!

    // 테스트용 기본 데이터
    private var testCategory: CategoryModel!
    private var testSubCategory: SubCategoryModel!
    private var testPaymentMethod: PaymentMethodModel!
    private var testSubCategoryDTO: SubCategoryDTO!
    private var testPaymentMethodDTO: PaymentMethodDTO!

    override func setUpWithError() throws {
        database = try Database(isStoredInMemoryOnly: true)
        repository = TransactionTemplateRepositoryImpl(database: database)

        // Interface Segregation을 위한 분리된 인터페이스
        templateReader = repository
        templateWriter = repository
    }

    override func tearDownWithError() throws {
        database = nil
        repository = nil
        templateReader = nil
        templateWriter = nil
        testCategory = nil
        testSubCategory = nil
        testPaymentMethod = nil
        testSubCategoryDTO = nil
        testPaymentMethodDTO = nil
    }

    private func setupBasicTestData() async throws {
        try await database.withModelContext { [self] context in
            // CategoryFactory를 사용하여 카테고리 생성
            let categoryDTO = CategoryFactory.createCategory(
                name: "구독",
                iconName: "tv",
                transactionType: .fixedExpense,
                orderIndex: 0
            )
            testCategory = categoryDTO.toModel()
            context.insert(testCategory)

            // SubCategory 생성
            testSubCategoryDTO = CategoryFactory.createSubCategory(
                name: "스트리밍",
                transactionType: .fixedExpense,
                parentCategory: categoryDTO,
                orderIndex: 0
            )
            testSubCategory = testSubCategoryDTO.toModel(parentCategory: testCategory)
            context.insert(testSubCategory)

            // PaymentMethodFactory를 사용하여 결제수단 생성
            testPaymentMethodDTO = PaymentMethodFactory.create(
                name: "신용카드",
                kind: .credit,
                orderIndex: 0
            )
            testPaymentMethod = testPaymentMethodDTO.toModel()
            context.insert(testPaymentMethod)

            try context.save()
        }
    }

    // MARK: - Helper Methods

    private func createTemplate(
        amount: Decimal = 100000,
        place: String? = "넷플릭스",
        memo: String? = "월간 구독",
        transactionType: TransactionType = .fixedExpense,
        recurrencePeriod: RecurrencePeriod = .monthly,
        lastAddedAt: Date? = nil,
        nextDueDate: Date? = nil
    ) -> TransactionTemplateDTO {
        return TestDataFactory.createTransactionTemplate(
            amount: amount,
            place: place,
            memo: memo,
            transactionType: transactionType,
            recurrencePeriod: recurrencePeriod,
            lastAddedAt: lastAddedAt,
            nextDueDate: nextDueDate,
            subCategory: testSubCategoryDTO,
            paymentMethod: testPaymentMethodDTO
        )
    }
}

// MARK: - TransactionTemplateReader Tests

extension TransactionTemplateRepositoryTests {

    // MARK: - Fetch Single Template Tests

    func testTemplateReader_fetchTemplate_withExistingId_returnsTemplate() async throws {
        // Given
        try await setupBasicTestData()
        let originalTemplate = createTemplate()
        try await templateWriter.insertTemplate(originalTemplate, shouldSave: true)

        // When
        let template = try await templateReader.fetchTemplate(id: originalTemplate.id)

        // Then
        XCTAssertNotNil(template)
        XCTAssertEqual(template?.id, originalTemplate.id)
        XCTAssertEqual(template?.amount, originalTemplate.amount)
        XCTAssertEqual(template?.place, originalTemplate.place)
        XCTAssertEqual(template?.memo, originalTemplate.memo)
        XCTAssertEqual(template?.recurrencePeriod, originalTemplate.recurrencePeriod)
    }

    func testTemplateReader_fetchTemplate_withNonExistingId_returnsNil() async throws {
        // Given
        try await setupBasicTestData()
        let randomId = UUID()

        // When
        let template = try await templateReader.fetchTemplate(id: randomId)

        // Then
        XCTAssertNil(template)
    }

    func testTemplateReader_fetchAllTemplates_returnsAllTemplates() async throws {
        try await setupBasicTestData()
        let template1 = createTemplate(place: "넷플릭스")
        let template2 = createTemplate(place: "스포티파이")

        try await templateWriter.insertTemplate(template1, shouldSave: true)
        try await templateWriter.insertTemplate(template2, shouldSave: true)

        let templates = try await templateReader.fetchAllTemplates()
        XCTAssertEqual(templates.count, 2)
    }

    // MARK: - Fetch Templates Due for Processing Tests

    func testTemplateReader_fetchTemplatesDueForProcessing_returnsDueTemplates() async throws {
        // Given
        try await setupBasicTestData()
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!

        let dueTemplate = createTemplate(
            place: "넷플릭스",
            nextDueDate: yesterday
        )
        let notDueTemplate = createTemplate(
            place: "스포티파이",
            nextDueDate: tomorrow
        )
        let noDateTemplate = createTemplate(
            place: "월세",
            recurrencePeriod: .none,
            nextDueDate: nil
        )

        try await templateWriter.insertTemplate(dueTemplate, shouldSave: true)
        try await templateWriter.insertTemplate(notDueTemplate, shouldSave: true)
        try await templateWriter.insertTemplate(noDateTemplate, shouldSave: true)

        // When
        let templates = try await templateReader.fetchTemplatesDueForProcessing(before: now)

        // Then
        XCTAssertEqual(templates.count, 1)
        XCTAssertEqual(templates.first?.place, "넷플릭스")
    }

}

// MARK: - TransactionTemplateWriter Tests

extension TransactionTemplateRepositoryTests {

    // MARK: - Insert Template Tests

    func testTemplateWriter_insertTemplate_createsNewTemplate() async throws {
        // Given
        try await setupBasicTestData()
        let newTemplate = createTemplate()

        // When
        try await templateWriter.insertTemplate(newTemplate, shouldSave: true)

        // Then
        let fetchedTemplate = try await templateReader.fetchTemplate(id: newTemplate.id)
        XCTAssertNotNil(fetchedTemplate)
        XCTAssertEqual(fetchedTemplate?.amount, newTemplate.amount)
        XCTAssertEqual(fetchedTemplate?.place, newTemplate.place)
        XCTAssertEqual(fetchedTemplate?.recurrencePeriod, newTemplate.recurrencePeriod)
    }

    func testTemplateWriter_insertTemplate_withInvalidSubCategory_throwsError() async throws {
        try await setupBasicTestData()
        let fakeCategory = CategoryFactory.createCategory(
            id: UUID(), name: "FakeCategory", iconName: "xmark",
            transactionType: .variableExpense, orderIndex: 0
        )
        let invalidSubCategoryDTO = CategoryFactory.createSubCategory(
            id: UUID(), name: "Invalid", transactionType: .variableExpense,
            parentCategory: fakeCategory, orderIndex: 0
        )

        let template = TransactionTemplateDTO(
            amount: 10000, place: "Test", memo: "Test",
            transactionType: .fixedExpense, recurrencePeriod: .monthly,
            lastAddedAt: nil, nextDueDate: nil,
            subCategory: invalidSubCategoryDTO, paymentMethod: testPaymentMethodDTO
        )

        do {
            try await templateWriter.insertTemplate(template, shouldSave: true)
            XCTFail("Should throw subCategoryNotFound error")
        } catch {
            if case RepositoryError.subCategoryNotFound = error {
                // Expected
            } else {
                XCTFail("Expected subCategoryNotFound error, but got \(error)")
            }
        }
    }

    // MARK: - Update Template Tests

    func testTemplateWriter_updateTemplate_modifiesExistingTemplate() async throws {
        // Given
        try await setupBasicTestData()
        let originalTemplate = createTemplate(amount: 10000, place: "넷플릭스")
        try await templateWriter.insertTemplate(originalTemplate, shouldSave: true)

        // When
        let updatedTemplate = TransactionTemplateDTO(
            id: originalTemplate.id,
            amount: 20000,
            place: "넷플릭스 프리미엄",
            memo: "업그레이드",
            transactionType: originalTemplate.transactionType,
            recurrencePeriod: originalTemplate.recurrencePeriod,
            lastAddedAt: originalTemplate.lastAddedAt,
            nextDueDate: originalTemplate.nextDueDate,
            subCategory: originalTemplate.subCategory,
            paymentMethod: originalTemplate.paymentMethod,
            recurrencePattern: originalTemplate.recurrencePattern,
            executionState: originalTemplate.executionState
        )
        try await templateWriter.updateTemplate(updatedTemplate)

        // Then
        let fetchedTemplate = try await templateReader.fetchTemplate(id: originalTemplate.id)
        XCTAssertEqual(fetchedTemplate?.amount, 20000)
        XCTAssertEqual(fetchedTemplate?.place, "넷플릭스 프리미엄")
        XCTAssertEqual(fetchedTemplate?.memo, "업그레이드")
    }

    func testTemplateWriter_updateTemplate_withNonExistingId_throwsError() async throws {
        try await setupBasicTestData()
        let nonExistingTemplate = createTemplate()

        do {
            try await templateWriter.updateTemplate(nonExistingTemplate)
            XCTFail("Should throw templateNotFound error")
        } catch {
            if case RepositoryError.custom(let message) = error {
                XCTAssertEqual(message, "Transaction template not found")
            } else {
                XCTFail("Expected templateNotFound error, but got \(error)")
            }
        }
    }

    // MARK: - Update Template Processing Tests

    func testTemplateWriter_updateTemplateProcessing_updatesProcessingFields() async throws {
        // Given
        try await setupBasicTestData()
        let originalTemplate = createTemplate()
        try await templateWriter.insertTemplate(originalTemplate, shouldSave: true)

        let newLastAddedAt = Date()
        let newNextDueDate = Calendar.current.date(byAdding: .month, value: 1, to: newLastAddedAt)

        // When
        let executionState = TemplateExecutionState(
            lastExecutedAt: newLastAddedAt,
            executionCount: 5
        )

        try await templateWriter.updateTemplateProcessing(
            id: originalTemplate.id,
            executionState: executionState,
            lastAddedAt: newLastAddedAt,
            nextDueDate: newNextDueDate
        )

        // Then
        let fetchedTemplate = try await templateReader.fetchTemplate(id: originalTemplate.id)
        XCTAssertEqual(fetchedTemplate?.effectiveExecutionState.executionCount, 5)
        XCTAssertNotNil(fetchedTemplate?.nextDueDate)
    }

    func testTemplateWriter_updateTemplateProcessing_withNonExistingId_throwsError() async throws {
        try await setupBasicTestData()
        let randomId = UUID()

        do {
            let executionState = TemplateExecutionState(
                lastExecutedAt: Date(),
                executionCount: 1
            )
            try await templateWriter.updateTemplateProcessing(
                id: randomId, executionState: executionState, lastAddedAt: Date(), nextDueDate: nil
            )
            XCTFail("Should throw templateNotFound error")
        } catch {
            if case RepositoryError.custom(let message) = error {
                XCTAssertEqual(message, "Transaction template not found")
            } else {
                XCTFail("Expected templateNotFound error, but got \(error)")
            }
        }
    }

    // MARK: - Delete Template Tests

    func testTemplateWriter_deleteTemplate_removesTemplate() async throws {
        try await setupBasicTestData()
        let template = createTemplate()
        try await templateWriter.insertTemplate(template, shouldSave: true)

        try await templateWriter.deleteTemplate(id: template.id)

        let deletedTemplate = try await templateReader.fetchTemplate(id: template.id)
        XCTAssertNil(deletedTemplate)
    }

    func testTemplateWriter_deleteTemplate_withNonExistingId_throwsError() async throws {
        try await setupBasicTestData()

        do {
            try await templateWriter.deleteTemplate(id: UUID())
            XCTFail("Should throw templateNotFound error")
        } catch {
            if case RepositoryError.custom(let message) = error {
                XCTAssertEqual(message, "Transaction template not found")
            } else {
                XCTFail("Expected templateNotFound error, but got \(error)")
            }
        }
    }
}

// MARK: - Integration Tests

extension TransactionTemplateRepositoryTests {

    func testIntegration_createUpdateAndDelete_worksCorrectly() async throws {
        try await setupBasicTestData()

        let template = createTemplate(amount: 10000, place: "초기")
        try await templateWriter.insertTemplate(template, shouldSave: true)

        var fetchedTemplate = try await templateReader.fetchTemplate(id: template.id)
        XCTAssertEqual(fetchedTemplate?.place, "초기")

        let updatedTemplate = TransactionTemplateDTO(
            id: template.id, amount: 20000, place: "수정됨", memo: template.memo,
            transactionType: template.transactionType, recurrencePeriod: template.recurrencePeriod,
            lastAddedAt: template.lastAddedAt,
            nextDueDate: template.nextDueDate, subCategory: template.subCategory,
            paymentMethod: template.paymentMethod,
            recurrencePattern: template.recurrencePattern,
            executionState: template.executionState
        )
        try await templateWriter.updateTemplate(updatedTemplate)

        fetchedTemplate = try await templateReader.fetchTemplate(id: template.id)
        XCTAssertEqual(fetchedTemplate?.place, "수정됨")

        try await templateWriter.deleteTemplate(id: template.id)
        fetchedTemplate = try await templateReader.fetchTemplate(id: template.id)
        XCTAssertNil(fetchedTemplate)
    }

    func testIntegration_templateProcessingWorkflow_worksCorrectly() async throws {
        try await setupBasicTestData()
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!

        let template1 = createTemplate(place: "넷플릭스", nextDueDate: yesterday)
        let template2 = createTemplate(place: "유튜브", nextDueDate: yesterday)

        try await templateWriter.insertTemplate(template1, shouldSave: true)
        try await templateWriter.insertTemplate(template2, shouldSave: true)

        let dueTemplates = try await templateReader.fetchTemplatesDueForProcessing(before: now)
        XCTAssertEqual(dueTemplates.count, 2)

        for template in dueTemplates {
            let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: now)
            let currentExecutionCount = template.effectiveExecutionState.executionCount
            let executionState = TemplateExecutionState(
                lastExecutedAt: now,
                executionCount: currentExecutionCount + 1
            )
            try await templateWriter.updateTemplateProcessing(
                id: template.id, executionState: executionState,
                lastAddedAt: now, nextDueDate: nextMonth
            )
        }

        let remainingDueTemplates = try await templateReader.fetchTemplatesDueForProcessing(before: now)
        XCTAssertEqual(remainingDueTemplates.count, 0)
    }
}
