//
//  UpdateTransactionTemplateUseCase.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/24/25.
//

import Foundation

/// TransactionTemplate 업데이트를 위한 UseCase 프로토콜
public protocol UpdateTransactionTemplateUseCase {
    /// 기존 TransactionTemplate을 업데이트합니다
    /// - Parameter template: 업데이트할 TransactionTemplate 데이터
    func execute(_ template: TransactionTemplateDTO) async throws
}
