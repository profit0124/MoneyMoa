//
//  TransactionEventPublisher.swift
//  MoneyMoa
//
//  Created by Claude on 8/19/25.
//

import Foundation
import Combine

// MARK: - TransactionEvent

/// 트랜잭션 변경 이벤트를 나타내는 구조체
public struct TransactionEvent {
    /// 이벤트 타입
    public let type: TransactionEventType
    /// 트랜잭션이 속한 연월
    public let yearMonth: YearMonth
    /// 트랜잭션 고유 식별자 (삭제 시 필요)
    public let transactionId: UUID?
    
    public init(type: TransactionEventType, yearMonth: YearMonth, transactionId: UUID? = nil) {
        self.type = type
        self.yearMonth = yearMonth
        self.transactionId = transactionId
    }
}

// MARK: - TransactionEventType

/// 트랜잭션 이벤트 타입
public enum TransactionEventType {
    /// 트랜잭션 생성
    case created
    /// 트랜잭션 업데이트
    case updated
    /// 트랜잭션 삭제
    case deleted
}

// MARK: - TransactionEventPublisher Protocol

/// 트랜잭션 변경 이벤트를 발행하고 구독할 수 있는 Publisher
public protocol TransactionEventPublisher {
    /// 트랜잭션 이벤트 스트림
    var transactionEvents: AnyPublisher<TransactionEvent, Never> { get }
    
    /// 트랜잭션 이벤트 발행
    /// - Parameter event: 발행할 이벤트
    func publish(_ event: TransactionEvent)
}

// MARK: - DefaultTransactionEventPublisher

/// TransactionEventPublisher의 기본 구현
public final class DefaultTransactionEventPublisher: TransactionEventPublisher {
    
    // MARK: - Properties
    
    /// 이벤트를 발행하는 Subject
    private let subject = PassthroughSubject<TransactionEvent, Never>()
    
    /// 싱글톤 인스턴스
    public static let shared = DefaultTransactionEventPublisher()
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - TransactionEventPublisher
    
    public var transactionEvents: AnyPublisher<TransactionEvent, Never> {
        subject.eraseToAnyPublisher()
    }
    
    public func publish(_ event: TransactionEvent) {
        subject.send(event)
    }
}
