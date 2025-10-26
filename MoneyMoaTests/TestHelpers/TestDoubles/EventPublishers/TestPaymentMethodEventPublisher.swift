import Foundation
import Combine
@testable import MoneyMoa

final class TestPaymentMethodEventPublisher: PaymentMethodEventPublisher {
    private let subject = PassthroughSubject<PaymentMethodEvent, Never>()
    private(set) var publishedEvents: [PaymentMethodEvent] = []

    var paymentMethodEvents: AnyPublisher<PaymentMethodEvent, Never> {
        subject.eraseToAnyPublisher()
    }

    func publish(_ event: PaymentMethodEvent) {
        publishedEvents.append(event)
        subject.send(event)
    }
}
