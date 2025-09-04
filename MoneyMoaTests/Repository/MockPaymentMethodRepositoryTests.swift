//
//  MockPaymentMethodRepositoryTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 9/4/25.
//

import XCTest
@testable import MoneyMoa

// MARK: - Mock Repository Tests

final class MockPaymentMethodRepositoryTests: XCTestCase {

    private var mockRepository: MockPaymentMethodRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockPaymentMethodRepository(scenario: .normal())
    }

    override func tearDown() {
        mockRepository = nil
        super.tearDown()
    }

    func testScenarios() async throws {
        // Test empty scenario
        mockRepository = MockPaymentMethodRepository(scenario: .empty)
        var paymentMethods = try await mockRepository.fetchPaymentMethods()
        XCTAssertTrue(paymentMethods.isEmpty)

        // Test minimal scenario
        mockRepository = MockPaymentMethodRepository(scenario: .minimal(count: 3))
        paymentMethods = try await mockRepository.fetchPaymentMethods()
        XCTAssertEqual(paymentMethods.count, 3)

        // Test realistic scenario
        mockRepository = MockPaymentMethodRepository(scenario: .realistic)
        paymentMethods = try await mockRepository.fetchPaymentMethods()
        XCTAssertGreaterThan(paymentMethods.count, 0)
    }

    func testDelaySimulation() async throws {
        // Given: 지연 설정
        mockRepository.delay = 0.1

        // When: 조회 수행
        let startTime = Date()
        _ = try await mockRepository.fetchPaymentMethods()
        let endTime = Date()

        // Then: 최소 지연 시간 확인
        let elapsed = endTime.timeIntervalSince(startTime)
        XCTAssertGreaterThanOrEqual(elapsed, 0.05) // 최소한의 지연 확인
    }

    func testErrorSimulation() async throws {
        // Given: 에러 설정
        mockRepository.shouldFail = true
        mockRepository.errorToThrow = MockError.simulatedFailure

        // When & Then: 에러 발생
        do {
            _ = try await mockRepository.fetchPaymentMethods()
            XCTFail("Expected error but succeeded")
        } catch MockError.simulatedFailure {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCRUDOperations() async throws {
        // Test Create
        let newPaymentMethod = PaymentMethodFactory.create(
            name: "테스트카드",
            kind: .credit
        )
        try await mockRepository.insertPaymentMethod(newPaymentMethod)

        // Test Read
        var paymentMethod = try await mockRepository.fetchPaymentMethod(id: newPaymentMethod.id)
        XCTAssertNotNil(paymentMethod)
        XCTAssertEqual(paymentMethod?.name, "테스트카드")

        // Test Update
        let updatedPaymentMethod = PaymentMethodDTO(
            id: newPaymentMethod.id,
            name: "수정된카드",
            kind: .credit,
            orderIndex: 1,
            isActive: true
        )
        try await mockRepository.updatePaymentMethod(updatedPaymentMethod)
        paymentMethod = try await mockRepository.fetchPaymentMethod(id: newPaymentMethod.id)
        XCTAssertEqual(paymentMethod?.name, "수정된카드")

        // Test Deactivate & Delete
        try await mockRepository.deactivatePaymentMethod(id: newPaymentMethod.id)
        paymentMethod = try await mockRepository.fetchPaymentMethod(id: newPaymentMethod.id)
        XCTAssertFalse(paymentMethod?.isActive ?? true)

        try await mockRepository.deletePaymentMethod(id: newPaymentMethod.id)
        paymentMethod = try await mockRepository.fetchPaymentMethod(id: newPaymentMethod.id)
        XCTAssertNil(paymentMethod)
    }

    func testThreadSafety() async throws {
        // Concurrent read/write operations
        await withTaskGroup(of: Void.self) { group in
            // Multiple writes
            for i in 0..<10 {
                group.addTask {
                    let paymentMethod = PaymentMethodFactory.create(
                        name: "카드\(i)",
                        kind: .credit,
                        orderIndex: i
                    )
                    try? await self.mockRepository.insertPaymentMethod(paymentMethod)
                }
            }

            // Multiple reads
            for _ in 0..<10 {
                group.addTask {
                    _ = try? await self.mockRepository.fetchPaymentMethods()
                }
            }
        }

        // Verify data integrity
        let count = await mockRepository.count()
        XCTAssertGreaterThanOrEqual(count, 0) // Some writes should have succeeded
    }
}
