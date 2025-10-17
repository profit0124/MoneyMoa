//
//  MockClasses.swift
//  MoneyMoaTests
//
//  Created by Sooik Kim on 8/27/25.
//

import Foundation
import Combine
@testable import MoneyMoa

// MARK: - Mock UseCases

class MockUpdateSubCategoryUseCase: UpdateSubCategoryUseCase {
    var executeCallCount = 0
    var lastSubCategory: SubCategoryDTO?
    var executeError: Error?

    func execute(_ subCategory: SubCategoryDTO) async throws {
        executeCallCount += 1
        lastSubCategory = subCategory

        if let error = executeError {
            throw error
        }
    }
}

// MARK: - Mock CategoryEventPublisher

class MockCategoryEventPublisher: CategoryEventPublisher {
    private let subject = PassthroughSubject<CategoryEvent, Never>()

    var publishCallCount = 0
    var lastEvent: CategoryEvent?

    var categoryEvents: AnyPublisher<CategoryEvent, Never> {
        subject.eraseToAnyPublisher()
    }

    func publish(_ event: CategoryEvent) {
        publishCallCount += 1
        lastEvent = event
        subject.send(event)
    }
}

// MARK: - Mock UseCases

class MockCreateCategoryUseCase: CreateCategoryUseCase {
    var executeCallCount = 0
    var lastCategory: CategoryDTO?
    var executeError: Error?

    func execute(_ category: CategoryDTO) async throws {
        executeCallCount += 1
        lastCategory = category

        if let error = executeError {
            throw error
        }
    }
}

class MockCreateSubCategoryUseCase: CreateSubCategoryUseCase {
    var executeCallCount = 0
    var lastSubCategory: SubCategoryDTO?
    var executeError: Error?

    func execute(_ subCategory: SubCategoryDTO) async throws {
        executeCallCount += 1
        lastSubCategory = subCategory

        if let error = executeError {
            throw error
        }
    }
}

class MockUpdateCategoryUseCase: UpdateCategoryUseCase {
    var executeCallCount = 0
    var lastCategory: CategoryDTO?
    var executeError: Error?

    func execute(_ category: CategoryDTO) async throws {
        executeCallCount += 1
        lastCategory = category

        if let error = executeError {
            throw error
        }
    }
}

// MARK: - Mock DeleteCategoryUseCase

class MockDeleteCategoryUseCase: DeleteCategoryUseCase {
    var executeCallCount = 0
    var lastDeletedCategoryId: UUID?
    var executeError: Error?

    func execute(_ id: UUID) async throws {
        executeCallCount += 1
        lastDeletedCategoryId = id

        if let error = executeError {
            throw error
        }
    }
}

// MARK: - Mock DeleteSubCategoryUseCase

class MockDeleteSubCategoryUseCase: DeleteSubCategoryUseCase {
    var executeCallCount = 0
    var lastDeletedSubCategoryId: UUID?
    var executeError: Error?

    func execute(_ id: UUID) async throws {
        executeCallCount += 1
        lastDeletedSubCategoryId = id

        if let error = executeError {
            throw error
        }
    }
}

// MARK: - Mock SelectCategoryEventPublisher

class MockSelectCategoryEventPublisher: SelectCategoryEventPublisher {
    var publishCallCount = 0
    var lastPublishedCategory: CategoryDTO?

    var selectCategoryEvent: AnyPublisher<CategoryDTO, Never> {
        PassthroughSubject<CategoryDTO, Never>().eraseToAnyPublisher()
    }

    func publish(_ category: CategoryDTO) {
        publishCallCount += 1
        lastPublishedCategory = category
    }
}
