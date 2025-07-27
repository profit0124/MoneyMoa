//
//  CategoryRepositoryImpl.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/27/25.
//

import Foundation
import SwiftData

// MARK: - CategoryRepositoryImpl

public class CategoryRepositoryImpl: CategoryRepository {
    private let database: Database
    
    public init(database: Database) {
        self.database = database
    }
    
    // MARK: - 조회 (Fetch Operations)
    
    public func fetchCategories() async throws -> [CategoryDTO] {
        try await database.withModelContext { context in
            let descriptor = FetchDescriptor<Category>(
                sortBy: [SortDescriptor(\.orderIndex), SortDescriptor(\.name)]
            )
            let categories = try context.fetch(descriptor)
            
            return categories.toDTOs(includeSubCategories: false)
        }
    }
    
    public func fetchCategory(id: UUID) async throws -> CategoryDTO? {
        try await database.withModelContext { context in
            let predicate = #Predicate<Category> { $0.id == id }
            let descriptor = FetchDescriptor<Category>(predicate: predicate)
            
            guard let category = try context.fetch(descriptor).first else {
                return nil
            }
            
            return category.toDTO(includeSubCategories: true)
        }
    }
    
    public func fetchCategoryWithSubCategories(id: UUID) async throws -> CategoryDTO? {
        try await database.withModelContext { context in
            let predicate = #Predicate<Category> { $0.id == id }
            let descriptor = FetchDescriptor<Category>(predicate: predicate)
            
            guard let category = try context.fetch(descriptor).first else {
                return nil
            }
            
            return category.toDTO(includeSubCategories: true)
        }
    }
    
    public func fetchActiveCategories() async throws -> [CategoryDTO] {
        try await database.withModelContext { context in
            let predicate = #Predicate<Category> { $0.isActive == true }
            let descriptor = FetchDescriptor<Category>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.orderIndex), SortDescriptor(\.name)]
            )
            let categories = try context.fetch(descriptor)
            
            return categories.toDTOs(includeSubCategories: true)
        }
    }
    
    public func fetchCategoriesByType(_ type: TransactionType) async throws -> [CategoryDTO] {
        try await database.withModelContext { context in
            let predicate = #Predicate<Category> { category in
                category.transactionTypeRawValue == type.rawValue
            }
            let descriptor = FetchDescriptor<Category>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.orderIndex), SortDescriptor(\.name)]
            )
            let categories = try context.fetch(descriptor)
            
            return categories.toDTOs(includeSubCategories: true)
        }
    }
    
    // MARK: - 생성/수정 (Create/Update Operations)
    
    public func insertCategory(_ category: CategoryDTO) async throws {
        try await database.withModelContext { context in
            // DTO를 SwiftData 모델로 변환
            let newCategory = category.toModel()
            
            context.insert(newCategory)
            try context.save()
        }
    }
    
    public func updateCategory(_ category: CategoryDTO) async throws {
        let id = category.id
        try await database.withModelContext { context in
            // 기존 카테고리 조회
            let predicate = #Predicate<Category> { $0.id == id }
            let descriptor = FetchDescriptor<Category>(predicate: predicate)
            
            guard let existingCategory = try context.fetch(descriptor).first else {
                throw RepositoryError.categoryNotFound
            }
            
            // 카테고리 업데이트 (validation은 UseCase에서 처리)
            existingCategory.name = category.name
            existingCategory.transactionType = category.transactionType
            existingCategory.isActive = category.isActive
            existingCategory.orderIndex = category.orderIndex
            
            try context.save()
        }
    }
    
    // MARK: - 활성/비활성 관리 (Activation Management)
    
    public func deactivateCategory(id: UUID) async throws {
        try await database.withModelContext { context in
            let predicate = #Predicate<Category> { $0.id == id }
            let descriptor = FetchDescriptor<Category>(predicate: predicate)
            
            guard let category = try context.fetch(descriptor).first else {
                throw RepositoryError.categoryNotFound
            }
            
            category.isActive = false
            try context.save()
        }
    }
    
    public func activateCategory(id: UUID) async throws {
        try await database.withModelContext { context in
            let predicate = #Predicate<Category> { $0.id == id }
            let descriptor = FetchDescriptor<Category>(predicate: predicate)
            
            guard let category = try context.fetch(descriptor).first else {
                throw RepositoryError.categoryNotFound
            }
            
            category.isActive = true
            try context.save()
        }
    }
    
    // MARK: - 삭제 관련 (Delete Operations)
    
    public func deleteCategory(id: UUID) async throws {
        try await database.withModelContext { context in
            let predicate = #Predicate<Category> { $0.id == id }
            let descriptor = FetchDescriptor<Category>(predicate: predicate)
            
            guard let category = try context.fetch(descriptor).first else {
                throw RepositoryError.categoryNotFound
            }
            
            // 활성 카테고리 삭제 방지
            if category.isActive {
                throw RepositoryError.cannotDeleteActiveCategory
            }
            
            // 카테고리 삭제 (SwiftData의 cascade 삭제 규칙에 의해 서브카테고리도 함께 삭제됨)
            context.delete(category)
            try context.save()
        }
    }
    
    // MARK: - 검증 (Validation)
    
    public func validateCategoryName(_ name: String, type: TransactionType, excludingId: UUID?) async throws -> Bool {
        try await database.withModelContext { context in
            let predicate: Predicate<Category>
            
            if let excludingId = excludingId {
                predicate = #Predicate<Category> { category in
                    category.name == name && 
                    category.transactionTypeRawValue == type.rawValue &&
                    category.id != excludingId
                }
            } else {
                predicate = #Predicate<Category> { category in
                    category.name == name && category.transactionTypeRawValue == type.rawValue
                }
            }
            
            let descriptor = FetchDescriptor<Category>(predicate: predicate)
            let existingCategories = try context.fetch(descriptor)
            
            return existingCategories.isEmpty
        }
    }
    
    public func hasTransactions(categoryId: UUID) async throws -> Bool {
        try await database.withModelContext { context in
            // 해당 카테고리의 서브카테고리들 조회
            let subCategoryPredicate = #Predicate<SubCategory> { $0.category.id == categoryId }
            let subCategoryDescriptor = FetchDescriptor<SubCategory>(predicate: subCategoryPredicate)
            let subCategories = try context.fetch(subCategoryDescriptor)
            
            // 서브카테고리가 없으면 거래 내역도 없음
            if subCategories.isEmpty {
                return false
            }
            
            let subCategoryIds = subCategories.map { $0.id }
            
            // 거래 내역 확인
            let transactionPredicate = #Predicate<Transaction> { transaction in
                subCategoryIds.contains(transaction.subCategory.id)
            }
            let transactionDescriptor = FetchDescriptor<Transaction>(predicate: transactionPredicate)
            let transactions = try context.fetch(transactionDescriptor)
            
            return !transactions.isEmpty
        }
    }
}
