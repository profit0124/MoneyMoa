//
//  GetActivePaymentMethodsUseCaseTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 9/4/25.
//

import XCTest
@testable import MoneyMoa

final class GetActivePaymentMethodsUseCaseTests: XCTestCase {
    
    private var useCase: GetActivePaymentMethodsUseCase!
    private var mockRepository: MockPaymentMethodRepository!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockPaymentMethodRepository(scenario: .empty)
        useCase = GetActivePaymentMethodsUseCaseImpl(paymentMethodRepository: mockRepository)
    }
    
    override func tearDown() {
        useCase = nil
        mockRepository = nil
        super.tearDown()
    }
    
    // MARK: - Success Cases
    
    func testExecute_withEmptyRepository_returnsEmptyArray() async throws {
        // Given: 빈 Repository
        mockRepository.loadScenario(.empty)
        
        // When: 활성 결제수단 조회
        let paymentMethods = try await useCase.execute()
        
        // Then: 빈 배열 반환
        XCTAssertTrue(paymentMethods.isEmpty)
    }
    
    func testExecute_withActivePaymentMethods_returnsOnlyActive() async throws {
        // Given: 활성/비활성 혼합 데이터
        let activeCard1 = PaymentMethodFactory.create(
            name: "활성카드1",
            kind: .credit,
            isActive: true
        )
        let activeCard2 = PaymentMethodFactory.create(
            name: "활성카드2",
            kind: .debit,
            isActive: true
        )
        let inactiveCard = PaymentMethodFactory.inactiveCard()
        
        try await mockRepository.insertPaymentMethod(activeCard1)
        try await mockRepository.insertPaymentMethod(activeCard2)
        try await mockRepository.insertPaymentMethod(inactiveCard)
        
        // When: 활성 결제수단 조회
        let paymentMethods = try await useCase.execute()
        
        // Then: 활성 결제수단만 반환
        XCTAssertEqual(paymentMethods.count, 2)
        XCTAssertTrue(paymentMethods.allSatisfy { $0.isActive })
        XCTAssertFalse(paymentMethods.contains { $0.name == "비활성카드" })
    }
    
    func testExecute_withStandardSet_returnsSortedByOrderIndex() async throws {
        // Given: 표준 결제수단 세트
        mockRepository.loadScenario(.normal())
        
        // When: 활성 결제수단 조회
        let paymentMethods = try await useCase.execute()
        
        // Then: orderIndex 순으로 정렬되어 반환
        XCTAssertGreaterThan(paymentMethods.count, 0)
        for i in 1..<paymentMethods.count {
            XCTAssertLessThanOrEqual(
                paymentMethods[i-1].orderIndex,
                paymentMethods[i].orderIndex
            )
        }
    }
    
    func testExecute_withRealisticData_returnsExpectedResults() async throws {
        // Given: 현실적인 데이터 시나리오
        mockRepository.loadScenario(.realistic)
        
        // When: 활성 결제수단 조회
        let paymentMethods = try await useCase.execute()
        
        // Then: 적절한 수의 결제수단 반환
        XCTAssertGreaterThan(paymentMethods.count, 0)
        XCTAssertTrue(paymentMethods.allSatisfy { $0.isActive })
    }
    
    // MARK: - Error Handling
    
    func testExecute_whenRepositoryFails_throwsError() async throws {
        // Given: Repository 에러 설정
        mockRepository.shouldFail = true
        mockRepository.errorToThrow = MockError.simulatedFailure
        
        // When & Then: 에러 전파
        do {
            _ = try await useCase.execute()
            XCTFail("Expected error but succeeded")
        } catch MockError.simulatedFailure {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Performance Tests
    
    func testExecute_withLargeDataset_performsWell() async throws {
        // Given: 대량의 활성 결제수단
        mockRepository.loadScenario(.stress(count: 100))
        
        // When: 조회 실행
        let startTime = Date()
        let paymentMethods = try await useCase.execute()
        let endTime = Date()
        
        // Then: 1초 이내 완료
        let elapsed = endTime.timeIntervalSince(startTime)
        XCTAssertLessThan(elapsed, 1.0)
        XCTAssertGreaterThan(paymentMethods.count, 0)
    }
    
    // MARK: - Integration Tests
    
    func testExecute_afterAddingPaymentMethod_includesNewMethod() async throws {
        // Given: 빈 Repository에서 시작
        mockRepository.loadScenario(.empty)
        
        // When: 새 결제수단 추가 후 조회
        let newPaymentMethod = PaymentMethodFactory.create(
            name: "새카드",
            kind: .credit,
            isActive: true
        )
        try await mockRepository.insertPaymentMethod(newPaymentMethod)
        let paymentMethods = try await useCase.execute()
        
        // Then: 새 결제수단 포함
        XCTAssertEqual(paymentMethods.count, 1)
        XCTAssertEqual(paymentMethods.first?.name, "새카드")
    }
    
    func testExecute_afterDeactivating_excludesDeactivated() async throws {
        // Given: 활성 결제수단
        let paymentMethod = PaymentMethodFactory.create(
            name: "테스트카드",
            kind: .credit,
            isActive: true
        )
        try await mockRepository.insertPaymentMethod(paymentMethod)
        
        // 초기 조회 확인
        var paymentMethods = try await useCase.execute()
        XCTAssertEqual(paymentMethods.count, 1)
        
        // When: 비활성화
        try await mockRepository.deactivatePaymentMethod(id: paymentMethod.id)
        
        // Then: 조회에서 제외
        paymentMethods = try await useCase.execute()
        XCTAssertTrue(paymentMethods.isEmpty)
    }
    
    func testExecute_afterReactivating_includesReactivated() async throws {
        // Given: 비활성 결제수단
        let paymentMethod = PaymentMethodFactory.create(
            name: "테스트카드",
            kind: .credit,
            isActive: false
        )
        try await mockRepository.insertPaymentMethod(paymentMethod)
        
        // 초기 조회 확인
        var paymentMethods = try await useCase.execute()
        XCTAssertTrue(paymentMethods.isEmpty)
        
        // When: 활성화
        try await mockRepository.activatePaymentMethod(id: paymentMethod.id)
        
        // Then: 조회에 포함
        paymentMethods = try await useCase.execute()
        XCTAssertEqual(paymentMethods.count, 1)
        XCTAssertEqual(paymentMethods.first?.name, "테스트카드")
    }
    
    // MARK: - Concurrent Access Tests
    
    func testExecute_withConcurrentAccess_maintainsDataIntegrity() async throws {
        // Given: 초기 데이터
        mockRepository.loadScenario(.normal())
        
        // When: 동시 다발적 조회
        await withTaskGroup(of: [PaymentMethodDTO].self) { group in
            for _ in 0..<10 {
                group.addTask {
                    (try? await self.useCase.execute()) ?? []
                }
            }
            
            // Then: 모든 결과가 일관됨
            var results: [[PaymentMethodDTO]] = []
            for await result in group {
                results.append(result)
            }
            
            // 첫 번째 결과를 기준으로 모든 결과 비교
            if let firstResult = results.first {
                for result in results {
                    XCTAssertEqual(result.count, firstResult.count)
                }
            }
        }
    }
}
