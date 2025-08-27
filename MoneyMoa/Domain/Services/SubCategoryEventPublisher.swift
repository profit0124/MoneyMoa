//
//  SubCategoryEventPublisher.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/26/25.
//

import Foundation
import Combine

// MARK: - TransactionEvent

/// 서브카테고리 변경 이벤트를 나타내는 구조체
public struct SubCategoryEvent {
    /// 이벤트 타입
    public let type: SubCategoryEventType

    public let subCategory: SubCategoryDTO

    public init(type: SubCategoryEventType, subCategory: SubCategoryDTO) {
        self.type = type
        self.subCategory = subCategory
    }
}

// MARK: - SubCategoryEventType

/// 서브카테고리 이벤트 타입
public enum SubCategoryEventType {
    /// 서브카테고리 생성
    case created
    /// 서브카테고리 업데이트
    case updated
    /// 서브카테고리 삭제
    case deleted
}

// MARK: - SubCategoryEventPublisher Protocol

/// 트랜잭션 변경 이벤트를 발행하고 구독할 수 있는 Publisher
public protocol SubCategoryEventPublisher {

    /// 트랜잭션 이벤트 스트림
    var subCategoryEvents: AnyPublisher<SubCategoryEvent, Never> { get }

    /// 트랜잭션 이벤트 발행
    /// - Parameter event: 발행할 이벤트
    func publish(_ event: SubCategoryEvent)
}

// MARK: - DefaultTransactionEventPublisher

/// TransactionEventPublisher의 기본 구현
public final class DefaultSubCategoryEventPublisher: SubCategoryEventPublisher {
    // MARK: - Properties

    /// 이벤트를 발행하는 Subject
    private let subject = PassthroughSubject<SubCategoryEvent, Never>()

    /// 싱글톤 인스턴스
    public static let shared = DefaultSubCategoryEventPublisher()

    // MARK: - Initialization

    private init() {}

    // MARK: - TransactionEventPublisher

    public var subCategoryEvents: AnyPublisher<SubCategoryEvent, Never> {
        subject.eraseToAnyPublisher()
    }

    public func publish(_ event: SubCategoryEvent) {
        subject.send(event)
    }
}
