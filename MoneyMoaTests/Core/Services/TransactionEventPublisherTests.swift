//
//  TransactionEventPublisherTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 8/19/25.
//

import XCTest
import Combine
@testable import MoneyMoa

// MARK: - TransactionEventPublisherTests

final class TransactionEventPublisherTests: XCTestCase {
    
    // MARK: - Properties
    
    private var publisher: DefaultTransactionEventPublisher!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        publisher = DefaultTransactionEventPublisher.shared
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables = nil
        publisher = nil
        super.tearDown()
    }
    
    // MARK: - Test Methods - Event Publishing
    
    func test_publish_createdEvent_deliversEventToSubscriber() {
        // Given
        let expectedYearMonth = YearMonth(year: 2024, month: 8)
        let expectedTransactionId = UUID()
        var receivedEvent: TransactionEvent?
        
        let expectation = expectation(description: "Event received")
        
        publisher.transactionEvents
            .sink { event in
                receivedEvent = event
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        let event = TransactionEvent(
            type: .created,
            yearMonth: expectedYearMonth,
            transactionId: expectedTransactionId
        )
        
        // When
        publisher.publish(event)
        
        // Then
        waitForExpectations(timeout: 1.0) { _ in
            XCTAssertNotNil(receivedEvent)
            XCTAssertEqual(receivedEvent?.type, .created)
            XCTAssertEqual(receivedEvent?.yearMonth, expectedYearMonth)
            XCTAssertEqual(receivedEvent?.transactionId, expectedTransactionId)
        }
    }
    
    func test_publish_updatedEvent_deliversEventToSubscriber() {
        // Given
        let expectedYearMonth = YearMonth.current
        let expectedTransactionId = UUID()
        var receivedEvent: TransactionEvent?
        
        let expectation = expectation(description: "Updated event received")
        
        publisher.transactionEvents
            .sink { event in
                receivedEvent = event
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        let event = TransactionEvent(
            type: .updated,
            yearMonth: expectedYearMonth,
            transactionId: expectedTransactionId
        )
        
        // When
        publisher.publish(event)
        
        // Then
        waitForExpectations(timeout: 1.0) { _ in
            XCTAssertNotNil(receivedEvent)
            XCTAssertEqual(receivedEvent?.type, .updated)
            XCTAssertEqual(receivedEvent?.yearMonth, expectedYearMonth)
            XCTAssertEqual(receivedEvent?.transactionId, expectedTransactionId)
        }
    }
    
    func test_publish_deletedEvent_deliversEventToSubscriber() {
        // Given
        let expectedYearMonth = YearMonth(year: 2023, month: 12)
        let expectedTransactionId = UUID()
        var receivedEvent: TransactionEvent?
        
        let expectation = expectation(description: "Deleted event received")
        
        publisher.transactionEvents
            .sink { event in
                receivedEvent = event
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        let event = TransactionEvent(
            type: .deleted,
            yearMonth: expectedYearMonth,
            transactionId: expectedTransactionId
        )
        
        // When
        publisher.publish(event)
        
        // Then
        waitForExpectations(timeout: 1.0) { _ in
            XCTAssertNotNil(receivedEvent)
            XCTAssertEqual(receivedEvent?.type, .deleted)
            XCTAssertEqual(receivedEvent?.yearMonth, expectedYearMonth)
            XCTAssertEqual(receivedEvent?.transactionId, expectedTransactionId)
        }
    }
    
    // MARK: - Test Methods - Multiple Subscribers
    
    func test_publish_withMultipleSubscribers_deliversEventToAllSubscribers() {
        // Given
        let expectedYearMonth = YearMonth.current
        var receivedEvents: [TransactionEvent] = []
        let expectation1 = expectation(description: "Subscriber 1 received event")
        let expectation2 = expectation(description: "Subscriber 2 received event")
        
        // Subscriber 1
        publisher.transactionEvents
            .sink { event in
                receivedEvents.append(event)
                expectation1.fulfill()
            }
            .store(in: &cancellables)
        
        // Subscriber 2
        publisher.transactionEvents
            .sink { event in
                receivedEvents.append(event)
                expectation2.fulfill()
            }
            .store(in: &cancellables)
        
        let event = TransactionEvent(
            type: .created,
            yearMonth: expectedYearMonth,
            transactionId: UUID()
        )
        
        // When
        publisher.publish(event)
        
        // Then
        waitForExpectations(timeout: 1.0) { _ in
            XCTAssertEqual(receivedEvents.count, 2)
            XCTAssertTrue(receivedEvents.allSatisfy { $0.type == .created })
            XCTAssertTrue(receivedEvents.allSatisfy { $0.yearMonth == expectedYearMonth })
        }
    }
    
    // MARK: - Test Methods - Multiple Events
    
    func test_publish_multipleEvents_deliversAllEventsInOrder() {
        // Given
        let yearMonth1 = YearMonth(year: 2024, month: 1)
        let yearMonth2 = YearMonth(year: 2024, month: 2)
        let yearMonth3 = YearMonth(year: 2024, month: 3)
        
        var receivedEvents: [TransactionEvent] = []
        let expectation = expectation(description: "All events received")
        expectation.expectedFulfillmentCount = 3
        
        publisher.transactionEvents
            .sink { event in
                receivedEvents.append(event)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        let events = [
            TransactionEvent(type: .created, yearMonth: yearMonth1, transactionId: UUID()),
            TransactionEvent(type: .updated, yearMonth: yearMonth2, transactionId: UUID()),
            TransactionEvent(type: .deleted, yearMonth: yearMonth3, transactionId: UUID())
        ]
        
        // When
        for event in events {
            publisher.publish(event)
        }
        
        // Then
        waitForExpectations(timeout: 1.0) { _ in
            XCTAssertEqual(receivedEvents.count, 3)
            XCTAssertEqual(receivedEvents[0].type, .created)
            XCTAssertEqual(receivedEvents[0].yearMonth, yearMonth1)
            XCTAssertEqual(receivedEvents[1].type, .updated)
            XCTAssertEqual(receivedEvents[1].yearMonth, yearMonth2)
            XCTAssertEqual(receivedEvents[2].type, .deleted)
            XCTAssertEqual(receivedEvents[2].yearMonth, yearMonth3)
        }
    }
    
    // MARK: - Test Methods - Filtering
    
    func test_transactionEvents_withFilter_deliversOnlyMatchingEvents() {
        // Given
        let targetYearMonth = YearMonth.current
        let otherYearMonth = YearMonth(year: 2023, month: 1)
        var receivedEvents: [TransactionEvent] = []
        
        let expectation = expectation(description: "Filtered events received")
        expectation.expectedFulfillmentCount = 2
        
        publisher.transactionEvents
            .filter { $0.yearMonth == targetYearMonth }
            .sink { event in
                receivedEvents.append(event)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        let events = [
            TransactionEvent(type: .created, yearMonth: targetYearMonth, transactionId: UUID()), // 포함됨
            TransactionEvent(type: .updated, yearMonth: otherYearMonth, transactionId: UUID()),  // 제외됨
            TransactionEvent(type: .deleted, yearMonth: targetYearMonth, transactionId: UUID())  // 포함됨
        ]
        
        // When
        for event in events {
            publisher.publish(event)
        }
        
        // Then
        waitForExpectations(timeout: 1.0) { _ in
            XCTAssertEqual(receivedEvents.count, 2)
            XCTAssertTrue(receivedEvents.allSatisfy { $0.yearMonth == targetYearMonth })
            XCTAssertEqual(receivedEvents[0].type, .created)
            XCTAssertEqual(receivedEvents[1].type, .deleted)
        }
    }
    
    // MARK: - Test Methods - Singleton Behavior
    
    func test_shared_returnsConsistentInstance() {
        // Given & When
        let instance1 = DefaultTransactionEventPublisher.shared
        let instance2 = DefaultTransactionEventPublisher.shared
        
        // Then
        XCTAssertTrue(instance1 === instance2)
    }
    
    func test_shared_publishedEventIsReceivedByOtherSubscribers() {
        // Given
        let sharedPublisher = DefaultTransactionEventPublisher.shared
        var receivedEvent: TransactionEvent?
        
        let expectation = expectation(description: "Shared publisher event received")
        
        sharedPublisher.transactionEvents
            .sink { event in
                receivedEvent = event
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        let event = TransactionEvent(
            type: .created,
            yearMonth: YearMonth.current,
            transactionId: UUID()
        )
        
        // When
        sharedPublisher.publish(event)
        
        // Then
        waitForExpectations(timeout: 1.0) { _ in
            XCTAssertNotNil(receivedEvent)
            XCTAssertEqual(receivedEvent?.type, .created)
        }
    }
}

// MARK: - TransactionEventTests

final class TransactionEventTests: XCTestCase {
    
    // MARK: - Test Methods - Initialization
    
    func test_init_withAllParameters_setsCorrectValues() {
        // Given
        let type = TransactionEventType.created
        let yearMonth = YearMonth(year: 2024, month: 6)
        let transactionId = UUID()
        
        // When
        let event = TransactionEvent(
            type: type,
            yearMonth: yearMonth,
            transactionId: transactionId
        )
        
        // Then
        XCTAssertEqual(event.type, type)
        XCTAssertEqual(event.yearMonth, yearMonth)
        XCTAssertEqual(event.transactionId, transactionId)
    }
    
    func test_init_withoutTransactionId_setsNilTransactionId() {
        // Given
        let type = TransactionEventType.updated
        let yearMonth = YearMonth.current
        
        // When
        let event = TransactionEvent(type: type, yearMonth: yearMonth)
        
        // Then
        XCTAssertEqual(event.type, type)
        XCTAssertEqual(event.yearMonth, yearMonth)
        XCTAssertNil(event.transactionId)
    }
}

// MARK: - TransactionEventTypeTests

final class TransactionEventTypeTests: XCTestCase {
    
    // MARK: - Test Methods - All Cases
    
    func test_allCases_containsExpectedValues() {
        // Given
        let expectedCases: [TransactionEventType] = [.created, .updated, .deleted]
        
        // When & Then
        XCTAssertEqual(expectedCases.count, 3)
        // Test that all expected cases can be created
        XCTAssertNotNil(TransactionEventType.created)
        XCTAssertNotNil(TransactionEventType.updated)
        XCTAssertNotNil(TransactionEventType.deleted)
    }
}
