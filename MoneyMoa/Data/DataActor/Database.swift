//
//  DataActor.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/26/25.
//

import Foundation
import SwiftData

enum DatabaseError: Error {
    case initializeError
}

@ModelActor
public actor Database {
    public init(isStoredInMemoryOnly: Bool = false) throws {
        let scheme = Schema([
            Category.self,
            SubCategory.self,
            Transaction.self,
            PaymentMethod.self,
            BudgetTemplate.self,
            CategoryBudgetTemplate.self,
            Budget.self,
            CategoryBudget.self
        ])
        do {
            let configuration = ModelConfiguration(schema: scheme, isStoredInMemoryOnly: isStoredInMemoryOnly, allowsSave: true)
            let container = try ModelContainer(for: scheme, configurations: configuration)
            let context = ModelContext(container)
            self.modelExecutor = DefaultSerialModelExecutor(modelContext: context)
            self.modelContainer = container
        } catch {
            throw DatabaseError.initializeError
        }
    }
}

extension ModelActor {
  public func withModelContext<T: Sendable>(
    _ closure: @Sendable @escaping (ModelContext) throws -> T
  ) async rethrows -> T {
    try closure(self.modelContext)
  }
}
