import Foundation
import Combine
@testable import MoneyMoa

final class TestTransactionTemplateEventPublisher: TransactionTemplateEventPublisher {
    private let subject = PassthroughSubject<TransactionTemplateEvent, Never>()
    private(set) var publishedEvents: [TransactionTemplateEvent] = []

    var transactionTemplateEvents: AnyPublisher<TransactionTemplateEvent, Never> {
        subject.eraseToAnyPublisher()
    }

    func publish(_ event: TransactionTemplateEvent) {
        publishedEvents.append(event)
        subject.send(event)
    }
}
