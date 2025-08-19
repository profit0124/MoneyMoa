//
//  DateAdditionalFormViewModel.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/19/25.
//

import Foundation
import Observation

/// 거래 날짜, 메모, 즐겨찾기 설정을 관리하는 ViewModel
/// 
/// 특징:
/// - 가장 단순한 폼으로 외부 의존성 없음
/// - 항상 유효한 상태 (필수 입력 없음)
/// - 즐겨찾기 토글 기능 제공
@Observable
final class DateAdditionalFormViewModel: Identifiable {
    
    // MARK: - Properties
    
    /// 고유 식별자
    let id = UUID()
    
    /// 거래 발생 날짜 및 시간 (기본: 현재 시간)
    var selectedDate: Date
    
    /// 거래 메모 (선택사항, 20자 이상 시 요약 표시)
    var memo: String
    
    /// 즐겨찾기 등록 여부 (빠른 입력용)
    var isFavorite: Bool

    // MARK: - Computed Properties
    
    /// 카드 요약 정보 생성
    /// - 날짜는 항상 표시
    /// - 메모는 20자 이상 시 "..." 처리
    /// - 즐겨찾기 시 별표 이모지 추가
    var summary: String {
        var result: [String] = []
        result.append("📅 \(selectedDate.transactionListSectionHeader)")
        if !memo.isEmpty {
            let truncatedMemo = memo.count > 20
                ? String(memo.prefix(20)) + "..."
                : memo
            result.append("📝 \(truncatedMemo)")
        }

        if isFavorite {
            result.append("⭐ 즐겨찾기")
        }

        return result.isEmpty ? "정보 없음" : result.joined(separator: " • ")
    }

    init(selectedDate: Date = Date(),
         memo: String = "",
         isFavorite: Bool = false) {
        self.selectedDate = selectedDate
        self.memo = memo
        self.isFavorite = isFavorite
    }
    
    // MARK: - Action Handling
    
    /// 사용자 액션 정의
    enum Action {
        case toggleFavorite  // 즐겨찾기 상태 토글
    }
    
    func send(_ action: Action) {
        switch action {
        case .toggleFavorite:
            toggleFavorite()
        }
    }
    
    // MARK: - Private Methods
    
    /// 즐겨찾기 상태를 토글
    private func toggleFavorite() {
        self.isFavorite.toggle()
    }
}
