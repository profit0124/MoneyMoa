//
//  TransactionTemplateEventPublisherTests.swift
//  MoneyMoaTests
//
//  Created by Generated on 3/7/24.
//

import Testing
import Combine
@testable import MoneyMoa

struct TransactionTemplateEventPublisherTests {

    @Test("publish 호출 시 subject가 이벤트를 전달한다")
    func testPublishEmitsEvent() async throws {
        // Given
        let publisher = DefaultTransactionTemplateEventPublisher.shared
        var cancellables = Set<AnyCancellable>()
        var receivedEvent: TransactionTemplateEvent?

        let template = TestDataFactory.createTransactionTemplate(
            subCategory: .mockFoodExpense,
            paymentMethod: .mockCreditCard
        )
        let event = TransactionTemplateEvent(type: .created, template: template)

        publisher.transactionTemplateEvents
            .sink { received in
                receivedEvent = received
            }
            .store(in: &cancellables)

        // When
        publisher.publish(event)

        // Then
        let captured = try #require(receivedEvent)
        #expect(captured.type == .created)
        #expect(captured.template.id == template.id)
    }
}
