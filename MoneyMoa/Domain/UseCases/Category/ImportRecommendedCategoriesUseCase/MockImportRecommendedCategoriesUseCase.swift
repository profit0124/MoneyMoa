//
//  MockImportRecommendedCategoriesUseCase.swift
//  MoneyMoa
//
//  Created by Claude on 8/21/25.
//

import Foundation

// MARK: - MockImportRecommendedCategoriesUseCase

public final class MockImportRecommendedCategoriesUseCase: ImportRecommendedCategoriesUseCase {
    public var executeCallCount = 0
    public var executeError: Error?
    
    public init() {}
    
    public func execute() async throws {
        executeCallCount += 1
        
        if let error = executeError {
            throw error
        }
    }
}
