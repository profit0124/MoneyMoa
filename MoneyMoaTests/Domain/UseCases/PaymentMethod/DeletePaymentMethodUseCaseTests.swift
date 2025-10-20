//
//  DeletePaymentMethodUseCaseTests.swift
//  MoneyMoaTests
//
//  Created by Sooik Kim on 10/20/25.
//

import XCTest
@testable import MoneyMoa

@MainActor
final class DeletePaymentMethodUseCaseTests: XCTestCase {

    // MARK: - Properties

    private var useCase: DeletePaymentMethodUseCaseImpl!
    private var mockRepository: MockPaymentMethodRepository!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mockRepository = MockPaymentMethodRepository(scenario: .normal())
        useCase = DeletePaymentMethodUseCaseImpl(paymentMethodRepository: mockRepository)
    }

    override func tearDown() {
        useCase = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - Test Methods

    func test_execute_callsRepositoryDeletePaymentMethod() async throws {
        // Given: 실제 존재하는 결제수단 ID
        let paymentMethods = try await mockRepository.fetchPaymentMethods()
        guard let paymentMethodId = paymentMethods.first?.id else {
            XCTFail("No payment methods found in mock repository")
            return
        }

        // When: UseCase execute 호출
        try await useCase.execute(paymentMethodId)

        // Then: Repository의 deletePaymentMethod가 호출됨
        XCTAssertTrue(mockRepository.deletePaymentMethodCalled)
        XCTAssertEqual(mockRepository.lastDeletedPaymentMethodId, paymentMethodId)
    }

    func test_execute_propagatesRepositoryError() async throws {
        // Given: Repository에서 에러가 발생하도록 설정
        let paymentMethodId = UUID()
        mockRepository.shouldFail = true
        mockRepository.errorToThrow = MockError.simulatedFailure

        // When/Then: UseCase가 Repository 에러를 전파
        do {
            try await useCase.execute(paymentMethodId)
            XCTFail("Should propagate repository error")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}
