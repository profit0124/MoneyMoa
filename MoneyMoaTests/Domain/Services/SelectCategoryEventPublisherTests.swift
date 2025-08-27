//
//  SelectCategoryEventPublisherTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 8/27/25.
//

import XCTest
import Combine
@testable import MoneyMoa

// MARK: - SelectCategoryEventPublisherTests

@MainActor
final class SelectCategoryEventPublisherTests: XCTestCase {
    
    // MARK: - Properties
    
    private var publisher: DefaultSelectCategoryEventPublisher!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        
        // 싱글톤을 사용하지만 각 테스트는 독립적으로 실행
        publisher = DefaultSelectCategoryEventPublisher.shared
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables.removeAll()
        publisher = nil
        super.tearDown()
    }
    
    // MARK: - Test Methods - Initialization
    
    func test_sharedInstance_isNotNil() {
        // Then
        XCTAssertNotNil(DefaultSelectCategoryEventPublisher.shared)
    }
    
    func test_sharedInstance_isSingleton() {
        // Given
        let instance1 = DefaultSelectCategoryEventPublisher.shared
        let instance2 = DefaultSelectCategoryEventPublisher.shared
        
        // Then
        XCTAssertTrue(instance1 === instance2)
    }
    
    // MARK: - Test Methods - Event Publishing
    
    func test_publishEvent_sendsEventToSubscribers() {
        // Given
        let category = CategoryDTO.mockFood
        let expectation = XCTestExpectation(description: "Category event should be received")
        
        var receivedCategory: CategoryDTO?
        
        // When
        publisher.selectCategoryEvent
            .sink { receivedValue in
                receivedCategory = receivedValue
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        publisher.publish(category)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(receivedCategory)
        XCTAssertEqual(receivedCategory?.id, category.id)
        XCTAssertEqual(receivedCategory?.name, category.name)
        XCTAssertEqual(receivedCategory?.transactionType, category.transactionType)
    }
    
    func test_publishMultipleEvents_sendsAllEventsToSubscribers() {
        // Given
        let category1 = CategoryDTO.mockFood
        let category2 = CategoryDTO.mockTransport
        let category3 = CategoryDTO.mockIncome
        
        let expectation = XCTestExpectation(description: "All category events should be received")
        expectation.expectedFulfillmentCount = 3
        
        var receivedCategories: [CategoryDTO] = []
        
        // When
        publisher.selectCategoryEvent
            .sink { category in
                receivedCategories.append(category)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        publisher.publish(category1)
        publisher.publish(category2)
        publisher.publish(category3)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedCategories.count, 3)
        XCTAssertEqual(receivedCategories[0].id, category1.id)
        XCTAssertEqual(receivedCategories[1].id, category2.id)
        XCTAssertEqual(receivedCategories[2].id, category3.id)
    }
    
    // MARK: - Test Methods - Different Category Types
    
    func test_publishIncomeCategory_receivesCorrectCategory() {
        // Given
        let incomeCategory = CategoryDTO.mockIncome
        let expectation = XCTestExpectation(description: "Income category should be received")
        
        var receivedCategory: CategoryDTO?
        
        // When
        publisher.selectCategoryEvent
            .sink { category in
                receivedCategory = category
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        publisher.publish(incomeCategory)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedCategory?.transactionType, .income)
        XCTAssertEqual(receivedCategory?.name, "수입")
    }
    
    func test_publishVariableExpenseCategory_receivesCorrectCategory() {
        // Given
        let variableExpenseCategory = CategoryDTO.mockFood
        let expectation = XCTestExpectation(description: "Variable expense category should be received")
        
        var receivedCategory: CategoryDTO?
        
        // When
        publisher.selectCategoryEvent
            .sink { category in
                receivedCategory = category
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        publisher.publish(variableExpenseCategory)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedCategory?.transactionType, .variableExpense)
        XCTAssertEqual(receivedCategory?.name, "식비")
    }
    
    func test_publishFixedExpenseCategory_receivesCorrectCategory() {
        // Given
        let fixedExpenseCategory = CategoryDTO.mockRent
        let expectation = XCTestExpectation(description: "Fixed expense category should be received")
        
        var receivedCategory: CategoryDTO?
        
        // When
        publisher.selectCategoryEvent
            .sink { category in
                receivedCategory = category
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        publisher.publish(fixedExpenseCategory)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedCategory?.transactionType, .fixedExpense)
        XCTAssertEqual(receivedCategory?.name, "월세")
    }
    
    // MARK: - Test Methods - Multiple Subscribers
    
    func test_multipleSubscribers_allReceiveEvent() {
        // Given
        let category = CategoryDTO.mockTransport
        let expectation1 = XCTestExpectation(description: "First subscriber should receive event")
        let expectation2 = XCTestExpectation(description: "Second subscriber should receive event")
        
        var receivedCategory1: CategoryDTO?
        var receivedCategory2: CategoryDTO?
        
        // When
        publisher.selectCategoryEvent
            .sink { category in
                receivedCategory1 = category
                expectation1.fulfill()
            }
            .store(in: &cancellables)
        
        publisher.selectCategoryEvent
            .sink { category in
                receivedCategory2 = category
                expectation2.fulfill()
            }
            .store(in: &cancellables)
        
        publisher.publish(category)
        
        // Then
        wait(for: [expectation1, expectation2], timeout: 1.0)
        XCTAssertNotNil(receivedCategory1)
        XCTAssertNotNil(receivedCategory2)
        XCTAssertEqual(receivedCategory1?.id, category.id)
        XCTAssertEqual(receivedCategory2?.id, category.id)
        XCTAssertEqual(receivedCategory1?.name, "교통비")
        XCTAssertEqual(receivedCategory2?.name, "교통비")
    }
    
    // MARK: - Test Methods - Cancellation
    
    func test_cancelledSubscription_doesNotReceiveEvent() {
        // Given
        let category = CategoryDTO.mockFood
        var receivedCategory: CategoryDTO?
        
        let cancellable = publisher.selectCategoryEvent
            .sink { category in
                receivedCategory = category
            }
        
        // When - 구독 취소 후 이벤트 발행
        cancellable.cancel()
        publisher.publish(category)
        
        // Then - 약간의 지연 후 확인
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertNil(receivedCategory)
        }
    }
    
    // MARK: - Test Methods - Category Properties
    
    func test_publishedCategory_preservesAllProperties() {
        // Given
        let originalCategory = CategoryDTO(
            name: "테스트 카테고리",
            iconName: "test.icon",
            transactionType: .variableExpense,
            isActive: true,
            orderIndex: 5,
            subCategories: [SubCategoryDTO.mockFoodExpense]
        )
        
        let expectation = XCTestExpectation(description: "Category with all properties should be received")
        
        var receivedCategory: CategoryDTO?
        
        // When
        publisher.selectCategoryEvent
            .sink { category in
                receivedCategory = category
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        publisher.publish(originalCategory)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedCategory?.id, originalCategory.id)
        XCTAssertEqual(receivedCategory?.name, "테스트 카테고리")
        XCTAssertEqual(receivedCategory?.iconName, "test.icon")
        XCTAssertEqual(receivedCategory?.transactionType, .variableExpense)
        XCTAssertEqual(receivedCategory?.isActive, true)
        XCTAssertEqual(receivedCategory?.orderIndex, 5)
        XCTAssertEqual(receivedCategory?.subCategories.count, 1)
        XCTAssertEqual(receivedCategory?.subCategories.first?.id, SubCategoryDTO.mockFoodExpense.id)
    }
    
    // MARK: - Test Methods - Sequential Events
    
    func test_publishSequentialEvents_receivesInCorrectOrder() {
        // Given
        let categories = [CategoryDTO.mockFood, CategoryDTO.mockTransport, CategoryDTO.mockIncome]
        let expectation = XCTestExpectation(description: "Sequential events should be received in order")
        expectation.expectedFulfillmentCount = 3
        
        var receivedCategories: [CategoryDTO] = []
        
        // When
        publisher.selectCategoryEvent
            .sink { category in
                receivedCategories.append(category)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Publish events sequentially
        for category in categories {
            publisher.publish(category)
        }
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedCategories.count, 3)
        XCTAssertEqual(receivedCategories[0].name, "식비")
        XCTAssertEqual(receivedCategories[1].name, "교통비")
        XCTAssertEqual(receivedCategories[2].name, "수입")
    }
    
    // MARK: - Test Methods - Same Category Multiple Times
    
    func test_publishSameCategoryMultipleTimes_receivesAllEvents() {
        // Given
        let category = CategoryDTO.mockFood
        let expectation = XCTestExpectation(description: "Same category published multiple times should be received")
        expectation.expectedFulfillmentCount = 3
        
        var receiveCount = 0
        
        // When
        publisher.selectCategoryEvent
            .sink { receivedCategory in
                XCTAssertEqual(receivedCategory.id, category.id)
                receiveCount += 1
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        publisher.publish(category)
        publisher.publish(category)
        publisher.publish(category)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receiveCount, 3)
    }
}
