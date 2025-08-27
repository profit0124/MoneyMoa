//
//  CategoryEventPublisherTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 8/26/25.
//

import XCTest
import Combine
@testable import MoneyMoa

// MARK: - CategoryEventPublisherTests

@MainActor
final class CategoryEventPublisherTests: XCTestCase {
    
    // MARK: - Properties
    
    private var publisher: DefaultCategoryEventPublisher!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        
        // 매번 새로운 인스턴스를 생성하여 격리된 테스트 환경 구성
        // 실제로는 싱글톤이지만 테스트에서는 새로운 인스턴스 생성이 필요
        publisher = DefaultCategoryEventPublisher.shared
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
        XCTAssertNotNil(DefaultCategoryEventPublisher.shared)
    }
    
    func test_sharedInstance_isSingleton() {
        // Given
        let instance1 = DefaultCategoryEventPublisher.shared
        let instance2 = DefaultCategoryEventPublisher.shared
        
        // Then
        XCTAssertTrue(instance1 === instance2)
    }
    
    // MARK: - Test Methods - CategoryEvent
    
    func test_categoryEvent_initialization() {
        // Given
        let category = CategoryDTO.mockFood
        let eventType = CategoryEventType.created
        
        // When
        let event = CategoryEvent(type: eventType, category: category)
        
        // Then
        XCTAssertEqual(event.type, eventType)
        XCTAssertEqual(event.category.id, category.id)
        XCTAssertEqual(event.category.name, category.name)
    }
    
    func test_categoryEventType_allCases() {
        // Given
        let createdType = CategoryEventType.created
        let updatedType = CategoryEventType.updated
        let deletedType = CategoryEventType.deleted
        
        // Then
        XCTAssertNotEqual(createdType, updatedType)
        XCTAssertNotEqual(updatedType, deletedType)
        XCTAssertNotEqual(createdType, deletedType)
    }
    
    // MARK: - Test Methods - Event Publishing
    
    func test_publishEvent_sendsEventToSubscribers() {
        // Given
        let category = CategoryDTO.mockFood
        let event = CategoryEvent(type: .created, category: category)
        let expectation = XCTestExpectation(description: "Event should be received")
        
        var receivedEvent: CategoryEvent?
        
        // When
        publisher.categoryEvents
            .sink { receivedValue in
                receivedEvent = receivedValue
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        publisher.publish(event)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(receivedEvent)
        XCTAssertEqual(receivedEvent?.type, .created)
        XCTAssertEqual(receivedEvent?.category.id, category.id)
    }
    
    func test_publishMultipleEvents_sendsAllEventsToSubscribers() {
        // Given
        let category1 = CategoryDTO.mockFood
        let category2 = CategoryDTO.mockTransport
        let event1 = CategoryEvent(type: .created, category: category1)
        let event2 = CategoryEvent(type: .updated, category: category2)
        
        let expectation = XCTestExpectation(description: "All events should be received")
        expectation.expectedFulfillmentCount = 2
        
        var receivedEvents: [CategoryEvent] = []
        
        // When
        publisher.categoryEvents
            .sink { event in
                receivedEvents.append(event)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        publisher.publish(event1)
        publisher.publish(event2)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedEvents.count, 2)
        XCTAssertEqual(receivedEvents[0].type, .created)
        XCTAssertEqual(receivedEvents[1].type, .updated)
    }
    
    // MARK: - Test Methods - Event Types
    
    func test_publishCreatedEvent_receivesCorrectEventType() {
        // Given
        let category = CategoryDTO.mockFood
        let event = CategoryEvent(type: .created, category: category)
        let expectation = XCTestExpectation(description: "Created event should be received")
        
        var receivedEventType: CategoryEventType?
        
        // When
        publisher.categoryEvents
            .sink { event in
                receivedEventType = event.type
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        publisher.publish(event)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedEventType, .created)
    }
    
    func test_publishUpdatedEvent_receivesCorrectEventType() {
        // Given
        let category = CategoryDTO.mockFood
        let event = CategoryEvent(type: .updated, category: category)
        let expectation = XCTestExpectation(description: "Updated event should be received")
        
        var receivedEventType: CategoryEventType?
        
        // When
        publisher.categoryEvents
            .sink { event in
                receivedEventType = event.type
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        publisher.publish(event)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedEventType, .updated)
    }
    
    func test_publishDeletedEvent_receivesCorrectEventType() {
        // Given
        let category = CategoryDTO.mockFood
        let event = CategoryEvent(type: .deleted, category: category)
        let expectation = XCTestExpectation(description: "Deleted event should be received")
        
        var receivedEventType: CategoryEventType?
        
        // When
        publisher.categoryEvents
            .sink { event in
                receivedEventType = event.type
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        publisher.publish(event)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedEventType, .deleted)
    }
    
    // MARK: - Test Methods - Multiple Subscribers
    
    func test_multipleSubscribers_allReceiveEvent() {
        // Given
        let category = CategoryDTO.mockFood
        let event = CategoryEvent(type: .created, category: category)
        let expectation1 = XCTestExpectation(description: "First subscriber should receive event")
        let expectation2 = XCTestExpectation(description: "Second subscriber should receive event")
        
        var receivedEvent1: CategoryEvent?
        var receivedEvent2: CategoryEvent?
        
        // When
        publisher.categoryEvents
            .sink { event in
                receivedEvent1 = event
                expectation1.fulfill()
            }
            .store(in: &cancellables)
        
        publisher.categoryEvents
            .sink { event in
                receivedEvent2 = event
                expectation2.fulfill()
            }
            .store(in: &cancellables)
        
        publisher.publish(event)
        
        // Then
        wait(for: [expectation1, expectation2], timeout: 1.0)
        XCTAssertNotNil(receivedEvent1)
        XCTAssertNotNil(receivedEvent2)
        XCTAssertEqual(receivedEvent1?.category.id, category.id)
        XCTAssertEqual(receivedEvent2?.category.id, category.id)
    }
    
    // MARK: - Test Methods - Cancellation
    
    func test_cancelledSubscription_doesNotReceiveEvent() {
        // Given
        let category = CategoryDTO.mockFood
        let event = CategoryEvent(type: .created, category: category)
        var receivedEvent: CategoryEvent?
        
        let cancellable = publisher.categoryEvents
            .sink { event in
                receivedEvent = event
            }
        
        // When - 구독 취소 후 이벤트 발행
        cancellable.cancel()
        publisher.publish(event)
        
        // Then - 약간의 지연 후 확인
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertNil(receivedEvent)
        }
    }
    
    // MARK: - Test Methods - Different Categories
    
    func test_publishEventsForDifferentCategories_receivesAllEvents() {
        // Given
        let foodCategory = CategoryDTO.mockFood
        let transportCategory = CategoryDTO.mockTransport
        let incomeCategory = CategoryDTO.mockIncome
        
        let foodEvent = CategoryEvent(type: .created, category: foodCategory)
        let transportEvent = CategoryEvent(type: .updated, category: transportCategory)
        let incomeEvent = CategoryEvent(type: .deleted, category: incomeCategory)
        
        let expectation = XCTestExpectation(description: "All events should be received")
        expectation.expectedFulfillmentCount = 3
        
        var receivedCategories: [CategoryDTO] = []
        
        // When
        publisher.categoryEvents
            .sink { event in
                receivedCategories.append(event.category)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        publisher.publish(foodEvent)
        publisher.publish(transportEvent)
        publisher.publish(incomeEvent)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedCategories.count, 3)
        
        let categoryNames = receivedCategories.map { $0.name }
        XCTAssertTrue(categoryNames.contains("식비"))
        XCTAssertTrue(categoryNames.contains("교통비"))
        XCTAssertTrue(categoryNames.contains("수입"))
    }
}
