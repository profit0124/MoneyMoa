//
//  DeleteCategoryUseCaseTests.swift
//  MoneyMoaTests
//
//  Created by Sooik Kim on 10/16/25.
//

import XCTest
@testable import MoneyMoa

// MARK: - DeleteCategoryUseCaseTests

@MainActor
final class DeleteCategoryUseCaseTests: XCTestCase {

    // MARK: - Properties

    private var useCase: DeleteCategoryUseCaseImpl!
    private var mockRepository: MockCategoryRepository!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mockRepository = MockCategoryRepository(scenario: .normal)
        useCase = DeleteCategoryUseCaseImpl(categoryRepository: mockRepository)
    }

    override func tearDown() {
        useCase = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - Test Methods

    func test_execute_callsRepositoryDeleteCategory() async throws {
        // Given: 실제 존재하는 카테고리 ID
        let categories = try await mockRepository.fetchCategories()
        guard let categoryId = categories.first?.id else {
            XCTFail("No categories found in mock repository")
            return
        }

        // When: UseCase execute 호출
        try await useCase.execute(categoryId)

        // Then: Repository의 deleteCategory가 호출됨
        XCTAssertTrue(mockRepository.deleteCategoryCalled)
        XCTAssertEqual(mockRepository.lastDeletedCategoryId, categoryId)
    }

    func test_execute_propagatesRepositoryError() async throws {
        // Given: Repository에서 에러가 발생하도록 설정
        let categoryId = UUID()
        mockRepository.shouldFail = true
        mockRepository.errorToThrow = MockError.simulatedFailure

        // When/Then: UseCase가 Repository 에러를 전파
        do {
            try await useCase.execute(categoryId)
            XCTFail("Should propagate repository error")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}
