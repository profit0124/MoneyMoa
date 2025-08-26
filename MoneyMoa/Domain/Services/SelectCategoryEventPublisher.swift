//
//  SelectCategoryEventPublisher.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/25/25.
//

import Foundation
import Combine

// MARK: - SelectCategoryEventPublisher Protocol

/// 카테고리 선택 이벤트를 발행하고 구독할 수 있는 Publisher
public protocol SelectCategoryEventPublisher {
    /// 카테고리 선택 이벤트 스트림
    var selectCategoryEvent: AnyPublisher<CategoryDTO, Never> { get }

    /// 카테고리 선택 이벤트 발행
    /// - Parameter event: 발행할 이벤트
    func publish(_ event: CategoryDTO)
}

// MARK: - DefaultTransactionEventPublisher

/// TransactionEventPublisher의 기본 구현
public final class DefaultSelectCategoryEventPublisher: SelectCategoryEventPublisher {

    // MARK: - Properties

    /// 이벤트를 발행하는 Subject
    private let subject = PassthroughSubject<CategoryDTO, Never>()

    /// 싱글톤 인스턴스
    public static let shared = DefaultSelectCategoryEventPublisher()

    // MARK: - Initialization

    private init() {}

    // MARK: - SelectCategoryEvent

    public var selectCategoryEvent: AnyPublisher<CategoryDTO, Never> {
        subject.eraseToAnyPublisher()
    }

    public func publish(_ event: CategoryDTO) {
        subject.send(event)
    }
}
