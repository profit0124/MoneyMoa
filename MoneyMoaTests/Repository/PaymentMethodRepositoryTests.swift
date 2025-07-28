//
//  PaymentMethodRepositoryTests.swift
//  MoneyMoaTests
//
//  Created by Sooik Kim on 7/28/25.
//

import XCTest
import SwiftData
@testable import MoneyMoa

final class PaymentMethodRepositoryTests: XCTestCase {
    
    private var database: Database!
    private var repository: PaymentMethodRepositoryImpl!
    
    override func setUpWithError() throws {
        // 각 테스트마다 새로운 인메모리 데이터베이스 생성
        database = try Database(isStoredInMemoryOnly: true)
        repository = PaymentMethodRepositoryImpl(database: database)
    }
    
    override func tearDownWithError() throws {
        database = nil
        repository = nil
    }
    
    // MARK: - 조회 테스트 (Fetch Operations)
    
    func testFetchPaymentMethods_EmptyDatabase() async throws {
        // Given: 빈 데이터베이스
        
        // When: 모든 결제수단 조회
        let paymentMethods = try await repository.fetchPaymentMethods()
        
        // Then: 빈 배열 반환
        XCTAssertTrue(paymentMethods.isEmpty)
    }
    
    func testFetchPaymentMethods_WithData() async throws {
        // Given: 테스트 결제수단들 생성
        let paymentMethod1 = TestDataFactory.createPaymentMethod(name: "신용카드", kind: .credit, orderIndex: 1)
        let paymentMethod2 = TestDataFactory.createPaymentMethod(name: "체크카드", kind: .debit, orderIndex: 0)
        let paymentMethod3 = TestDataFactory.createPaymentMethod(name: "현금", kind: .cash, orderIndex: 2)
        
        try await repository.insertPaymentMethod(paymentMethod1)
        try await repository.insertPaymentMethod(paymentMethod2)
        try await repository.insertPaymentMethod(paymentMethod3)
        
        // When: 모든 결제수단 조회
        let paymentMethods = try await repository.fetchPaymentMethods()
        
        // Then: orderIndex 순으로 정렬되어 반환
        XCTAssertEqual(paymentMethods.count, 3)
        XCTAssertEqual(paymentMethods[0].name, "체크카드") // orderIndex: 0
        XCTAssertEqual(paymentMethods[1].name, "신용카드") // orderIndex: 1  
        XCTAssertEqual(paymentMethods[2].name, "현금")     // orderIndex: 2
    }
    
    func testFetchPaymentMethod_ExistingId() async throws {
        // Given: 테스트 결제수단 생성
        let originalPaymentMethod = TestDataFactory.createPaymentMethod(name: "신용카드", kind: .credit)
        try await repository.insertPaymentMethod(originalPaymentMethod)
        
        // When: 특정 결제수단 조회
        let paymentMethod = try await repository.fetchPaymentMethod(id: originalPaymentMethod.id)
        
        // Then: 해당 결제수단 반환
        XCTAssertNotNil(paymentMethod)
        XCTAssertEqual(paymentMethod?.id, originalPaymentMethod.id)
        XCTAssertEqual(paymentMethod?.name, "신용카드")
        XCTAssertEqual(paymentMethod?.kind, .credit)
    }
    
    func testFetchPaymentMethod_NonExistingId() async throws {
        // Given: 빈 데이터베이스
        let nonExistingId = UUID()
        
        // When: 존재하지 않는 ID로 조회
        let paymentMethod = try await repository.fetchPaymentMethod(id: nonExistingId)
        
        // Then: nil 반환
        XCTAssertNil(paymentMethod)
    }
    
    func testFetchActivePaymentMethods() async throws {
        // Given: 활성/비활성 결제수단들 생성
        let activePaymentMethod = TestDataFactory.createPaymentMethod(name: "활성결제수단", kind: .credit, isActive: true)
        let inactivePaymentMethod = TestDataFactory.createPaymentMethod(name: "비활성결제수단", kind: .debit, isActive: false)
        
        try await repository.insertPaymentMethod(activePaymentMethod)
        try await repository.insertPaymentMethod(inactivePaymentMethod)
        
        // When: 활성 결제수단만 조회
        let paymentMethods = try await repository.fetchActivePaymentMethods()
        
        // Then: 활성 결제수단만 반환
        XCTAssertEqual(paymentMethods.count, 1)
        XCTAssertEqual(paymentMethods.first?.name, "활성결제수단")
        XCTAssertTrue(paymentMethods.first?.isActive ?? false)
    }
    
    func testFetchPaymentMethodsByKind() async throws {
        // Given: 다양한 종류의 결제수단들 생성
        let creditCard = TestDataFactory.createPaymentMethod(name: "신용카드", kind: .credit)
        let debitCard = TestDataFactory.createPaymentMethod(name: "체크카드", kind: .debit)
        let cash = TestDataFactory.createPaymentMethod(name: "현금", kind: .cash)
        let transfer = TestDataFactory.createPaymentMethod(name: "계좌이체", kind: .transfer)
        
        try await repository.insertPaymentMethod(creditCard)
        try await repository.insertPaymentMethod(debitCard)
        try await repository.insertPaymentMethod(cash)
        try await repository.insertPaymentMethod(transfer)
        
        // When: 신용카드 종류만 조회
        let paymentMethods = try await repository.fetchPaymentMethodsByKind(.credit)
        
        // Then: 해당 종류의 결제수단만 반환
        XCTAssertEqual(paymentMethods.count, 1)
        XCTAssertEqual(paymentMethods.first?.name, "신용카드")
        XCTAssertEqual(paymentMethods.first?.kind, .credit)
    }
    
    // MARK: - 생성/수정 테스트 (Create/Update Operations)
    
    func testInsertPaymentMethod_Success() async throws {
        // Given: 새로운 결제수단 DTO
        let paymentMethod = TestDataFactory.createPaymentMethod(name: "신용카드", kind: .credit)
        
        // When: 결제수단 삽입
        try await repository.insertPaymentMethod(paymentMethod)
        
        // Then: 데이터베이스에 저장됨
        let paymentMethods = try await repository.fetchPaymentMethods()
        XCTAssertEqual(paymentMethods.count, 1)
        XCTAssertEqual(paymentMethods.first?.name, "신용카드")
        XCTAssertEqual(paymentMethods.first?.id, paymentMethod.id)
    }
    
    func testUpdatePaymentMethod_Success() async throws {
        // Given: 기존 결제수단 생성
        let originalPaymentMethod = TestDataFactory.createPaymentMethod(name: "신용카드", kind: .credit, orderIndex: 0)
        try await repository.insertPaymentMethod(originalPaymentMethod)
        
        // When: 결제수단 정보 수정
        let updatedPaymentMethod = PaymentMethodDTO(
            id: originalPaymentMethod.id,
            name: "새신용카드",
            kind: .credit,
            orderIndex: 1,
            isActive: false
        )
        try await repository.updatePaymentMethod(updatedPaymentMethod)
        
        // Then: 변경사항이 반영됨
        let paymentMethod = try await repository.fetchPaymentMethod(id: originalPaymentMethod.id)
        XCTAssertEqual(paymentMethod?.name, "새신용카드")
        XCTAssertFalse(paymentMethod?.isActive ?? true)
        XCTAssertEqual(paymentMethod?.orderIndex, 1)
    }
    
    func testUpdatePaymentMethod_NonExistingPaymentMethod() async throws {
        // Given: 존재하지 않는 결제수단 ID
        let nonExistingPaymentMethod = TestDataFactory.createPaymentMethod(name: "존재하지않음", kind: .credit)
        
        // When & Then: 에러 발생
        do {
            try await repository.updatePaymentMethod(nonExistingPaymentMethod)
            XCTFail("Expected error to be thrown")
        } catch {
            switch error {
            case RepositoryError.paymentMethodNotFound:
                break // 예상된 에러
            default:
                XCTFail("Expected paymentMethodNotFound error, but got \(error)")
            }
        }
    }
    
    func testUpdatePaymentMethodOrder_Success() async throws {
        // Given: 여러 결제수단 생성
        let paymentMethod1 = TestDataFactory.createPaymentMethod(name: "첫번째", kind: .credit, orderIndex: 0)
        let paymentMethod2 = TestDataFactory.createPaymentMethod(name: "두번째", kind: .debit, orderIndex: 1)
        let paymentMethod3 = TestDataFactory.createPaymentMethod(name: "세번째", kind: .cash, orderIndex: 2)
        
        try await repository.insertPaymentMethod(paymentMethod1)
        try await repository.insertPaymentMethod(paymentMethod2)
        try await repository.insertPaymentMethod(paymentMethod3)
        
        // When: 순서 변경 (역순으로)
        let reorderedPaymentMethods = [paymentMethod3, paymentMethod2, paymentMethod1]
        try await repository.updatePaymentMethodOrder(reorderedPaymentMethods)
        
        // Then: 새로운 순서로 정렬됨
        let paymentMethods = try await repository.fetchPaymentMethods()
        XCTAssertEqual(paymentMethods[0].name, "세번째") // orderIndex: 0
        XCTAssertEqual(paymentMethods[1].name, "두번째") // orderIndex: 1
        XCTAssertEqual(paymentMethods[2].name, "첫번째") // orderIndex: 2
    }
    
    // MARK: - 활성/비활성 관리 테스트 (Activation Management)
    
    func testDeactivatePaymentMethod_Success() async throws {
        // Given: 활성 결제수단 생성
        let paymentMethod = TestDataFactory.createPaymentMethod(name: "신용카드", kind: .credit, isActive: true)
        try await repository.insertPaymentMethod(paymentMethod)
        
        // When: 결제수단 비활성화
        try await repository.deactivatePaymentMethod(id: paymentMethod.id)
        
        // Then: 비활성 상태로 변경됨
        let updatedPaymentMethod = try await repository.fetchPaymentMethod(id: paymentMethod.id)
        XCTAssertFalse(updatedPaymentMethod?.isActive ?? true)
    }
    
    func testDeactivatePaymentMethod_NonExistingPaymentMethod() async throws {
        // Given: 존재하지 않는 결제수단 ID
        let nonExistingId = UUID()
        
        // When & Then: 에러 발생
        do {
            try await repository.deactivatePaymentMethod(id: nonExistingId)
            XCTFail("Expected error to be thrown")
        } catch {
            switch error {
            case RepositoryError.paymentMethodNotFound:
                break // 예상된 에러
            default:
                XCTFail("Expected paymentMethodNotFound error, but got \(error)")
            }
        }
    }
    
    func testActivatePaymentMethod_Success() async throws {
        // Given: 비활성 결제수단 생성
        let paymentMethod = TestDataFactory.createPaymentMethod(name: "신용카드", kind: .credit, isActive: false)
        try await repository.insertPaymentMethod(paymentMethod)
        
        // When: 결제수단 활성화
        try await repository.activatePaymentMethod(id: paymentMethod.id)
        
        // Then: 활성 상태로 변경됨
        let updatedPaymentMethod = try await repository.fetchPaymentMethod(id: paymentMethod.id)
        XCTAssertTrue(updatedPaymentMethod?.isActive ?? false)
    }
    
    func testActivatePaymentMethod_NonExistingPaymentMethod() async throws {
        // Given: 존재하지 않는 결제수단 ID
        let nonExistingId = UUID()
        
        // When & Then: 에러 발생
        do {
            try await repository.activatePaymentMethod(id: nonExistingId)
            XCTFail("Expected error to be thrown")
        } catch {
            switch error {
            case RepositoryError.paymentMethodNotFound:
                break // 예상된 에러
            default:
                XCTFail("Expected paymentMethodNotFound error, but got \(error)")
            }
        }
    }
    
    // MARK: - 삭제 테스트 (Delete Operations)
    
    func testDeletePaymentMethod_InactivePaymentMethod_Success() async throws {
        // Given: 비활성 결제수단 생성
        let paymentMethod = TestDataFactory.createPaymentMethod(name: "신용카드", kind: .credit, isActive: false)
        try await repository.insertPaymentMethod(paymentMethod)
        
        // When: 결제수단 삭제
        try await repository.deletePaymentMethod(id: paymentMethod.id)
        
        // Then: 데이터베이스에서 삭제됨
        let paymentMethods = try await repository.fetchPaymentMethods()
        XCTAssertTrue(paymentMethods.isEmpty)
    }
    
    func testDeletePaymentMethod_ActivePaymentMethod_ThrowsError() async throws {
        // Given: 활성 결제수단 생성
        let paymentMethod = TestDataFactory.createPaymentMethod(name: "신용카드", kind: .credit, isActive: true)
        try await repository.insertPaymentMethod(paymentMethod)
        
        // When & Then: 에러 발생
        do {
            try await repository.deletePaymentMethod(id: paymentMethod.id)
            XCTFail("Expected error to be thrown")
        } catch {
            switch error {
            case RepositoryError.cannotDeleteActivePaymentMethod:
                break // 예상된 에러
            default:
                XCTFail("Expected cannotDeleteActivePaymentMethod error, but got \(error)")
            }
        }
        
        // 결제수단이 여전히 존재함
        let paymentMethods = try await repository.fetchPaymentMethods()
        XCTAssertEqual(paymentMethods.count, 1)
    }
    
    func testDeletePaymentMethod_NonExistingPaymentMethod() async throws {
        // Given: 존재하지 않는 결제수단 ID
        let nonExistingId = UUID()
        
        // When & Then: 에러 발생
        do {
            try await repository.deletePaymentMethod(id: nonExistingId)
            XCTFail("Expected error to be thrown")
        } catch {
            switch error {
            case RepositoryError.paymentMethodNotFound:
                break // 예상된 에러
            default:
                XCTFail("Expected paymentMethodNotFound error, but got \(error)")
            }
        }
    }
    
    // MARK: - 검증 테스트 (Validation)
    
    func testValidatePaymentMethodName_AvailableName() async throws {
        // Given: 기존 결제수단 생성
        let existingPaymentMethod = TestDataFactory.createPaymentMethod(name: "국민카드", kind: .credit)
        try await repository.insertPaymentMethod(existingPaymentMethod)
        
        // When: 다른 이름으로 검증
        let isValid = try await repository.validatePaymentMethodName("신한카드", kind: .credit, excludingId: nil)
        
        // Then: 사용 가능
        XCTAssertTrue(isValid)
    }
    
    func testValidatePaymentMethodName_DuplicateName_SameKind() async throws {
        // Given: 기존 결제수단 생성
        let existingPaymentMethod = TestDataFactory.createPaymentMethod(name: "국민카드", kind: .credit)
        try await repository.insertPaymentMethod(existingPaymentMethod)
        
        // When: 동일한 이름과 종류로 검증
        let isValid = try await repository.validatePaymentMethodName("국민카드", kind: .credit, excludingId: nil)
        
        // Then: 사용 불가능
        XCTAssertFalse(isValid)
    }
    
    func testValidatePaymentMethodName_DuplicateNameButDifferentKind() async throws {
        // Given: 기존 결제수단 생성 (신용카드)
        let existingPaymentMethod = TestDataFactory.createPaymentMethod(name: "국민카드", kind: .credit)
        try await repository.insertPaymentMethod(existingPaymentMethod)
        
        // When: 동일한 이름이지만 다른 종류로 검증 (체크카드)
        let isValid = try await repository.validatePaymentMethodName("국민카드", kind: .debit, excludingId: nil)
        
        // Then: 사용 가능 (다른 결제수단 종류이므로)
        XCTAssertTrue(isValid)
    }
    
    func testValidatePaymentMethodName_ExcludingSelf() async throws {
        // Given: 기존 결제수단 생성
        let existingPaymentMethod = TestDataFactory.createPaymentMethod(name: "국민카드", kind: .credit)
        try await repository.insertPaymentMethod(existingPaymentMethod)
        
        // When: 자기 자신을 제외하고 검증 (수정 시나리오)
        let isValid = try await repository.validatePaymentMethodName("국민카드", kind: .credit, excludingId: existingPaymentMethod.id)
        
        // Then: 사용 가능 (자기 자신 제외)
        XCTAssertTrue(isValid)
    }
    
    func testHasTransactions_WithTransactions() async throws {
        // Given: 결제수단, 카테고리, 서브카테고리, 거래 내역 생성
        let paymentMethod = TestDataFactory.createPaymentMethod(name: "신용카드", kind: .credit)
        try await repository.insertPaymentMethod(paymentMethod)
        
        // 데이터베이스에 직접 카테고리, 서브카테고리, 거래 내역 추가
        try await database.withModelContext { context in
            let paymentMethodModel = try context.fetch(FetchDescriptor<PaymentMethod>()).first!
            
            let categoryDTO = TestDataFactory.createCategory(name: "식비", type: .variableExpense)
            let categoryModel = categoryDTO.toModel()
            context.insert(categoryModel)
            
            let subCategoryDTO = TestDataFactory.createSubCategory(name: "외식비", categoryId: categoryModel.id)
            let subCategoryModel = subCategoryDTO.toModel(parentCategory: categoryModel)
            context.insert(subCategoryModel)
            
            let transactionDTO = TestDataFactory.createTransaction(
                amount: 10000,
                memo: "점심식사",
                subCategory: subCategoryDTO,
                paymentMethod: paymentMethod
            )
            let transactionModel = transactionDTO.toModel(subCategory: subCategoryModel, paymentMethod: paymentMethodModel)
            context.insert(transactionModel)
            try context.save()
        }
        
        // When: 거래 내역 존재 여부 확인
        let hasTransactions = try await repository.hasTransactions(paymentMethodId: paymentMethod.id)
        
        // Then: 거래 내역 존재
        XCTAssertTrue(hasTransactions)
    }
    
    func testHasTransactions_WithoutTransactions() async throws {
        // Given: 결제수단만 생성 (거래 없음)
        let paymentMethod = TestDataFactory.createPaymentMethod(name: "신용카드", kind: .credit)
        try await repository.insertPaymentMethod(paymentMethod)
        
        // When: 거래 내역 존재 여부 확인
        let hasTransactions = try await repository.hasTransactions(paymentMethodId: paymentMethod.id)
        
        // Then: 거래 내역 없음
        XCTAssertFalse(hasTransactions)
    }
    
    // MARK: - 통계 테스트 (Statistics)
    
    func testFetchPaymentMethodUsageStats() async throws {
        // Given: 결제수단들과 거래 내역 생성
        let paymentMethod1 = TestDataFactory.createPaymentMethod(name: "신용카드", kind: .credit)
        let paymentMethod2 = TestDataFactory.createPaymentMethod(name: "체크카드", kind: .debit)
        let paymentMethod3 = TestDataFactory.createPaymentMethod(name: "현금", kind: .cash)
        
        try await repository.insertPaymentMethod(paymentMethod1)
        try await repository.insertPaymentMethod(paymentMethod2)
        try await repository.insertPaymentMethod(paymentMethod3)
        
        // 데이터베이스에 직접 거래 내역 추가
        try await database.withModelContext { context in
            let paymentMethods = try context.fetch(FetchDescriptor<PaymentMethod>())
            let paymentMethod1Model = paymentMethods.first { $0.name == "신용카드" }!
            let paymentMethod2Model = paymentMethods.first { $0.name == "체크카드" }!
            let paymentMethod3Model = paymentMethods.first { $0.name == "현금" }!
            
            let categoryDTO = TestDataFactory.createCategory(name: "식비", type: .variableExpense)
            let categoryModel = categoryDTO.toModel()
            context.insert(categoryModel)
            
            let subCategoryDTO = TestDataFactory.createSubCategory(name: "외식비", categoryId: categoryModel.id)
            let subCategoryModel = subCategoryDTO.toModel(parentCategory: categoryModel)
            context.insert(subCategoryModel)
            
            // 신용카드: 3회 거래
            for _ in 0..<3 {
                let transactionDTO = TestDataFactory.createTransaction(subCategory: subCategoryDTO, paymentMethod: paymentMethod1)
                let transactionModel = transactionDTO.toModel(subCategory: subCategoryModel, paymentMethod: paymentMethod1Model)
                context.insert(transactionModel)
            }
            
            // 체크카드: 1회 거래  
            let transactionDTO2 = TestDataFactory.createTransaction(subCategory: subCategoryDTO, paymentMethod: paymentMethod2)
            let transactionModel2 = transactionDTO2.toModel(subCategory: subCategoryModel, paymentMethod: paymentMethod2Model)
            context.insert(transactionModel2)
            
            // 현금: 거래 없음
            
            try context.save()
        }
        
        // When: 사용 통계 조회
        let usageStats = try await repository.fetchPaymentMethodUsageStats(limit: 10)
        
        // Then: 사용 횟수 순으로 정렬되어 반환
        XCTAssertEqual(usageStats.count, 3)
        XCTAssertEqual(usageStats[0].paymentMethod.name, "신용카드")
        XCTAssertEqual(usageStats[0].usageCount, 3)
        XCTAssertEqual(usageStats[1].paymentMethod.name, "체크카드")
        XCTAssertEqual(usageStats[1].usageCount, 1)
        XCTAssertEqual(usageStats[2].paymentMethod.name, "현금")
        XCTAssertEqual(usageStats[2].usageCount, 0)
    }
    
    func testFetchPaymentMethodAmountSummary() async throws {
        // Given: 결제수단들과 거래 내역 생성
        let paymentMethod1 = TestDataFactory.createPaymentMethod(name: "신용카드", kind: .credit)
        let paymentMethod2 = TestDataFactory.createPaymentMethod(name: "체크카드", kind: .debit)
        
        try await repository.insertPaymentMethod(paymentMethod1)
        try await repository.insertPaymentMethod(paymentMethod2)
        
        let startDate = TestDataFactory.startOfMonth()
        let endDate = TestDataFactory.endOfMonth()
        
        // 데이터베이스에 직접 거래 내역 추가
        try await database.withModelContext { context in
            let paymentMethods = try context.fetch(FetchDescriptor<PaymentMethod>())
            let paymentMethod1Model = paymentMethods.first { $0.name == "신용카드" }!
            let paymentMethod2Model = paymentMethods.first { $0.name == "체크카드" }!
            
            let categoryDTO = TestDataFactory.createCategory(name: "식비", type: .variableExpense)
            let categoryModel = categoryDTO.toModel()
            context.insert(categoryModel)
            
            let subCategoryDTO = TestDataFactory.createSubCategory(name: "외식비", categoryId: categoryModel.id)
            let subCategoryModel = subCategoryDTO.toModel(parentCategory: categoryModel)
            context.insert(subCategoryModel)
            
            // 신용카드: 50000원 (20000 + 30000)
            let transaction1 = TestDataFactory.createTransaction(amount: 20000, date: startDate, subCategory: subCategoryDTO, paymentMethod: paymentMethod1)
            let transactionModel1 = transaction1.toModel(subCategory: subCategoryModel, paymentMethod: paymentMethod1Model)
            context.insert(transactionModel1)
            
            let transaction2 = TestDataFactory.createTransaction(amount: 30000, date: endDate, subCategory: subCategoryDTO, paymentMethod: paymentMethod1)
            let transactionModel2 = transaction2.toModel(subCategory: subCategoryModel, paymentMethod: paymentMethod1Model)
            context.insert(transactionModel2)
            
            // 체크카드: 15000원
            let transaction3 = TestDataFactory.createTransaction(amount: 15000, date: startDate, subCategory: subCategoryDTO, paymentMethod: paymentMethod2)
            let transactionModel3 = transaction3.toModel(subCategory: subCategoryModel, paymentMethod: paymentMethod2Model)
            context.insert(transactionModel3)
            
            try context.save()
        }
        
        // When: 금액 집계 조회
        let amountSummary = try await repository.fetchPaymentMethodAmountSummary(startDate: startDate, endDate: endDate)
        
        // Then: 금액 순으로 정렬되어 반환
        XCTAssertEqual(amountSummary.count, 2)
        XCTAssertEqual(amountSummary[0].paymentMethod.name, "신용카드")
        XCTAssertEqual(amountSummary[0].totalAmount, 50000)
        XCTAssertEqual(amountSummary[1].paymentMethod.name, "체크카드")
        XCTAssertEqual(amountSummary[1].totalAmount, 15000)
    }
}