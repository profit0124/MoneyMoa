import Foundation
@testable import MoneyMoa

@MainActor
final class StubGetCategoriesByTypeUseCase: GetCategoriesByTypeUseCase {
    var categories: [CategoryDTO]

    init(categories: [CategoryDTO]) {
        self.categories = categories
    }

    func execute(_ type: TransactionType) async throws -> [CategoryDTO] {
        categories
    }
}
