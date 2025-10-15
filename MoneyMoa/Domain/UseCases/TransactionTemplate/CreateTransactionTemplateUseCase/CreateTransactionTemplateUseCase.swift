//
//  CreateTransactionTemplateUseCase.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/24/25.
//

import Foundation

// MARK: - Use Case Protocol

public protocol CreateTransactionTemplateUseCase {
    /// 새로운 거래 템플릿을 생성합니다
    /// - Parameter template: 생성할 템플릿 정보
    /// - Throws: 데이터 검증 실패, 저장 실패 등의 에러
    func execute(_ template: TransactionTemplateDTO) async throws
}
