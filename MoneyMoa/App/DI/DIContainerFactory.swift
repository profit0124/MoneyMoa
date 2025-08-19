//
//  DIContainerFactory.swift
//  MoneyMoa
//
//  Created by Claude on 8/5/25.
//

import Foundation
import SwiftData

// MARK: - DIContainerFactory

/// DI 컨테이너를 생성하는 팩토리 클래스
/// App Layer에서 환경에 맞는 적절한 DI 컨테이너를 제공합니다
final class DIContainerFactory {
    
    // MARK: - Container Type
    
    /// 컨테이너 타입
    enum ContainerType {
        case mock        // Mock 구현체 사용 (개발/테스트)
        case production  // Production 구현체 사용 (실제 앱)
    }
    
    // MARK: - Factory Methods
    
    /// 지정된 타입의 DI 컨테이너를 생성합니다
    /// - Parameters:
    ///   - type: 컨테이너 타입
    ///   - database: Production 타입일 때 필요한 Database 인스턴스
    /// - Returns: DI 컨테이너 인스턴스
    static func create(type: ContainerType, database: Database? = nil) -> DIContainer {
        switch type {
        case .mock:
            return MockDIContainer()
        case .production:
            guard let database = database else {
                fatalError("Production DI Container requires Database instance")
            }
            return AppDIContainer(database: database)
        }
    }
    
    /// 현재 빌드 환경에 맞는 기본 컨테이너를 생성합니다
    /// DEBUG 빌드에서는 Mock, RELEASE 빌드에서는 Production을 사용합니다
    /// - Parameter database: Production 환경에서 필요한 Database 인스턴스
    /// - Returns: DI 컨테이너 인스턴스
    static func createDefault(database: Database? = nil) -> DIContainer {
        let containerType: ContainerType
        #if DEBUG
        containerType = .production
        #else
        containerType = .production
        #endif
        return create(type: containerType, database: database)
    }
    
    /// Preview 전용 Mock 컨테이너를 생성합니다
    /// SwiftUI Preview에서 사용하기 위한 Mock 컨테이너입니다
    /// - Returns: Mock DI 컨테이너 인스턴스
    static func createForPreview() -> DIContainer {
        return create(type: .mock)
    }
}
