//
//  PaymentMethodEventPublisher.swift
//  MoneyMoa
//
//  Created by Claude on 10/26/25.
//

import Foundation
import Combine

// MARK: - PaymentMethodEvent

/// 결제수단 변경 이벤트를 나타내는 구조체
public struct PaymentMethodEvent {
    /// 이벤트 타입
    public let type: PaymentMethodEventType

    public let paymentMethod: PaymentMethodDTO

    public init(type: PaymentMethodEventType, paymentMethod: PaymentMethodDTO) {
        self.type = type
        self.paymentMethod = paymentMethod
    }
}

// MARK: - PaymentMethodEventType

/// 결제수단 이벤트 타입
public enum PaymentMethodEventType {
    /// 결제수단 생성
    case created
    /// 결제수단 업데이트
    case updated
    /// 결제수단 삭제
    case deleted
}

// MARK: - PaymentMethodEventPublisher Protocol

/// 결제수단 변경 이벤트를 발행하고 구독할 수 있는 Publisher
public protocol PaymentMethodEventPublisher {

    /// 결제수단 이벤트 스트림
    var paymentMethodEvents: AnyPublisher<PaymentMethodEvent, Never> { get }

    /// 결제수단 이벤트 발행
    /// - Parameter event: 발행할 이벤트
    func publish(_ event: PaymentMethodEvent)
}

// MARK: - DefaultPaymentMethodEventPublisher

/// PaymentMethodEventPublisher의 기본 구현
public final class DefaultPaymentMethodEventPublisher: PaymentMethodEventPublisher {
    // MARK: - Properties

    /// 이벤트를 발행하는 Subject
    private let subject = PassthroughSubject<PaymentMethodEvent, Never>()

    /// 싱글톤 인스턴스
    public static let shared = DefaultPaymentMethodEventPublisher()

    // MARK: - Initialization

    private init() {}

    // MARK: - PaymentMethodEventPublisher

    public var paymentMethodEvents: AnyPublisher<PaymentMethodEvent, Never> {
        subject.eraseToAnyPublisher()
    }

    public func publish(_ event: PaymentMethodEvent) {
        subject.send(event)
    }
}
