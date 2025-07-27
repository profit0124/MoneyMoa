//
//  SubCategoryRepositoryImpl.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/27/25.
//

import Foundation
import SwiftData

// MARK: - SubCategoryRepositoryImpl

public class SubCategoryRepositoryImpl: SubCategoryRepository {
    private let database: Database
    
    public init(database: Database) {
        self.database = database
    }
    
    // MARK: - 조회 (Fetch Operations)
    
    public func fetchSubCategories() async throws -> [SubCategoryDTO] {
        try await database.withModelContext { context in
            let descriptor = FetchDescriptor<SubCategory>(
                sortBy: [SortDescriptor(\.orderIndex), SortDescriptor(\.name)]
            )
            let subCategories = try context.fetch(descriptor)
            
            return subCategories.toDTOs()
        }
    }
    
    public func fetchSubCategory(id: UUID) async throws -> SubCategoryDTO? {
        try await database.withModelContext { context in
            let predicate = #Predicate<SubCategory> { $0.id == id }
            let descriptor = FetchDescriptor<SubCategory>(predicate: predicate)
            
            guard let subCategory = try context.fetch(descriptor).first else {
                return nil
            }
            
            return subCategory.toDTO()
        }
    }
    
    public func fetchSubCategories(categoryId: UUID) async throws -> [SubCategoryDTO] {
        try await database.withModelContext { context in
            let predicate = #Predicate<SubCategory> { subCategory in
                subCategory.category.id == categoryId && subCategory.isActive == true
            }
            let descriptor = FetchDescriptor<SubCategory>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.orderIndex), SortDescriptor(\.name)]
            )
            let subCategories = try context.fetch(descriptor)
            
            return subCategories.toDTOs()
        }
    }
    
    public func fetchActiveSubCategories() async throws -> [SubCategoryDTO] {
        try await database.withModelContext { context in
            let predicate = #Predicate<SubCategory> { $0.isActive == true }
            let descriptor = FetchDescriptor<SubCategory>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.orderIndex), SortDescriptor(\.name)]
            )
            let subCategories = try context.fetch(descriptor)
            
            return subCategories.toDTOs()
        }
    }
    
    public func fetchSubCategoriesByType(_ type: TransactionType) async throws -> [SubCategoryDTO] {
        try await database.withModelContext { context in
            let predicate = #Predicate<SubCategory> { subCategory in
                subCategory.transactionTypeRawValue == type.rawValue
            }
            let descriptor = FetchDescriptor<SubCategory>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.orderIndex), SortDescriptor(\.name)]
            )
            let subCategories = try context.fetch(descriptor)
            
            return subCategories.toDTOs()
        }
    }
    
    // MARK: - 생성/수정 (Create/Update Operations)
    
    public func insertSubCategory(_ subCategory: SubCategoryDTO) async throws {
        let categoryId = subCategory.categoryId
        try await database.withModelContext { context in
            // 상위 카테고리 조회 (반드시 필요)
            let categoryPredicate = #Predicate<Category> { $0.id == categoryId }
            let categoryDescriptor = FetchDescriptor<Category>(predicate: categoryPredicate)
            guard let parentCategory = try context.fetch(categoryDescriptor).first else {
                throw RepositoryError.categoryNotFound
            }
            
            // DTO를 SwiftData 모델로 변환
            let newSubCategory = subCategory.toModel(parentCategory: parentCategory)
            
            context.insert(newSubCategory)
            try context.save()
        }
    }
    
    public func updateSubCategory(_ subCategory: SubCategoryDTO) async throws {
        let id = subCategory.id
        let categoryId = subCategory.categoryId
        try await database.withModelContext { context in
            // 기존 서브카테고리 조회
            let predicate = #Predicate<SubCategory> { $0.id == id }
            let descriptor = FetchDescriptor<SubCategory>(predicate: predicate)
            
            guard let existingSubCategory = try context.fetch(descriptor).first else {
                throw RepositoryError.subCategoryNotFound
            }
            
            // 카테고리가 변경되었다면 새 카테고리 확인
            if existingSubCategory.category.id != categoryId {
                let categoryPredicate = #Predicate<Category> { $0.id == categoryId }
                let categoryDescriptor = FetchDescriptor<Category>(predicate: categoryPredicate)
                guard let newParentCategory = try context.fetch(categoryDescriptor).first else {
                    throw RepositoryError.categoryNotFound
                }
                existingSubCategory.category = newParentCategory
            }
            
            // 서브카테고리 업데이트 (validation은 UseCase에서 처리)
            existingSubCategory.name = subCategory.name
            existingSubCategory.transactionType = subCategory.transactionType
            existingSubCategory.isActive = subCategory.isActive
            existingSubCategory.orderIndex = subCategory.orderIndex
            
            try context.save()
        }
    }
    
    // MARK: - 활성/비활성 관리 (Activation Management)
    
    public func deactivateSubCategory(id: UUID) async throws {
        try await database.withModelContext { context in
            let predicate = #Predicate<SubCategory> { $0.id == id }
            let descriptor = FetchDescriptor<SubCategory>(predicate: predicate)
            
            guard let subCategory = try context.fetch(descriptor).first else {
                throw RepositoryError.subCategoryNotFound
            }
            
            subCategory.isActive = false
            try context.save()
        }
    }
    
    public func activateSubCategory(id: UUID) async throws {
        try await database.withModelContext { context in
            let predicate = #Predicate<SubCategory> { $0.id == id }
            let descriptor = FetchDescriptor<SubCategory>(predicate: predicate)
            
            guard let subCategory = try context.fetch(descriptor).first else {
                throw RepositoryError.subCategoryNotFound
            }
            
            subCategory.isActive = true
            try context.save()
        }
    }
    
    // MARK: - 삭제 관련 (Delete Operations)
    
    public func deleteSubCategory(id: UUID) async throws {
        try await database.withModelContext { context in
            let predicate = #Predicate<SubCategory> { $0.id == id }
            let descriptor = FetchDescriptor<SubCategory>(predicate: predicate)
            
            guard let subCategory = try context.fetch(descriptor).first else {
                throw RepositoryError.subCategoryNotFound
            }
            
            // 활성 서브카테고리 삭제 방지
            if subCategory.isActive {
                throw RepositoryError.cannotDeleteActiveSubCategory
            }
            
            // 서브카테고리 삭제 (SwiftData의 cascade 삭제 규칙에 의해 관련 거래 내역도 함께 삭제됨)
            context.delete(subCategory)
            try context.save()
        }
    }
    
    // MARK: - 검증 (Validation)
    
    public func validateSubCategoryName(_ name: String, categoryId: UUID, excludingId: UUID?) async throws -> Bool {
        try await database.withModelContext { context in
            let predicate: Predicate<SubCategory>
            
            if let excludingId = excludingId {
                predicate = #Predicate<SubCategory> { subCategory in
                    subCategory.name == name && 
                    subCategory.category.id == categoryId &&
                    subCategory.id != excludingId
                }
            } else {
                predicate = #Predicate<SubCategory> { subCategory in
                    subCategory.name == name && subCategory.category.id == categoryId
                }
            }
            
            let descriptor = FetchDescriptor<SubCategory>(predicate: predicate)
            let existingSubCategories = try context.fetch(descriptor)
            
            return existingSubCategories.isEmpty
        }
    }
    
    public func hasTransactions(subCategoryId: UUID) async throws -> Bool {
        try await database.withModelContext { context in
            // 해당 서브카테고리의 거래 내역 확인
            let transactionPredicate = #Predicate<Transaction> { transaction in
                transaction.subCategory.id == subCategoryId
            }
            let transactionDescriptor = FetchDescriptor<Transaction>(predicate: transactionPredicate)
            let transactions = try context.fetch(transactionDescriptor)
            
            return !transactions.isEmpty
        }
    }
}
