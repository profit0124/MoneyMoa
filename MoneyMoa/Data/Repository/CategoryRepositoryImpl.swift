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
    
    // MARK: - Private Helper Methods
    
    /// Category 정렬 조건 정의
    private var categorySortDescriptors: [SortDescriptor<Category>] {
        [SortDescriptor(\.orderIndex), SortDescriptor(\.name)]
    }
    
    /// SubCategory 정렬 조건 정의
    private var subCategorySortDescriptors: [SortDescriptor<SubCategory>] {
        [SortDescriptor(\.orderIndex), SortDescriptor(\.name)]
    }
    
    /// Category FetchDescriptor 생성
    private func createCategoryDescriptor(
        predicate: Predicate<Category>? = nil,
        sortBy: [SortDescriptor<Category>]? = nil
    ) -> FetchDescriptor<Category> {
        FetchDescriptor<Category>(
            predicate: predicate,
            sortBy: sortBy ?? categorySortDescriptors
        )
    }
    
    /// SubCategory FetchDescriptor 생성
    private func createSubCategoryDescriptor(
        predicate: Predicate<SubCategory>? = nil,
        sortBy: [SortDescriptor<SubCategory>]? = nil
    ) -> FetchDescriptor<SubCategory> {
        FetchDescriptor<SubCategory>(
            predicate: predicate,
            sortBy: sortBy ?? subCategorySortDescriptors
        )
    }
    
    /// 단일 Category 조회 헬퍼
    private func fetchCategoryModel(id: UUID, context: ModelContext) throws -> Category? {
        let predicate = #Predicate<Category> { $0.id == id }
        let descriptor = createCategoryDescriptor(predicate: predicate)
        return try context.fetch(descriptor).first
    }
    
    /// 단일 SubCategory 조회 헬퍼
    private func fetchSubCategoryModel(id: UUID, context: ModelContext) throws -> SubCategory? {
        let predicate = #Predicate<SubCategory> { $0.id == id }
        let descriptor = createSubCategoryDescriptor(predicate: predicate)
        return try context.fetch(descriptor).first
    }
    
    // MARK: - 조회 (Fetch Operations)
    
    public func fetchCategories() async throws -> [CategoryDTO] {
        try await database.withModelContext { context in
            let descriptor = self.createCategoryDescriptor()
            let categories = try context.fetch(descriptor)
            return categories.toDTOs(includeSubCategories: false)
        }
    }

    public func fetchCategoriesByType(_ type: TransactionType) async throws -> [CategoryDTO] {
        try await database.withModelContext { context in
            let predicate = #Predicate<Category> { category in
                category.transactionTypeRawValue == type.rawValue &&
                category.isActive
            }
            let descriptor = self.createCategoryDescriptor(predicate: predicate)
            let categories = try context.fetch(descriptor)
            return categories.toDTOs(includeSubCategories: true)
        }
    }
    
    // MARK: - 생성/수정 (Create/Update Operations)
    
    public func insertCategory(_ category: CategoryDTO) async throws {
        try await database.withModelContext { context in
            context.insert(category.toModel())
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
            return try context.fetch(descriptor).isEmpty
        }
    }
    
    public func updateCategory(_ category: CategoryDTO) async throws {
        try await database.withModelContext { context in
            guard let existingCategory = try self.fetchCategoryModel(id: category.id, context: context) else {
                throw RepositoryError.categoryNotFound
            }
            
            existingCategory.name = category.name
            existingCategory.iconName = category.iconName
            existingCategory.transactionType = category.transactionType
            existingCategory.isActive = category.isActive
            existingCategory.orderIndex = category.orderIndex
            
            try context.save()
        }
    }
    
    // MARK: - SubCategory Operations Implementation
    
    // MARK: - SubCategory 조회 (Fetch Operations)
    
    public func fetchSubCategories(categoryId: UUID) async throws -> [SubCategoryDTO] {
        try await database.withModelContext { context in
            let predicate = #Predicate<SubCategory> { subCategory in
                subCategory.category?.id == categoryId && subCategory.isActive == true
            }
            let descriptor = self.createSubCategoryDescriptor(predicate: predicate)
            let subCategories = try context.fetch(descriptor)
            return subCategories.toDTOs()
        }
    }
    
    // MARK: - SubCategory 생성/수정 (Create/Update Operations)
    
    public func insertSubCategory(_ subCategory: SubCategoryDTO) async throws {
        try await database.withModelContext { context in
            guard let parentCategory = try self.fetchCategoryModel(id: subCategory.categoryId, context: context) else {
                throw RepositoryError.categoryNotFound
            }
            
            context.insert(subCategory.toModel(parentCategory: parentCategory))
            try context.save()
        }
    }
    
    public func updateSubCategory(_ subCategory: SubCategoryDTO) async throws {
        try await database.withModelContext { context in
            guard let existingSubCategory = try self.fetchSubCategoryModel(id: subCategory.id, context: context) else {
                throw RepositoryError.subCategoryNotFound
            }

            if existingSubCategory.category?.id != subCategory.categoryId {
                guard let newParentCategory = try self.fetchCategoryModel(id: subCategory.categoryId, context: context) else {
                    throw RepositoryError.categoryNotFound
                }
                existingSubCategory.category = newParentCategory
            }

            existingSubCategory.name = subCategory.name
            existingSubCategory.transactionType = subCategory.transactionType
            existingSubCategory.isActive = subCategory.isActive
            existingSubCategory.orderIndex = subCategory.orderIndex

            try context.save()
        }
    }
    
    // MARK: - SubCategory 검증 (Validation)

    public func validateSubCategoryName(_ name: String, categoryId: UUID, excludingId: UUID?) async throws -> Bool {
        try await database.withModelContext { context in
            let predicate: Predicate<SubCategory>
            if let excludingId = excludingId {
                predicate = #Predicate<SubCategory> { subCategory in
                    subCategory.name == name &&
                    subCategory.category?.id == categoryId &&
                    subCategory.id != excludingId
                }
            } else {
                predicate = #Predicate<SubCategory> { subCategory in
                    subCategory.name == name && subCategory.category?.id == categoryId
                }
            }

            let descriptor = FetchDescriptor<SubCategory>(predicate: predicate)
            return try context.fetch(descriptor).isEmpty
        }
    }

    // MARK: - 삭제 (Delete Operations)

    public func deleteCategory(_ id: UUID) async throws {
        try await database.withModelContext { context in
            guard let category = try self.fetchCategoryModel(id: id, context: context) else {
                throw RepositoryError.categoryNotFound
            }

            // TransactionTemplate 확인
            let hasTemplates = category.subCategories.contains { subCategory in
                !subCategory.transactionTemplates.isEmpty
            }

            if hasTemplates {
                throw RepositoryError.hasActiveTemplates
            }

            // Transaction 확인
            let hasTransactions = category.subCategories.contains { subCategory in
                !subCategory.transactions.isEmpty
            }

            if hasTransactions {
                // Transaction이 있으면 soft delete
                category.isActive = false
                for subCategory in category.subCategories {
                    subCategory.isActive = false
                }
            } else {
                // 참조가 없으면 hard delete
                context.delete(category)
            }

            try context.save()
        }
    }

    public func deleteSubCategory(_ id: UUID) async throws {
        try await database.withModelContext { context in
            guard let subCategory = try self.fetchSubCategoryModel(id: id, context: context) else {
                throw RepositoryError.subCategoryNotFound
            }

            // TransactionTemplate 확인
            if !subCategory.transactionTemplates.isEmpty {
                throw RepositoryError.hasActiveTemplates
            }

            // Transaction 확인
            if !subCategory.transactions.isEmpty {
                // Transaction이 있으면 soft delete
                subCategory.isActive = false
            } else {
                // 참조가 없으면 hard delete
                context.delete(subCategory)
            }

            try context.save()
        }
    }

}
