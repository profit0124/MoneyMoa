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
        // Given: 빈 데이터베이스
        
        // When: 모든 결제수단 조회
        let paymentMethods = try await repository.fetchPaymentMethods()
        
        // Then: 빈 배열 반환
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
        // Given: 존재하지 않는 ID
        let nonExistentId = UUID()
        
        // When: 조회 시도
        let paymentMethod = try await repository.fetchPaymentMethod(id: nonExistentId)
        
        // Then: nil 반환
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
        // Given: 존재하지 않는 결제수단 ID
        let nonExistingId = UUID()
        
        // When & Then: 에러 발생
        do {
            try await repository.deactivatePaymentMethod(id: nonExistingId)
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
    
    func testDeletePaymentMethod_InactivePaymentMethod_Success() async throws {
        // Given: 비활성 결제수단 생성
        let paymentMethod = PaymentMethodFactory.inactiveCard()
        try await repository.insertPaymentMethod(paymentMethod)
        
        // When: 결제수단 삭제
        try await repository.deletePaymentMethod(id: paymentMethod.id)
        
        // Then: 데이터베이스에서 삭제됨
        let paymentMethods = try await repository.fetchPaymentMethods()
        XCTAssertTrue(paymentMethods.isEmpty)
    }
    
    func testDeletePaymentMethod_ActivePaymentMethod_ThrowsError() async throws {
        // Given: 활성 결제수단 생성
        let paymentMethod = PaymentMethodFactory.create(
            name: "활성카드",
            kind: .credit,
            isActive: true
        )
        try await repository.insertPaymentMethod(paymentMethod)
        
        // When & Then: 에러 발생
        do {
            try await repository.deletePaymentMethod(id: paymentMethod.id)
            XCTFail("Expected error to be thrown")
        } catch RepositoryError.cannotDeleteActivePaymentMethod {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // 결제수단이 여전히 존재함
        let paymentMethods = try await repository.fetchPaymentMethods()
        XCTAssertEqual(paymentMethods.count, 1)
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
        // Given: 여러 결제수단 생성
        let paymentMethods = PaymentMethodFactory.standardSet()
        for paymentMethod in paymentMethods {
            try await repository.insertPaymentMethod(paymentMethod)
        }
        
        // 거래 데이터 추가 (실제 구현시)
        // Note: 실제 테스트에서는 Transaction 데이터를 함께 생성해야 함
        
        // When: 사용 통계 조회
        let usageStats = try await repository.fetchPaymentMethodUsageStats(limit: 10)
        
        // Then: 결과 검증
        XCTAssertNotNil(usageStats)
        // 실제 구현시 더 상세한 검증 필요
    }
    
    func testFetchPaymentMethodAmountSummary() async throws {
        // Given: 결제수단들 생성
        let paymentMethods = PaymentMethodFactory.minimalSet()
        for paymentMethod in paymentMethods {
            try await repository.insertPaymentMethod(paymentMethod)
        }
        
        let startDate = YearMonth.current.startOfMonth
        let endDate = YearMonth.current.endOfMonth
        
        // When: 금액 집계 조회
        let amountSummary = try await repository.fetchPaymentMethodAmountSummary(
            startDate: startDate,
            endDate: endDate
        )
        
        // Then: 결과 검증
        XCTAssertNotNil(amountSummary)
        // 실제 구현시 더 상세한 검증 필요
    }
}
