//
//  CreatePaymentMethodUseCaseTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 9/4/25.
//

import XCTest
@testable import MoneyMoa

final class CreatePaymentMethodUseCaseTests: XCTestCase {
    
    private var useCase: CreatePaymentMethodUseCase!
    private var mockRepository: MockPaymentMethodRepository!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockPaymentMethodRepository(scenario: .empty)
        useCase = CreatePaymentMethodUseCaseImpl(paymentMethodRepository: mockRepository)
    }
    
    override func tearDown() {
        useCase = nil
        mockRepository = nil
        super.tearDown()
    }
    
    // MARK: - Success Cases
    
    func testExecute_withValidPaymentMethod_succeeds() async throws {
        // Given: 유효한 결제수단
        let paymentMethod = PaymentMethodFactory.create(
            name: "신한카드",
            kind: .credit
        )
        
        // When: 생성 실행
        try await useCase.execute(paymentMethod)
        
        // Then: 저장 확인
        let savedPaymentMethods = try await mockRepository.fetchPaymentMethods()
        XCTAssertEqual(savedPaymentMethods.count, 1)
        XCTAssertEqual(savedPaymentMethods.first?.name, "신한카드")
        XCTAssertEqual(savedPaymentMethods.first?.kind, .credit)
    }
    
    func testExecute_withMultiplePaymentMethods_succeeds() async throws {
        // Given: 여러 결제수단
        let paymentMethods = PaymentMethodFactory.standardSet()
        
        // When: 모두 생성
        for paymentMethod in paymentMethods {
            try await useCase.execute(paymentMethod)
        }
        
        // Then: 모두 저장됨
        let savedPaymentMethods = try await mockRepository.fetchPaymentMethods()
        XCTAssertEqual(savedPaymentMethods.count, paymentMethods.count)
    }
    
    func testExecute_withCustomIcon_preservesIcon() async throws {
        // Given: 커스텀 아이콘이 있는 결제수단
        let paymentMethod = PaymentMethodFactory.customIconCard()
        
        // When: 생성 실행
        try await useCase.execute(paymentMethod)
        
        // Then: 아이콘 정보 보존
        let savedPaymentMethods = try await mockRepository.fetchPaymentMethods()
        XCTAssertEqual(savedPaymentMethods.first?.iconName, "star.fill")
    }
    
    // MARK: - Validation Tests
    
    func testExecute_withEmptyName_throwsError() async throws {
        // Given: 빈 이름의 결제수단
        let paymentMethod = PaymentMethodFactory.create(
            name: "",
            kind: .credit
        )
        
        // When & Then: 에러 발생
        do {
            try await useCase.execute(paymentMethod)
            XCTFail("Expected error but succeeded")
        } catch PaymentMethodCreationError.emptyName {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testExecute_withWhitespaceName_throwsError() async throws {
        // Given: 공백만 있는 이름
        let paymentMethod = PaymentMethodFactory.create(
            name: "   ",
            kind: .credit
        )
        
        // When & Then: 에러 발생
        do {
            try await useCase.execute(paymentMethod)
            XCTFail("Expected error but succeeded")
        } catch PaymentMethodCreationError.emptyName {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testExecute_withDuplicateName_throwsError() async throws {
        // Given: 기존 결제수단 생성
        let existingPaymentMethod = PaymentMethodFactory.create(
            name: "국민카드",
            kind: .credit
        )
        mockRepository.loadScenario(.empty)
        try await mockRepository.insertPaymentMethod(existingPaymentMethod)
        
        // When: 동일한 이름과 종류로 생성 시도
        let duplicatePaymentMethod = PaymentMethodFactory.create(
            name: "국민카드",
            kind: .credit
        )
        
        // Then: 에러 발생
        do {
            try await useCase.execute(duplicatePaymentMethod)
            XCTFail("Expected error but succeeded")
        } catch PaymentMethodCreationError.duplicateName {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testExecute_withSameNameDifferentKind_succeeds() async throws {
        // Given: 신용카드로 "국민카드" 생성
        let creditCard = PaymentMethodFactory.create(
            name: "국민카드",
            kind: .credit
        )
        try await useCase.execute(creditCard)
        
        // When: 체크카드로 동일한 이름 생성
        let debitCard = PaymentMethodFactory.create(
            name: "국민카드",
            kind: .debit
        )
        try await useCase.execute(debitCard)
        
        // Then: 둘 다 저장됨 (종류가 다르므로 허용)
        let savedPaymentMethods = try await mockRepository.fetchPaymentMethods()
        XCTAssertEqual(savedPaymentMethods.count, 2)
        XCTAssertTrue(savedPaymentMethods.contains { $0.kind == .credit })
        XCTAssertTrue(savedPaymentMethods.contains { $0.kind == .debit })
    }
    
    // MARK: - Repository Error Handling
    
    func testExecute_whenRepositoryFails_throwsError() async throws {
        // Given: Repository 에러 설정
        mockRepository.shouldFail = true
        mockRepository.errorToThrow = MockError.simulatedFailure
        
        let paymentMethod = PaymentMethodFactory.create(
            name: "테스트카드",
            kind: .credit
        )
        
        // When & Then: 에러 전파
        do {
            try await useCase.execute(paymentMethod)
            XCTFail("Expected error but succeeded")
        } catch MockError.simulatedFailure {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Integration Tests
    
    func testExecute_withRealData_succeeds() async throws {
        // Given: 현실적인 데이터
        let paymentMethods = PaymentMethodFactory.realisticPersonalSet()
        
        // When: 모두 생성
        for paymentMethod in paymentMethods where !paymentMethod.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            try await useCase.execute(paymentMethod)
        }
        
        // Then: 정상 저장
        let savedPaymentMethods = try await mockRepository.fetchPaymentMethods()
        XCTAssertGreaterThan(savedPaymentMethods.count, 0)
    }
    
    func testExecute_withStressData_succeeds() async throws {
        // Given: 대량의 결제수단 (Factory 사용)
        let paymentMethods = PaymentMethodFactory.randomSet(count: 50)
        
        // When: 모두 생성
        for paymentMethod in paymentMethods {
            try await useCase.execute(paymentMethod)
        }
        
        // Then: 모두 저장됨
        let savedPaymentMethods = try await mockRepository.fetchPaymentMethods()
        XCTAssertEqual(savedPaymentMethods.count, paymentMethods.count)
    }
}
