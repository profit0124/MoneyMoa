//
//  DeleteTransactionTemplateUseCase.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/18/25.
//

import Foundation

public protocol DeleteTransactionTemplateUseCase {
    /// 거래 템플릿을 삭제합니다
    /// - Parameter templateId: 삭제할 템플릿 ID
    /// - Note: 템플릿 삭제 시 연결된 거래는 유지됨
    /// - Throws: 존재하지 않는 템플릿, 삭제 실패 등의 에러
    func execute(templateId: UUID) async throws
}
