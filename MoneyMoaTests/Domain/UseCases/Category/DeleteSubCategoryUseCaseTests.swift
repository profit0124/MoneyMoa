//
//  DeleteSubCategoryUseCaseTests.swift
//  MoneyMoaTests
//
//  Created by Sooik Kim on 10/16/25.
//

import XCTest
@testable import MoneyMoa

// MARK: - DeleteSubCategoryUseCaseTests

@MainActor
final class DeleteSubCategoryUseCaseTests: XCTestCase {

    // MARK: - Properties

    private var useCase: DeleteSubCategoryUseCaseImpl!
    private var mockRepository: MockCategoryRepository!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mockRepository = MockCategoryRepository(scenario: .realistic)
        useCase = DeleteSubCategoryUseCaseImpl(categoryRepository: mockRepository)
    }

    override func tearDown() {
        useCase = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - Test Methods

    func test_execute_callsRepositoryDeleteSubCategory() async throws {
        // Given: 실제 존재하는 서브카테고리 ID
        let categories = try await mockRepository.fetchCategoriesByType(.variableExpense)
        guard let category = categories.first,
              let subCategoryId = category.subCategories.first?.id else {
            XCTFail("No subcategories found in mock repository")
            return
        }

        // When: UseCase execute 호출
        try await useCase.execute(subCategoryId)

        // Then: Repository의 deleteSubCategory가 호출됨
        XCTAssertTrue(mockRepository.deleteSubCategoryCalled)
        XCTAssertEqual(mockRepository.lastDeletedSubCategoryId, subCategoryId)
    }

    func test_execute_propagatesRepositoryError() async throws {
        // Given: Repository에서 에러가 발생하도록 설정
        let subCategoryId = UUID()
        mockRepository.shouldFail = true
        mockRepository.errorToThrow = MockError.simulatedFailure

        // When/Then: UseCase가 Repository 에러를 전파
        do {
            try await useCase.execute(subCategoryId)
            XCTFail("Should propagate repository error")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}
