//
//  TransactionTemplateEventPublisher.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 10/15/25.
//

import Foundation
import Combine

// MARK: - TransactionTemplateEvent

/// 트랜잭션 템플릿 변경 이벤트를 나타내는 구조체
public struct TransactionTemplateEvent {
    /// 이벤트 타입
    public let type: TransactionTemplateEventType

    public let template: TransactionTemplateDTO

    public init(type: TransactionTemplateEventType, template: TransactionTemplateDTO) {
        self.type = type
        self.template = template
    }
}

// MARK: - TransactionTemplateEventType

/// 트랜잭션 템플릿 이벤트 타입
public enum TransactionTemplateEventType {
    /// 트랜잭션 템플릿 생성
    case created
    /// 트랜잭션 템플릿 업데이트
    case updated
    /// 트랜잭션 템플릿 삭제
    case deleted
}

// MARK: - TransactionTemplateEventPublisher Protocol

/// 트랜잭션 템플릿 변경 이벤트를 발행하고 구독할 수 있는 Publisher
public protocol TransactionTemplateEventPublisher {

    /// 트랜잭션 템플릿 이벤트 스트림
    var transactionTemplateEvents: AnyPublisher<TransactionTemplateEvent, Never> { get }

    /// 트랜잭션 템플릿 이벤트 발행
    /// - Parameter event: 발행할 이벤트
    func publish(_ event: TransactionTemplateEvent)
}

// MARK: - DefaultTransactionTemplateEventPublisher

/// TransactionTemplateEventPublisher의 기본 구현
public final class DefaultTransactionTemplateEventPublisher: TransactionTemplateEventPublisher {
    // MARK: - Properties

    /// 이벤트를 발행하는 Subject
    private let subject = PassthroughSubject<TransactionTemplateEvent, Never>()

    /// 싱글톤 인스턴스
    public static let shared = DefaultTransactionTemplateEventPublisher()

    // MARK: - Initialization

    private init() {}

    // MARK: - TransactionTemplateEventPublisher

    public var transactionTemplateEvents: AnyPublisher<TransactionTemplateEvent, Never> {
        subject.eraseToAnyPublisher()
    }

    public func publish(_ event: TransactionTemplateEvent) {
        subject.send(event)
    }
}
