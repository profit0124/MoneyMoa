//
//  PaymentMethodRepositoryTests.swift
//  MoneyMoaTests
//
//  Created by Sooik Kim on 7/28/25.
//

import XCTest
import SwiftData
@testable import MoneyMoa

final class PaymentMethodRepositoryTests: XCTestCase {
    
    private var database: Database!
    private var repository: PaymentMethodRepositoryImpl!
    
    override func setUpWithError() throws {
        // 각 테스트마다 새로운 인메모리 데이터베이스 생성
        database = try Database(isStoredInMemoryOnly: true)
        repository = PaymentMethodRepositoryImpl(database: database)
    }
    
    override func tearDownWithError() throws {
        database = nil
        repository = nil
    }
    
    // MARK: - 조회 테스트 (Fetch Operations)
    
    func testFetchPaymentMethods_EmptyDatabase() async throws {
        let paymentMethods = try await repository.fetchPaymentMethods()
        XCTAssertTrue(paymentMethods.isEmpty)
    }
    
    func testFetchPaymentMethods_WithData() async throws {
        // Given: Factory를 사용한 테스트 데이터
        let testData = PaymentMethodFactory.standardSet()
        for paymentMethod in testData {
            try await repository.insertPaymentMethod(paymentMethod)
        }
        
        // When: 모든 결제수단 조회
        let paymentMethods = try await repository.fetchPaymentMethods()
        
        // Then: orderIndex 순으로 정렬되어 반환
        XCTAssertEqual(paymentMethods.count, 4)
        XCTAssertEqual(paymentMethods[0].name, "현금") // orderIndex: 0
        XCTAssertEqual(paymentMethods[1].name, "체크카드") // orderIndex: 1
        XCTAssertEqual(paymentMethods[2].name, "신용카드") // orderIndex: 2
        XCTAssertEqual(paymentMethods[3].name, "계좌이체") // orderIndex: 3
    }
    
    func testFetchPaymentMethod_ExistingId() async throws {
        // Given: Factory를 사용한 단일 결제수단
        let paymentMethod = PaymentMethodFactory.create(
            name: "테스트카드",
            kind: .credit
        )
        try await repository.insertPaymentMethod(paymentMethod)
        
        // When: ID로 조회
        let fetchedPaymentMethod = try await repository.fetchPaymentMethod(id: paymentMethod.id)
        
        // Then: 정확히 일치하는 데이터 반환
        XCTAssertNotNil(fetchedPaymentMethod)
        XCTAssertEqual(fetchedPaymentMethod?.id, paymentMethod.id)
        XCTAssertEqual(fetchedPaymentMethod?.name, "테스트카드")
        XCTAssertEqual(fetchedPaymentMethod?.kind, .credit)
    }
    
    func testFetchPaymentMethod_NonExistingId() async throws {
        let paymentMethod = try await repository.fetchPaymentMethod(id: UUID())
        XCTAssertNil(paymentMethod)
    }
    
    func testFetchActivePaymentMethods() async throws {
        // Given: 활성/비활성 혼합 데이터
        let activePaymentMethod = PaymentMethodFactory.create(
            name: "활성카드",
            kind: .credit,
            isActive: true
        )
        let inactivePaymentMethod = PaymentMethodFactory.inactiveCard()
        
        try await repository.insertPaymentMethod(activePaymentMethod)
        try await repository.insertPaymentMethod(inactivePaymentMethod)
        
        // When: 활성 결제수단만 조회
        let paymentMethods = try await repository.fetchActivePaymentMethods()
        
        // Then: 활성 결제수단만 반환
        XCTAssertEqual(paymentMethods.count, 1)
        XCTAssertEqual(paymentMethods.first?.name, "활성카드")
        XCTAssertTrue(paymentMethods.first?.isActive ?? false)
    }
    
    func testFetchPaymentMethodsByKind() async throws {
        // Given: 다양한 종류의 결제수단
        let testData = PaymentMethodFactory.diverseSet()
        for paymentMethod in testData {
            try await repository.insertPaymentMethod(paymentMethod)
        }
        
        // When: 신용카드 종류만 조회
        let creditCards = try await repository.fetchPaymentMethodsByKind(.credit)
        
        // Then: 해당 종류의 활성 결제수단만 반환
        XCTAssertEqual(creditCards.count, 3)
        XCTAssertTrue(creditCards.allSatisfy { $0.kind == .credit && $0.isActive })
    }
    
    // MARK: - 생성/수정 테스트 (Create/Update Operations)
    
    func testInsertPaymentMethod_Success() async throws {
        // Given: Factory로 생성한 결제수단
        let paymentMethod = PaymentMethodFactory.create(
            name: "새카드",
            kind: .debit
        )
        
        // When: 결제수단 삽입
        try await repository.insertPaymentMethod(paymentMethod)
        
        // Then: 데이터베이스에 저장됨
        let paymentMethods = try await repository.fetchPaymentMethods()
        XCTAssertEqual(paymentMethods.count, 1)
        XCTAssertEqual(paymentMethods.first?.name, "새카드")
        XCTAssertEqual(paymentMethods.first?.id, paymentMethod.id)
    }
    
    func testUpdatePaymentMethod_Success() async throws {
        // Given: 기존 결제수단 생성
        let originalPaymentMethod = PaymentMethodFactory.create(
            name: "기존카드",
            kind: .credit,
            orderIndex: 0
        )
        try await repository.insertPaymentMethod(originalPaymentMethod)
        
        // When: 결제수단 정보 수정
        let updatedPaymentMethod = PaymentMethodDTO(
            id: originalPaymentMethod.id,
            name: "수정된카드",
            kind: .credit,
            orderIndex: 1,
            isActive: false
        )
        try await repository.updatePaymentMethod(updatedPaymentMethod)
        
        // Then: 변경사항이 반영됨
        let paymentMethod = try await repository.fetchPaymentMethod(id: originalPaymentMethod.id)
        XCTAssertEqual(paymentMethod?.name, "수정된카드")
        XCTAssertFalse(paymentMethod?.isActive ?? true)
        XCTAssertEqual(paymentMethod?.orderIndex, 1)
    }
    
    func testUpdatePaymentMethod_NonExistingPaymentMethod() async throws {
        // Given: 존재하지 않는 결제수단
        let nonExistingPaymentMethod = PaymentMethodFactory.create(
            name: "존재하지않음",
            kind: .credit
        )
        
        // When & Then: 에러 발생
        do {
            try await repository.updatePaymentMethod(nonExistingPaymentMethod)
            XCTFail("Expected error but succeeded")
        } catch RepositoryError.paymentMethodNotFound {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testUpdatePaymentMethodOrder() async throws {
        // Given: 여러 결제수단 생성
        let paymentMethods = PaymentMethodFactory.minimalSet()
        for paymentMethod in paymentMethods {
            try await repository.insertPaymentMethod(paymentMethod)
        }
        
        // When: 순서 변경 (역순으로)
        let reorderedPaymentMethods = paymentMethods.reversed()
        try await repository.updatePaymentMethodOrder(Array(reorderedPaymentMethods))
        
        // Then: 새로운 순서로 정렬됨
        let fetchedPaymentMethods = try await repository.fetchPaymentMethods()
        XCTAssertEqual(fetchedPaymentMethods.count, paymentMethods.count)
        XCTAssertEqual(fetchedPaymentMethods.first?.name, paymentMethods.last?.name)
        XCTAssertEqual(fetchedPaymentMethods.last?.name, paymentMethods.first?.name)
    }
    
    // MARK: - 활성/비활성 관리 테스트 (Activation Management)
    
    func testDeactivatePaymentMethod_Success() async throws {
        // Given: 활성 결제수단 생성
        let paymentMethod = PaymentMethodFactory.create(
            name: "활성카드",
            kind: .credit,
            isActive: true
        )
        try await repository.insertPaymentMethod(paymentMethod)
        
        // When: 결제수단 비활성화
        try await repository.deactivatePaymentMethod(id: paymentMethod.id)
        
        // Then: 비활성 상태로 변경됨
        let updatedPaymentMethod = try await repository.fetchPaymentMethod(id: paymentMethod.id)
        XCTAssertFalse(updatedPaymentMethod?.isActive ?? true)
    }
    
    func testDeactivatePaymentMethod_NonExistingPaymentMethod() async throws {
        do {
            try await repository.deactivatePaymentMethod(id: UUID())
            XCTFail("Expected error to be thrown")
        } catch RepositoryError.paymentMethodNotFound {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testActivatePaymentMethod_Success() async throws {
        // Given: 비활성 결제수단 생성
        let paymentMethod = PaymentMethodFactory.create(
            name: "비활성카드",
            kind: .credit,
            isActive: false
        )
        try await repository.insertPaymentMethod(paymentMethod)
        
        // When: 결제수단 활성화
        try await repository.activatePaymentMethod(id: paymentMethod.id)
        
        // Then: 활성 상태로 변경됨
        let updatedPaymentMethod = try await repository.fetchPaymentMethod(id: paymentMethod.id)
        XCTAssertTrue(updatedPaymentMethod?.isActive ?? false)
    }
    
    // MARK: - 삭제 테스트 (Delete Operations)

    // MARK: - Test Helpers

    private func createTestSubCategory(
        name: String,
        transactionType: TransactionType
    ) async throws -> SubCategoryDTO {
        let category = TestDataFactory.createCategory(
            name: "\(name) 카테고리",
            iconName: "folder.fill",
            type: transactionType,
            orderIndex: 0
        )
        let categoryRepository = CategoryRepositoryImpl(database: database)
        try await categoryRepository.insertCategory(category)

        let subCategory = TestDataFactory.createSubCategory(
            name: name,
            categoryId: category.id,
            categoryName: category.name,
            categoryIconName: category.iconName,
            type: transactionType,
            orderIndex: 0
        )
        try await categoryRepository.insertSubCategory(subCategory)

        return subCategory
    }

    private func createTestTransaction(
        paymentMethod: PaymentMethodDTO,
        subCategory: SubCategoryDTO,
        amount: Decimal = 10000
    ) async throws {
        let transactionRepository = TransactionRepositoryImpl(database: database)
        let transaction = TestDataFactory.createTransaction(
            amount: amount,
            transactionType: subCategory.transactionType,
            subCategory: subCategory,
            paymentMethod: paymentMethod
        )
        try await transactionRepository.insertTransaction(transaction)
    }

    private func createTestTemplate(
        paymentMethod: PaymentMethodDTO,
        subCategory: SubCategoryDTO,
        amount: Decimal = 50000,
        recurrencePeriod: RecurrencePeriod = .monthly
    ) async throws {
        let templateRepository = TransactionTemplateRepositoryImpl(database: database)
        let template = TestDataFactory.createTransactionTemplate(
            amount: amount,
            transactionType: subCategory.transactionType,
            recurrencePeriod: recurrencePeriod,
            subCategory: subCategory,
            paymentMethod: paymentMethod
        )
        try await templateRepository.insertTemplate(template)
    }

    func testDeletePaymentMethod_NoReferences_HardDelete() async throws {
        // Given: 참조가 없는 결제수단
        let paymentMethod = TestDataFactory.createPaymentMethod(name: "테스트카드", kind: .credit)
        try await repository.insertPaymentMethod(paymentMethod)

        // When: 삭제
        try await repository.deletePaymentMethod(id: paymentMethod.id)

        // Then: Hard delete
        let result = try await repository.fetchPaymentMethods()
        XCTAssertTrue(result.isEmpty)
    }

    func testDeletePaymentMethod_WithTransactions_SoftDelete() async throws {
        // Given: Transaction이 있는 결제수단
        let paymentMethod = TestDataFactory.createPaymentMethod(name: "신한카드", kind: .credit)
        try await repository.insertPaymentMethod(paymentMethod)

        let subCategory = try await createTestSubCategory(name: "외식", transactionType: .variableExpense)
        try await createTestTransaction(paymentMethod: paymentMethod, subCategory: subCategory)

        // When: 삭제
        try await repository.deletePaymentMethod(id: paymentMethod.id)

        // Then: Soft delete
        let result = try await repository.fetchPaymentMethod(id: paymentMethod.id)
        XCTAssertNotNil(result)
        XCTAssertFalse(result?.isActive ?? true)
        let allPaymentMethods = try await repository.fetchPaymentMethods()
        XCTAssertEqual(allPaymentMethods.count, 1)
    }

    func testDeletePaymentMethod_WithTemplates_ThrowsError() async throws {
        // Given: Template이 있는 결제수단
        let paymentMethod = TestDataFactory.createPaymentMethod(name: "국민카드", kind: .credit)
        try await repository.insertPaymentMethod(paymentMethod)

        let subCategory = try await createTestSubCategory(name: "월세", transactionType: .fixedExpense)
        try await createTestTemplate(paymentMethod: paymentMethod, subCategory: subCategory)

        // When & Then: 에러 발생
        do {
            try await repository.deletePaymentMethod(id: paymentMethod.id)
            XCTFail("Expected hasActiveTemplates error")
        } catch RepositoryError.hasActiveTemplates {
            // Expected
        }

        // 여전히 활성 상태
        let result = try await repository.fetchPaymentMethod(id: paymentMethod.id)
        XCTAssertTrue(result?.isActive ?? false)
    }

    func testDeletePaymentMethod_WithBothTransactionsAndTemplates_ThrowsError() async throws {
        // Given: Transaction과 Template 모두 있음
        let paymentMethod = TestDataFactory.createPaymentMethod(name: "우리카드", kind: .credit)
        try await repository.insertPaymentMethod(paymentMethod)

        let subCategory = try await createTestSubCategory(name: "지하철", transactionType: .variableExpense)
        try await createTestTransaction(paymentMethod: paymentMethod, subCategory: subCategory, amount: 5000)
        try await createTestTemplate(paymentMethod: paymentMethod, subCategory: subCategory, amount: 10000, recurrencePeriod: .weekly)

        // When & Then: Template 우선 차단
        do {
            try await repository.deletePaymentMethod(id: paymentMethod.id)
            XCTFail("Expected hasActiveTemplates error")
        } catch RepositoryError.hasActiveTemplates {
            // Expected
        }

        let result = try await repository.fetchPaymentMethod(id: paymentMethod.id)
        XCTAssertTrue(result?.isActive ?? false)
    }

    func testDeletePaymentMethod_NonExisting_ThrowsError() async throws {
        // When & Then
        do {
            try await repository.deletePaymentMethod(id: UUID())
            XCTFail("Expected paymentMethodNotFound error")
        } catch RepositoryError.paymentMethodNotFound {
            // Expected
        }
    }
    
    // MARK: - 검증 테스트 (Validation)
    
    func testValidatePaymentMethodName_AvailableName() async throws {
        // Given: 기존 결제수단 생성
        let existingPaymentMethod = PaymentMethodFactory.create(
            name: "국민카드",
            kind: .credit
        )
        try await repository.insertPaymentMethod(existingPaymentMethod)
        
        // When: 다른 이름으로 검증
        let isValid = try await repository.validatePaymentMethodName("신한카드", kind: .credit, excludingId: nil)
        
        // Then: 사용 가능
        XCTAssertTrue(isValid)
    }
    
    func testValidatePaymentMethodName_DuplicateName_SameKind() async throws {
        // Given: 기존 결제수단 생성
        let existingPaymentMethod = PaymentMethodFactory.create(
            name: "국민카드",
            kind: .credit
        )
        try await repository.insertPaymentMethod(existingPaymentMethod)
        
        // When: 동일한 이름과 종류로 검증
        let isValid = try await repository.validatePaymentMethodName("국민카드", kind: .credit, excludingId: nil)
        
        // Then: 사용 불가능
        XCTAssertFalse(isValid)
    }
    
    func testValidatePaymentMethodName_DuplicateNameButDifferentKind() async throws {
        // Given: 기존 결제수단 생성 (신용카드)
        let existingPaymentMethod = PaymentMethodFactory.create(
            name: "국민카드",
            kind: .credit
        )
        try await repository.insertPaymentMethod(existingPaymentMethod)
        
        // When: 동일한 이름이지만 다른 종류로 검증 (체크카드)
        let isValid = try await repository.validatePaymentMethodName("국민카드", kind: .debit, excludingId: nil)
        
        // Then: 사용 가능 (다른 결제수단 종류이므로)
        XCTAssertTrue(isValid)
    }
    
    func testValidatePaymentMethodName_ExcludingSelf() async throws {
        // Given: 기존 결제수단 생성
        let existingPaymentMethod = PaymentMethodFactory.create(
            name: "국민카드",
            kind: .credit
        )
        try await repository.insertPaymentMethod(existingPaymentMethod)
        
        // When: 자기 자신을 제외하고 검증 (수정 시나리오)
        let isValid = try await repository.validatePaymentMethodName(
            "국민카드",
            kind: .credit,
            excludingId: existingPaymentMethod.id
        )
        
        // Then: 사용 가능 (자기 자신 제외)
        XCTAssertTrue(isValid)
    }
    
    // MARK: - 통계 테스트 (Statistics)
    
    func testFetchPaymentMethodUsageStats_WithMixedUsage() async throws {
        let paymentMethods = PaymentMethodFactory.standardSet()
        for paymentMethod in paymentMethods {
            try await repository.insertPaymentMethod(paymentMethod)
        }
        let usageStats = try await repository.fetchPaymentMethodUsageStats(limit: 10)
        XCTAssertNotNil(usageStats)
    }
    
    func testFetchPaymentMethodAmountSummary() async throws {
        let paymentMethods = PaymentMethodFactory.minimalSet()
        for paymentMethod in paymentMethods {
            try await repository.insertPaymentMethod(paymentMethod)
        }
        let amountSummary = try await repository.fetchPaymentMethodAmountSummary(
            startDate: YearMonth.current.startOfMonth,
            endDate: YearMonth.current.endOfMonth
        )
        XCTAssertNotNil(amountSummary)
    }
}
