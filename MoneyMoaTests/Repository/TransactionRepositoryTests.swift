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
    
    // 테스트용 기본 데이터
    private var testCategory: CategoryModel!
    private var testSubCategory: SubCategoryModel!
    private var testPaymentMethod: PaymentMethodModel!
    
    override func setUpWithError() throws {
        database = try Database(isStoredInMemoryOnly: true)
        repository = TransactionRepositoryImpl(database: database)
    }
    
    override func tearDownWithError() throws {
        database = nil
        repository = nil
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
        transactionType: TransactionType = .variableExpense,
        isFavorite: Bool = false
    ) -> TransactionDTO {
        return TransactionDTO(
            amount: amount,
            date: date,
            place: place,
            memo: memo,
            transactionType: transactionType,
            isFavorite: isFavorite,
            subCategory: testSubCategory.toDTO(),
            paymentMethod: testPaymentMethod.toDTO()
        )
    }
    
    // MARK: - 조회 테스트 (Fetch Operations)
    
    func testFetchTransactions_EmptyDatabase() async throws {
        // Given: 빈 데이터베이스
        
        // When: 모든 거래 조회
        let transactions = try await repository.fetchTransactions()
        
        // Then: 빈 배열 반환
        XCTAssertTrue(transactions.isEmpty)
    }
    
    func testFetchTransactions_WithData() async throws {
        // Given: 기본 테스트 데이터 설정
        try await setupBasicTestData()
        
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today
        let dayBeforeYesterday = Calendar.current.date(byAdding: .day, value: -2, to: today) ?? today
        
        try await repository.insertTransaction(createTransaction(amount: 10000, date: yesterday))
        try await repository.insertTransaction(createTransaction(amount: 20000, date: today))
        try await repository.insertTransaction(createTransaction(amount: 15000, date: dayBeforeYesterday))
        
        let transactions = try await repository.fetchTransactions()
        XCTAssertEqual(transactions.count, 3)
        XCTAssertEqual(transactions[0].amount, 20000) // 오늘 (최신)
        XCTAssertEqual(transactions[1].amount, 10000) // 어제
        XCTAssertEqual(transactions[2].amount, 15000) // 그저께
    }
    
    func testFetchTransaction() async throws {
        try await setupBasicTestData()
        
        let originalTransaction = createTransaction()
        try await repository.insertTransaction(originalTransaction)
        
        // 존재하는 ID 조회
        let transaction = try await repository.fetchTransaction(id: originalTransaction.id)
        XCTAssertEqual(transaction?.id, originalTransaction.id)
        XCTAssertEqual(transaction?.amount, 10000)
        XCTAssertEqual(transaction?.place, "맥도날드")
        
        let nonExistentTransaction = try await repository.fetchTransaction(id: UUID())
        XCTAssertNil(nonExistentTransaction)
    }
    
    func testFetchTransactions_DateRange() async throws {
        // Given: 기본 테스트 데이터 설정
        try await setupBasicTestData()
        
        // Given: 다양한 날짜의 거래들 생성
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let lastWeek = calendar.date(byAdding: .day, value: -7, to: today)!
        
        let transaction1 = createTransaction(amount: 10000, date: today)
        let transaction2 = createTransaction(amount: 20000, date: yesterday)
        let transaction3 = createTransaction(amount: 30000, date: lastWeek)
        
        try await repository.insertTransaction(transaction1)
        try await repository.insertTransaction(transaction2)
        try await repository.insertTransaction(transaction3)
        
        // When: 최근 3일 거래 조회
        let startDate = calendar.date(byAdding: .day, value: -2, to: today)!
        let endDate = today
        let transactions = try await repository.fetchTransactions(from: startDate, to: endDate)
        
        // Then: 해당 기간의 거래만 반환
        XCTAssertEqual(transactions.count, 2)
        XCTAssertTrue(transactions.contains { $0.amount == 10000 })
        XCTAssertTrue(transactions.contains { $0.amount == 20000 })
    }
    
    func testFetchTransactions_YearMonth() async throws {
        // Given: 기본 테스트 데이터 설정
        try await setupBasicTestData()
        
        // Given: 다양한 월의 거래들 생성
        let currentMonth = YearMonth.current
        let lastMonth = currentMonth.previousMonth()
        
        let thisMonthTransaction = createTransaction(
            amount: 10000,
            date: currentMonth.startOfMonth
        )
        let lastMonthTransaction = createTransaction(
            amount: 20000,
            date: lastMonth.startOfMonth
        )
        
        try await repository.insertTransaction(thisMonthTransaction)
        try await repository.insertTransaction(lastMonthTransaction)
        
        // When: 현재 월 거래 조회
        let transactions = try await repository.fetchTransactions(for: currentMonth)
        
        // Then: 현재 월 거래만 반환
        XCTAssertEqual(transactions.count, 1)
        XCTAssertEqual(transactions.first?.amount, 10000)
    }
    
    func testFetchTransactionsByType() async throws {
        // Given: 기본 테스트 데이터 설정
        try await setupBasicTestData()
        
        // Given: 다양한 유형의 거래들 생성
        let expenseTransaction = createTransaction(
            amount: 50000,
            transactionType: .variableExpense
        )
        let incomeTransaction = createTransaction(
            amount: 1000000,
            transactionType: .income
        )
        
        try await repository.insertTransaction(expenseTransaction)
        try await repository.insertTransaction(incomeTransaction)
        
        let transactions = try await repository.fetchTransactionsByType(.variableExpense)
        XCTAssertEqual(transactions.count, 1)
        XCTAssertEqual(transactions.first?.amount, 50000)
    }
    
    func testFetchFavoriteTransactions() async throws {
        // Given: 기본 테스트 데이터 설정
        try await setupBasicTestData()
        
        // Given: 즐겨찾기/일반 거래들 생성
        let favoriteTransaction = createTransaction(amount: 10000, isFavorite: true)
        let normalTransaction = createTransaction(amount: 20000, isFavorite: false)
        
        try await repository.insertTransaction(favoriteTransaction)
        try await repository.insertTransaction(normalTransaction)
        
        // When: 즐겨찾기 거래 조회
        let transactions = try await repository.fetchFavoriteTransactions()
        
        // Then: 즐겨찾기 거래만 반환
        XCTAssertEqual(transactions.count, 1)
        XCTAssertTrue(transactions.first?.isFavorite ?? false)
        XCTAssertEqual(transactions.first?.amount, 10000)
    }
    
    func testSearchTransactions() async throws {
        // Given: 기본 테스트 데이터 설정
        try await setupBasicTestData()
        
        // Given: 다양한 메모와 장소의 거래들 생성
        let transaction1 = createTransaction(place: "스타벅스", memo: "커피")
        let transaction2 = createTransaction(place: "맥도날드", memo: "햄버거")
        let transaction3 = createTransaction(place: "편의점", memo: "생수")
        
        try await repository.insertTransaction(transaction1)
        try await repository.insertTransaction(transaction2)
        try await repository.insertTransaction(transaction3)
        
        // When: "스타"로 검색
        let transactions = try await repository.searchTransactions(keyword: "스타")
        
        // Then: 해당 키워드가 포함된 거래만 반환
        XCTAssertEqual(transactions.count, 1)
        XCTAssertEqual(transactions.first?.place, "스타벅스")
    }
    
    // MARK: - 집계 및 통계 테스트 (Aggregation & Statistics)
    
    func testGetTotalAmountByType_DateRange() async throws {
        // Given: 기본 테스트 데이터 설정
        try await setupBasicTestData()
        
        // Given: 다양한 유형의 거래들 생성
        let today = Date()
        let expenseTransaction1 = createTransaction(amount: 50000, date: today, transactionType: .variableExpense)
        let expenseTransaction2 = createTransaction(amount: 30000, date: today, transactionType: .variableExpense)
        
        try await repository.insertTransaction(expenseTransaction1)
        try await repository.insertTransaction(expenseTransaction2)
        
        // When: 오늘 거래 유형별 합계 조회
        let startOfDay = Calendar.current.startOfDay(for: today)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let totals = try await repository.getTotalAmountByType(from: startOfDay, to: endOfDay)
        
        // Then: 유형별 합계 반환
        XCTAssertEqual(totals.count, 1)
        let expenseTotal = totals.first { $0.0 == .variableExpense }?.1
        XCTAssertEqual(expenseTotal, 80000) // 50000 + 30000
    }
    
    func testGetTotalAmountByType_YearMonth() async throws {
        // Given: 기본 테스트 데이터 설정
        try await setupBasicTestData()
        
        // Given: 현재 월과 이전 월 거래들 생성
        let currentMonth = YearMonth.current
        let lastMonth = currentMonth.previousMonth()
        
        let thisMonthTransaction = createTransaction(amount: 100000, date: currentMonth.startOfMonth, transactionType: .variableExpense)
        let lastMonthTransaction = createTransaction(amount: 50000, date: lastMonth.startOfMonth, transactionType: .variableExpense)
        
        try await repository.insertTransaction(thisMonthTransaction)
        try await repository.insertTransaction(lastMonthTransaction)
        
        // When: 현재 월 거래 유형별 합계 조회
        let totals = try await repository.getTotalAmountByType(for: currentMonth)
        
        // Then: 현재 월 합계만 반환
        XCTAssertEqual(totals.count, 1)
        XCTAssertEqual(totals.first?.0, .variableExpense)
        XCTAssertEqual(totals.first?.1, 100000)
    }
    
    func testGetDailyTotals() async throws {
        // Given: 기본 테스트 데이터 설정
        try await setupBasicTestData()
        
        // Given: 같은 날 여러 거래 생성
        let today = Date()
        let transaction1 = createTransaction(amount: 10000, date: today)
        let transaction2 = createTransaction(amount: 20000, date: today)
        
        try await repository.insertTransaction(transaction1)
        try await repository.insertTransaction(transaction2)
        
        // When: 오늘 일별 합계 조회
        let startOfDay = Calendar.current.startOfDay(for: today)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let dailyTotals = try await repository.getDailyTotals(from: startOfDay, to: endOfDay, type: nil)
        
        // Then: 일별 합계 반환
        XCTAssertEqual(dailyTotals.count, 1)
        XCTAssertEqual(dailyTotals.first?.1, 30000) // 10000 + 20000
    }
    
    // MARK: - 생성/수정 테스트 (Create/Update Operations)
    
    func testInsertTransaction_Success() async throws {
        // Given: 기본 테스트 데이터 설정
        try await setupBasicTestData()
        
        // Given: 새로운 거래 DTO
        let transaction = createTransaction() // 모든 기본값 사용
        
        // When: 거래 삽입
        try await repository.insertTransaction(transaction)
        
        // Then: 데이터베이스에 저장됨
        let transactions = try await repository.fetchTransactions()
        XCTAssertEqual(transactions.count, 1)
        XCTAssertEqual(transactions.first?.amount, 10000)
        XCTAssertEqual(transactions.first?.place, "맥도날드")
    }
    
    func testInsertTransaction_InvalidSubCategory() async throws {
        // Given: 기본 테스트 데이터 설정
        try await setupBasicTestData()
        
        // Given: 존재하지 않는 서브카테고리를 가진 거래
        let invalidSubCategory = SubCategoryDTO(
            name: "존재하지않음",
            transactionType: .variableExpense,
            categoryId: UUID(),
            categoryName: "존재하지않음",
            categoryIconName: "questionmark"
        )
        
        let transaction = TransactionDTO(
            amount: 10000,
            date: Date(),
            place: "테스트",
            memo: "테스트",
            transactionType: .variableExpense,
            isFavorite: false,
            subCategory: invalidSubCategory,
            paymentMethod: testPaymentMethod.toDTO()
        )
        
        // When & Then: 에러 발생
        do {
            try await repository.insertTransaction(transaction)
            XCTFail("Expected error to be thrown")
        } catch {
            switch error {
            case RepositoryError.subCategoryNotFound:
                break // 예상된 에러
            default:
                XCTFail("Expected subCategoryNotFound error, but got \(error)")
            }
        }
    }
    
    func testUpdateTransaction_Success() async throws {
        // Given: 기본 테스트 데이터 설정
        try await setupBasicTestData()
        
        // Given: 기존 거래 생성
        let originalTransaction = createTransaction() // 모든 기본값 사용
        try await repository.insertTransaction(originalTransaction)
        
        // When: 거래 정보 수정
        let updatedTransaction = TransactionDTO(
            id: originalTransaction.id,
            amount: 15000,
            date: originalTransaction.date,
            place: "버거킹",
            memo: "저녁식사",
            transactionType: originalTransaction.transactionType,
            isFavorite: true,
            subCategory: testSubCategory.toDTO(),
            paymentMethod: testPaymentMethod.toDTO()
        )
        try await repository.updateTransaction(updatedTransaction)
        
        // Then: 변경사항이 반영됨
        let transaction = try await repository.fetchTransaction(id: originalTransaction.id)
        XCTAssertEqual(transaction?.amount, 15000)
        XCTAssertEqual(transaction?.place, "버거킹")
        XCTAssertEqual(transaction?.memo, "저녁식사")
        XCTAssertTrue(transaction?.isFavorite ?? false)
    }
    
    func testToggleFavorite_Success() async throws {
        // Given: 기본 테스트 데이터 설정
        try await setupBasicTestData()
        
        // Given: 일반 거래 생성
        let transaction = createTransaction(isFavorite: false)
        try await repository.insertTransaction(transaction)
        
        // When: 즐겨찾기 토글
        try await repository.toggleFavorite(id: transaction.id)
        
        // Then: 즐겨찾기 상태로 변경됨
        let updatedTransaction = try await repository.fetchTransaction(id: transaction.id)
        XCTAssertTrue(updatedTransaction?.isFavorite ?? false)
        
        // When: 다시 토글
        try await repository.toggleFavorite(id: transaction.id)
        
        // Then: 일반 상태로 변경됨
        let reToggleTransaction = try await repository.fetchTransaction(id: transaction.id)
        XCTAssertFalse(reToggleTransaction?.isFavorite ?? true)
    }
    
    // MARK: - 삭제 테스트 (Delete Operations)
    
    func testDeleteTransaction() async throws {
        try await setupBasicTestData()
        
        // 삭제 성공
        let transaction = createTransaction()
        try await repository.insertTransaction(transaction)
        try await repository.deleteTransaction(id: transaction.id)
        let transactionsAfterDelete = try await repository.fetchTransactions()
        XCTAssertTrue(transactionsAfterDelete.isEmpty)
        
        do {
            try await repository.deleteTransaction(id: UUID())
            XCTFail("Expected error")
        } catch RepositoryError.transactionNotFound {
            // Expected
        }
    }
    
    func testDeleteTransactions_Multiple() async throws {
        // Given: 기본 테스트 데이터 설정
        try await setupBasicTestData()
        
        // Given: 여러 거래 생성
        let transaction1 = createTransaction(amount: 10000)
        let transaction2 = createTransaction(amount: 20000)
        let transaction3 = createTransaction(amount: 30000)
        
        try await repository.insertTransaction(transaction1)
        try await repository.insertTransaction(transaction2)
        try await repository.insertTransaction(transaction3)
        
        // When: 두 거래 삭제
        try await repository.deleteTransactions(ids: [transaction1.id, transaction3.id])
        
        // Then: 해당 거래들만 삭제됨
        let transactions = try await repository.fetchTransactions()
        XCTAssertEqual(transactions.count, 1)
        XCTAssertEqual(transactions.first?.amount, 20000)
    }
    
    // MARK: - 검증 테스트 (Validation)
    
    func testValidateExists() async throws {
        try await setupBasicTestData()
        
        let validSubCategory = try await repository.validateSubCategoryExists(id: testSubCategory.id)
        let invalidSubCategory = try await repository.validateSubCategoryExists(id: UUID())
        XCTAssertTrue(validSubCategory)
        XCTAssertFalse(invalidSubCategory)
        
        let validPaymentMethod = try await repository.validatePaymentMethodExists(id: testPaymentMethod.id)
        let invalidPaymentMethod = try await repository.validatePaymentMethodExists(id: UUID())
        XCTAssertTrue(validPaymentMethod)
        XCTAssertFalse(invalidPaymentMethod)
    }
    
    // MARK: - YearMonth 유틸리티 테스트
    
    func testYearMonth_StartAndEndOfMonth() {
        let yearMonth = YearMonth(year: 2024, month: 7)
        let calendar = Calendar.current
        
        let startComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: yearMonth.startOfMonth)
        XCTAssertEqual(startComponents, DateComponents(year: 2024, month: 7, day: 1, hour: 0, minute: 0, second: 0))
        
        let endComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: yearMonth.endOfMonth)
        XCTAssertEqual(endComponents.year, 2024)
        XCTAssertEqual(endComponents.month, 7)
        XCTAssertEqual(endComponents.day, 31)
        XCTAssertEqual(endComponents.hour, 23)
        XCTAssertEqual(endComponents.minute, 59)
        XCTAssertEqual(endComponents.second, 59)
    }
}
