//
//  MockError.swift
//  MoneyMoa
//
//  Created by Claude Code on 9/3/25.
//

import Foundation

/// Common error types for all Mock Repository implementations
/// - Provides standardized error simulation for testing scenarios
/// - Includes domain-specific errors for comprehensive testing coverage
public enum MockError: Error, LocalizedError {
    // MARK: - General Mock Errors
    case simulatedFailure
    case networkTimeout
    case invalidData
    
    // MARK: - Transaction Domain Errors
    case transactionNotFound
    
    // MARK: - Category Domain Errors
    case categoryNotFound
    case subCategoryNotFound
    case cannotDeleteActiveCategory
    case cannotDeleteActiveSubCategory
    
    // MARK: - Budget Domain Errors
    case budgetNotFound
    case budgetTemplateNotFound
    
    // MARK: - PaymentMethod Domain Errors
    case paymentMethodNotFound
    
    // MARK: - Statistics Domain Errors
    case statisticsDataNotAvailable
    
    public var errorDescription: String? {
        switch self {
            // General
        case .simulatedFailure:
            return "Simulated failure for testing"
        case .networkTimeout:
            return "Network timeout"
        case .invalidData:
            return "Invalid data"
            
            // Transaction
        case .transactionNotFound:
            return "Transaction not found"
            
            // Category
        case .categoryNotFound:
            return "Category not found"
        case .subCategoryNotFound:
            return "SubCategory not found"
        case .cannotDeleteActiveCategory:
            return "Cannot delete active category"
        case .cannotDeleteActiveSubCategory:
            return "Cannot delete active subcategory"
            
            // Budget
        case .budgetNotFound:
            return "Budget not found"
        case .budgetTemplateNotFound:
            return "Budget template not found"
            
            // PaymentMethod
        case .paymentMethodNotFound:
            return "Payment method not found"
            
            // Statistics
        case .statisticsDataNotAvailable:
            return "Statistics data not available"
        }
    }
}
