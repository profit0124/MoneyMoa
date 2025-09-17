//
//  TransactionRepositoryTests.swift
//  MoneyMoaTests
//
//  Created by Sooik Kim on 7/27/25.
//

import XCTest
import SwiftData
@testable import MoneyMoa

final class TransactionRepositoryTests: XCTestCase {

    private var database: Database!
    private var repository: TransactionRepositoryImpl!
    private var transactionReader: TransactionReader!
    private var transactionWriter: TransactionWriter!
    private var templateRepository: TransactionTemplateRepositoryImpl!
    private var templateReader: TransactionTemplateReader!
    
    // 테스트용 기본 데이터
    private var testCategory: CategoryModel!
    private var testSubCategory: SubCategoryModel!
    private var testPaymentMethod: PaymentMethodModel!
    
    override func setUpWithError() throws {
        database = try Database(isStoredInMemoryOnly: true)
        repository = TransactionRepositoryImpl(database: database)
        templateRepository = TransactionTemplateRepositoryImpl(database: database)

        // Interface Segregation을 위한 분리된 인터페이스
        transactionReader = repository
        transactionWriter = repository
        templateReader = templateRepository
    }
    
    override func tearDownWithError() throws {
        database = nil
        repository = nil
        transactionReader = nil
        transactionWriter = nil
        templateRepository = nil
        templateReader = nil
        testCategory = nil
        testSubCategory = nil
        testPaymentMethod = nil
    }
    
    private func setupBasicTestData() async throws {
        try await database.withModelContext { [self] context in
            // 카테고리 생성
            let categoryDTO = CategoryDTO.mockExpense
            testCategory = categoryDTO.toModel()
            context.insert(testCategory)
            
            // 서브카테고리 생성
            let subCategoryDTO = SubCategoryDTO.mockFoodExpense
            testSubCategory = subCategoryDTO.toModel(parentCategory: testCategory)
            context.insert(testSubCategory)
            
            // 결제수단 생성
            let paymentMethodDTO = PaymentMethodDTO.mockCreditCard
            testPaymentMethod = paymentMethodDTO.toModel()
            context.insert(testPaymentMethod)
            
            try context.save()
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTransaction(
        amount: Decimal = 10000,
        date: Date = Date(),
        place: String? = "맥도날드",
        memo: String? = "점심식사",
        transactionType: TransactionType = .variableExpense
    ) -> TransactionDTO {
        return TransactionDTO(
            amount: amount,
            date: date,
            place: place,
            memo: memo,
            transactionType: transactionType,
            subCategory: testSubCategory.toDTO(),
            paymentMethod: testPaymentMethod.toDTO()
        )
    }
}

// MARK: - TransactionReader Tests

extension TransactionRepositoryTests {
    
    // MARK: - Read Operations Tests
    
    func testTransactionReader_fetchTransaction_withExistingId_returnsTransaction() async throws {
        // Given
        try await setupBasicTestData()
        let originalTransaction = createTransaction()
        try await transactionWriter.insertTransaction(originalTransaction, shouldSave: true)

        // When
        let transaction = try await transactionReader.fetchTransaction(id: originalTransaction.id)

        // Then
        XCTAssertNotNil(transaction)
        XCTAssertEqual(transaction?.id, originalTransaction.id)
        XCTAssertEqual(transaction?.amount, 10000)
        XCTAssertEqual(transaction?.place, "맥도날드")
    }
    
    func testTransactionReader_fetchTransaction_withNonExistingId_returnsNil() async throws {
        // Given
        try await setupBasicTestData()
        let nonExistentId = UUID()
        
        // When
        let transaction = try await transactionReader.fetchTransaction(id: nonExistentId)
        
        // Then
        XCTAssertNil(transaction)
    }
    
    func testTransactionReader_fetchTransactions_forYearMonth_returnsCorrectTransactions() async throws {
        // Given
        try await setupBasicTestData()
        let yearMonth = YearMonth.current
        let transactionInMonth = createTransaction(date: yearMonth.startOfMonth)
        let transactionOutsideMonth = createTransaction(
            date: Calendar.current.date(byAdding: .month, value: -1, to: yearMonth.startOfMonth) ?? Date()
        )
        
        try await transactionWriter.insertTransaction(transactionInMonth, shouldSave: true)
        try await transactionWriter.insertTransaction(transactionOutsideMonth, shouldSave: true)
        
        // When
        let transactions = try await transactionReader.fetchTransactions(for: yearMonth)
        
        // Then
        XCTAssertEqual(transactions.count, 1)
        XCTAssertEqual(transactions[0].id, transactionInMonth.id)
    }
    
    func testTransactionReader_fetchTransactions_dateRange_returnsCorrectTransactions() async throws {
        // Given
        try await setupBasicTestData()
        
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let lastWeek = calendar.date(byAdding: .day, value: -7, to: today)!
        
        let transaction1 = createTransaction(amount: 10000, date: today)
        let transaction2 = createTransaction(amount: 20000, date: yesterday)
        let transaction3 = createTransaction(amount: 30000, date: lastWeek)

        try await transactionWriter.insertTransaction(transaction1, shouldSave: true)
        try await transactionWriter.insertTransaction(transaction2, shouldSave: true)
        try await transactionWriter.insertTransaction(transaction3, shouldSave: true)
        
        // When
        let startDate = calendar.date(byAdding: .day, value: -2, to: today)!
        let endDate = today
        let transactions = try await transactionReader.fetchTransactions(from: startDate, to: endDate)
        
        // Then
        XCTAssertEqual(transactions.count, 2)
        XCTAssertEqual(Set(transactions.map { $0.amount }), Set([10000, 20000]))
    }
    
    func testTransactionReader_getTotalAmountByType_returnsCorrectTotals() async throws {
        // Given
        try await setupBasicTestData()
        
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date())
        let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!
        
        let expense1 = createTransaction(amount: 10000, date: startDate, transactionType: .variableExpense)
        let expense2 = createTransaction(amount: 15000, date: startDate, transactionType: .fixedExpense)
        let income1 = createTransaction(amount: 100000, date: startDate, transactionType: .income)
        
        try await transactionWriter.insertTransaction(expense1, shouldSave: true)
        try await transactionWriter.insertTransaction(expense2, shouldSave: true)
        try await transactionWriter.insertTransaction(income1, shouldSave: true)
        
        // When
        let totals = try await transactionReader.getTotalAmountByType(from: startDate, to: endDate)
        
        // Then
        let totalDict = Dictionary(uniqueKeysWithValues: totals)
        XCTAssertEqual(totalDict[.variableExpense], 10000)
        XCTAssertEqual(totalDict[.fixedExpense], 15000)
        XCTAssertEqual(totalDict[.income], 100000)
    }
    
    func testTransactionReader_getTotalAmountBySubCategory_returnsCorrectTotals() async throws {
        // Given
        try await setupBasicTestData()
        
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date())
        let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!
        
        let transaction1 = createTransaction(amount: 10000, date: startDate)
        let transaction2 = createTransaction(amount: 15000, date: startDate)

        try await transactionWriter.insertTransaction(transaction1, shouldSave: true)
        try await transactionWriter.insertTransaction(transaction2, shouldSave: true)
        
        // When
        let totals = try await transactionReader.getTotalAmountBySubCategory(from: startDate, to: endDate)
        
        // Then
        XCTAssertEqual(totals.count, 1)
        XCTAssertEqual(totals[0].0.id, testSubCategory.id)
        XCTAssertEqual(totals[0].1, 25000) // 10000 + 15000
    }
    
    func testTransactionReader_emptyDatabase_returnsEmptyResults() async throws {
        // Given: 빈 데이터베이스
        
        // When & Then
        let transactions = try await transactionReader.fetchTransactions(for: YearMonth.current)
        XCTAssertTrue(transactions.isEmpty)
        
        let favoriteTransactions = try await transactionReader.fetchFavoriteTransactions()
        XCTAssertTrue(favoriteTransactions.isEmpty)
        
        let totals = try await transactionReader.getTotalAmountByType(from: Date(), to: Date())
        XCTAssertTrue(totals.isEmpty)
    }
}

// MARK: - TransactionWriter Tests

extension TransactionRepositoryTests {
    
    // MARK: - Write Operations Tests
    
    func testTransactionWriter_insertTransaction_insertsSuccessfully() async throws {
        // Given
        try await setupBasicTestData()
        let transaction = createTransaction()
        
        // When
        try await transactionWriter.insertTransaction(transaction, shouldSave: true)

        // Then
        let retrievedTransaction = try await transactionReader.fetchTransaction(id: transaction.id)
        XCTAssertNotNil(retrievedTransaction)
        XCTAssertEqual(retrievedTransaction?.amount, 10000)
        XCTAssertEqual(retrievedTransaction?.place, "맥도날드")
    }
    
    func testTransactionWriter_updateTransaction_updatesSuccessfully() async throws {
        // Given
        try await setupBasicTestData()
        let originalTransaction = createTransaction(amount: 10000, place: "Original Place")
        try await transactionWriter.insertTransaction(originalTransaction, shouldSave: true)
        
        let updatedTransaction = TransactionDTO(
            id: originalTransaction.id,
            amount: 20000,
            date: originalTransaction.date,
            place: "Updated Place",
            memo: "Updated Memo",
            transactionType: originalTransaction.transactionType,
            subCategory: originalTransaction.subCategory,
            paymentMethod: originalTransaction.paymentMethod
        )
        
        // When
        try await transactionWriter.updateTransaction(updatedTransaction)
        
        // Then
        let retrievedTransaction = try await transactionReader.fetchTransaction(id: originalTransaction.id)
        XCTAssertNotNil(retrievedTransaction)
        XCTAssertEqual(retrievedTransaction?.amount, 20000)
        XCTAssertEqual(retrievedTransaction?.place, "Updated Place")
        XCTAssertEqual(retrievedTransaction?.memo, "Updated Memo")
    }
    
    func testTransactionWriter_deleteTransaction_deletesSuccessfully() async throws {
        // Given
        try await setupBasicTestData()
        let transaction = createTransaction()
        try await transactionWriter.insertTransaction(transaction, shouldSave: true)
        
        // Verify transaction exists
        let existingTransaction = try await transactionReader.fetchTransaction(id: transaction.id)
        XCTAssertNotNil(existingTransaction)
        
        // When
        try await transactionWriter.deleteTransaction(id: transaction.id)
        
        // Then
        let deletedTransaction = try await transactionReader.fetchTransaction(id: transaction.id)
        XCTAssertNil(deletedTransaction)
    }
    
    func testTransactionWriter_deleteNonExistentTransaction_throwsError() async throws {
        // Given
        let nonExistentId = UUID()
        
        // When & Then
        do {
            try await transactionWriter.deleteTransaction(id: nonExistentId)
            XCTFail("Expected error to be thrown")
        } catch {
            // Expected behavior - should throw error for non-existent transaction
            XCTAssertTrue(error is RepositoryError)
        }
    }
    
    func testTransactionWriter_multipleOperations_maintainDataIntegrity() async throws {
        // Given
        try await setupBasicTestData()
        
        let transaction1 = createTransaction(amount: 10000, place: "Place 1")
        let transaction2 = createTransaction(amount: 20000, place: "Place 2")
        let transaction3 = createTransaction(amount: 30000, place: "Place 3")

        // When - Multiple insertions
        try await transactionWriter.insertTransaction(transaction1, shouldSave: true)
        try await transactionWriter.insertTransaction(transaction2, shouldSave: true)
        try await transactionWriter.insertTransaction(transaction3, shouldSave: true)
        
        // Then - All transactions should exist
        let allTransactions = try await transactionReader.fetchTransactions(for: YearMonth.current)
        XCTAssertEqual(allTransactions.count, 3)
        
        // When - Update one transaction
        let updatedTransaction2 = TransactionDTO(
            id: transaction2.id,
            amount: 25000,
            date: transaction2.date,
            place: "Updated Place 2",
            memo: transaction2.memo,
            transactionType: transaction2.transactionType,
            subCategory: transaction2.subCategory,
            paymentMethod: transaction2.paymentMethod
        )
        try await transactionWriter.updateTransaction(updatedTransaction2)
        
        // When - Delete one transaction
        try await transactionWriter.deleteTransaction(id: transaction3.id)
        
        // Then - Verify final state
        let finalTransactions = try await transactionReader.fetchTransactions(for: YearMonth.current)
        XCTAssertEqual(finalTransactions.count, 2)
        
        let retrievedTransaction2 = try await transactionReader.fetchTransaction(id: transaction2.id)
        XCTAssertEqual(retrievedTransaction2?.amount, 25000)
        XCTAssertEqual(retrievedTransaction2?.place, "Updated Place 2")
        
        let deletedTransaction = try await transactionReader.fetchTransaction(id: transaction3.id)
        XCTAssertNil(deletedTransaction)
    }
}

// MARK: - Integration Tests (Combined Reader + Writer)

extension TransactionRepositoryTests {
    
    func testIntegration_readerWriter_workTogether() async throws {
        // Given
        try await setupBasicTestData()
        
        // Writer operations
        let transaction1 = createTransaction(amount: 10000)
        let transaction2 = createTransaction(amount: 20000)

        try await transactionWriter.insertTransaction(transaction1, shouldSave: true)
        try await transactionWriter.insertTransaction(transaction2, shouldSave: true)
        
        // Reader operations to verify
        let allTransactions = try await transactionReader.fetchTransactions(for: YearMonth.current)
        XCTAssertEqual(allTransactions.count, 2)
        
//        let favoriteTransactions = try await transactionReader.fetchFavoriteTransactions()
//        XCTAssertEqual(favoriteTransactions.count, 1)
//        XCTAssertEqual(favoriteTransactions[0].id, transaction1.id)
        
        // Combined operation: Update through Writer, verify through Reader
        let updatedTransaction1 = TransactionDTO(
            id: transaction1.id,
            amount: 15000,
            date: transaction1.date,
            place: transaction1.place,
            memo: "Updated memo",
            transactionType: transaction1.transactionType,
            subCategory: transaction1.subCategory,
            paymentMethod: transaction1.paymentMethod
        )
        
        try await transactionWriter.updateTransaction(updatedTransaction1)
        
        // Verify changes through Reader
//        let updatedFavorites = try await transactionReader.fetchFavoriteTransactions()
//        XCTAssertEqual(updatedFavorites.count, 0) // Should be empty now
        
        let retrievedUpdated = try await transactionReader.fetchTransaction(id: transaction1.id)
        XCTAssertEqual(retrievedUpdated?.amount, 15000)
        XCTAssertEqual(retrievedUpdated?.memo, "Updated memo")
//        XCTAssertFalse(retrievedUpdated?.isFavorite ?? true)
    }

    // MARK: - shouldSave Parameter Tests

    func testTransactionWriter_insertTransaction_withShouldSaveTrue_savesToDatabase() async throws {
        // Given
        try await setupBasicTestData()
        let transaction = createTransaction(amount: 10000, place: "테스트 장소")

        // When
        try await transactionWriter.insertTransaction(transaction, shouldSave: true)

        // Then
        let retrievedTransaction = try await transactionReader.fetchTransaction(id: transaction.id)
        XCTAssertNotNil(retrievedTransaction, "shouldSave: true일 때 DB에 저장되어야 함")
        XCTAssertEqual(retrievedTransaction?.amount, 10000)
        XCTAssertEqual(retrievedTransaction?.place, "테스트 장소")
    }

    func testTransactionWriter_insertTransaction_withShouldSaveFalse_doesNotCommitToDatabase() async throws {
        // Given
        try await setupBasicTestData()
        let transaction = createTransaction(amount: 15000, place: "임시 데이터")

        // When
        try await transactionWriter.insertTransaction(transaction, shouldSave: false)

        // Then
        // 새로운 context에서 조회했을 때 데이터가 없어야 함 (커밋되지 않았으므로)
        let retrievedTransaction = try await transactionReader.fetchTransaction(id: transaction.id)
        XCTAssertNotNil(retrievedTransaction, "shouldSave: false일 때 DB에 커밋되지 않아야 함")
        let id = transaction.id
        try await database.withModelContext { context in
            context.rollback()
            let predicate = #Predicate<Transaction> { $0.id == id }
            let descriptor = FetchDescriptor<Transaction>(predicate: predicate)
            let result = try context.fetch(descriptor).first
            XCTAssertNil(result, "shouldSave: false일 때 DB에 커밋되지 않아야 함")
        }
    }

    func testTransactionWriter_multipleOperations_withBatchSave_maintainsAtomicity() async throws {
        // Given
        try await setupBasicTestData()
        let transaction1 = createTransaction(amount: 10000, place: "장소1")
        let transaction2 = createTransaction(amount: 20000, place: "장소2")

        // When - 여러 작업을 shouldSave: false로 수행 후 마지막에 커밋
        try await transactionWriter.insertTransaction(transaction1, shouldSave: false)
        try await transactionWriter.insertTransaction(transaction2, shouldSave: false)
        try await database.withModelContext { context in
            try context.save()
        }

        // Then - 모든 거래가 한 번에 저장되어야 함
        let retrievedTransaction1 = try await transactionReader.fetchTransaction(id: transaction1.id)
        let retrievedTransaction2 = try await transactionReader.fetchTransaction(id: transaction2.id)

        XCTAssertNotNil(retrievedTransaction1, "배치 저장 후 첫 번째 거래가 존재해야 함")
        XCTAssertNotNil(retrievedTransaction2, "배치 저장 후 두 번째 거래가 존재해야 함")
        XCTAssertEqual(retrievedTransaction1?.place, "장소1")
        XCTAssertEqual(retrievedTransaction2?.place, "장소2")
    }
}
