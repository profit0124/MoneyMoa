//
//  DateAdditionalFormViewModel.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/19/25.
//

import Foundation
import Observation

/// 거래 날짜, 메모, 템플릿 생성 설정을 관리하는 ViewModel
///
/// 특징:
/// - 가장 단순한 폼으로 외부 의존성 없음
/// - 항상 유효한 상태 (필수 입력 없음)
/// - 템플릿 생성 토글 및 반복주기 선택 기능 제공
@Observable
final class DateAdditionalFormViewModel: Identifiable {
    
    // MARK: - Properties
    
    /// 고유 식별자
    let id = UUID()
    
    /// 거래 발생 날짜 및 시간 (기본: 현재 시간)
    var selectedDate: Date
    
    /// 거래 메모 (선택사항, 20자 이상 시 요약 표시)
    var memo: String

    /// 템플릿 생성을 위한 반복주기 설정 (nil이면 템플릿 생성하지 않음)
    var selectedRecurrencePeriod: RecurrencePeriod?

    // MARK: - Computed Properties

    /// 템플릿 생성 여부를 나타내는 Bool 값 (UI 바인딩용)
    var createAsTemplate: Bool {
        get { selectedRecurrencePeriod != nil }
        set {
            if newValue {
                selectedRecurrencePeriod = RecurrencePeriod.none  // 기본값: 반복 없음
            } else {
                selectedRecurrencePeriod = nil
            }
        }
    }


    /// 카드 요약 정보 생성
    /// - 날짜는 항상 표시
    /// - 메모는 20자 이상 시 "..." 처리
    /// - 템플릿 생성 시 반복주기 정보 추가
    var summary: String {
        var result: [String] = []
        result.append("📅 \(selectedDate.transactionListSectionHeader)")
        if !memo.isEmpty {
            let truncatedMemo = memo.count > 20
                ? String(memo.prefix(20)) + "..."
                : memo
            result.append("📝 \(truncatedMemo)")
        }

        if let recurrencePeriod = selectedRecurrencePeriod {
            result.append("🔄 \(recurrencePeriod.displayName)")
        }

        return result.isEmpty ? "정보 없음" : result.joined(separator: " • ")
    }

    init(selectedDate: Date = Date(),
         memo: String = "",
         selectedRecurrencePeriod: RecurrencePeriod? = nil) {
        self.selectedDate = selectedDate
        self.memo = memo
        self.selectedRecurrencePeriod = selectedRecurrencePeriod
    }
    
    // MARK: - Action Handling
    
    /// 사용자 액션 정의
    enum Action {
        case toggleTemplate  // 템플릿 생성 상태 토글
        case selectRecurrencePeriod(RecurrencePeriod)  // 반복주기 선택
    }

    func send(_ action: Action) {
        switch action {
        case .toggleTemplate:
            toggleTemplate()
        case .selectRecurrencePeriod(let period):
            selectedRecurrencePeriod = period
        }
    }

    // MARK: - Private Methods

    /// 템플릿 생성 상태를 토글
    private func toggleTemplate() {
        createAsTemplate.toggle()
    }
}
