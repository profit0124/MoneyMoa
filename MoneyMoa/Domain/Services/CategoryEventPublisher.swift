//
//  CategoryEventPublisher.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/26/25.
//

import Foundation
import Combine

// MARK: - CategoryEvent

/// 카테고리 변경 이벤트를 나타내는 구조체
public struct CategoryEvent {
    /// 이벤트 타입
    public let type: CategoryEventType

    public let category: CategoryDTO

    public init(type: CategoryEventType, category: CategoryDTO) {
        self.type = type
        self.category = category
    }
}

// MARK: - CategoryEventType

/// 카테고리 이벤트 타입
public enum CategoryEventType {
    /// 카테고리 생성
    case created
    /// 카테고리 업데이트
    case updated
    /// 카테고리 삭제
    case deleted
}

// MARK: - CategoryEventPublisher Protocol

/// 카테고리 변경 이벤트를 발행하고 구독할 수 있는 Publisher
public protocol CategoryEventPublisher {

    /// 카테고리 이벤트 스트림
    var categoryEvents: AnyPublisher<CategoryEvent, Never> { get }

    /// 카테고리 이벤트 발행
    /// - Parameter event: 발행할 이벤트
    func publish(_ event: CategoryEvent)
}

// MARK: - DefaultCategoryEventPublisher

/// CategoryEventPublisher의 기본 구현
public final class DefaultCategoryEventPublisher: CategoryEventPublisher {
    // MARK: - Properties

    /// 이벤트를 발행하는 Subject
    private let subject = PassthroughSubject<CategoryEvent, Never>()

    /// 싱글톤 인스턴스
    public static let shared = DefaultCategoryEventPublisher()

    // MARK: - Initialization

    private init() {}

    // MARK: - CategoryEventPublisher

    public var categoryEvents: AnyPublisher<CategoryEvent, Never> {
        subject.eraseToAnyPublisher()
    }

    public func publish(_ event: CategoryEvent) {
        subject.send(event)
    }
}
