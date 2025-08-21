//
//  ImportRecommendedCategoriesUseCaseTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 8/21/25.
//

import XCTest
@testable import MoneyMoa

final class ImportRecommendedCategoriesUseCaseTests: XCTestCase {
    
    // MARK: - Basic Tests
    
    func testImportRecommendedCategoriesUseCase_ShouldExist() {
        // Given & When
        let mockDIContainer = MockDIContainer()
        let useCase = mockDIContainer.makeImportRecommendedCategoriesUseCase()
        
        // Then
        XCTAssertNotNil(useCase, "ImportRecommendedCategoriesUseCase가 생성되어야 합니다")
    }
    
    func testMockImportRecommendedCategoriesUseCase_ShouldTrackExecuteCalls() async {
        // Given
        let mockUseCase = MockImportRecommendedCategoriesUseCase()
        
        // When
        try? await mockUseCase.execute()
        
        // Then
        XCTAssertEqual(mockUseCase.executeCallCount, 1, "execute 호출 횟수가 올바르게 기록되어야 합니다")
    }
    
    func testMockImportRecommendedCategoriesUseCase_WithError_ShouldThrowError() async {
        // Given
        let mockUseCase = MockImportRecommendedCategoriesUseCase()
        let expectedError = RepositoryError.custom("테스트 에러")
        mockUseCase.executeError = expectedError
        
        // When & Then
        do {
            try await mockUseCase.execute()
            XCTFail("에러가 발생해야 합니다")
        } catch {
            XCTAssertTrue(error is RepositoryError, "RepositoryError가 발생해야 합니다")
        }
    }
    
    func testMockImportRecommendedCategoriesUseCase_WithoutError_ShouldSucceed() async {
        // Given
        let mockUseCase = MockImportRecommendedCategoriesUseCase()
        mockUseCase.executeError = nil
        
        // When & Then
        do {
            try await mockUseCase.execute()
            // 성공적으로 완료되어야 함
        } catch {
            XCTFail("에러가 발생하지 않아야 합니다: \(error)")
        }
    }
}

// MARK: - Test Helper Classes

private class FailingImportUseCase: ImportRecommendedCategoriesUseCase {
    func execute() async throws {
        throw RepositoryError.custom("추천 카테고리 파일을 찾을 수 없습니다")
    }
}
