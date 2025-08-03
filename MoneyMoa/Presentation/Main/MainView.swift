//
//  MainView.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/30/25.
//

import SwiftUI

struct MainView: View {
    @State private var viewModel: MainViewModel
    
    init(viewModel: MainViewModel) {
        self._viewModel = State(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // TransactionList Section
                    TransactionListView(
                        listData: viewModel.listData,
                        onTransactionTap: handleTransactionTap
                    )
                }
            }
            .navigationTitle("MoneyMoa")
            .navigationBarTitleDisplayMode(.large)
            .task {
                viewModel.send(.loadTransactions)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func handleTransactionTap(_ transaction: TransactionDTO) {
        // TODO: 거래 상세 화면으로 이동
        print("Transaction tapped: \(transaction.id)")
    }
}

// MARK: - Preview

#Preview {
    // TODO: 실제 의존성 주입으로 교체 예정
    let mockUseCase = MockGetMonthlyTransactionsUseCase()
    let viewModel = MainViewModel(getMonthlyTransactionsUseCase: mockUseCase)
    
    MainView(viewModel: viewModel)
}


        /// TODO: 다음 구현 예정 섹션들
        /// 1. HeaderSection
        /// - 앱 이름 표시
        /// - Toolbar
        ///     - Chart Button -> 월별 / 분류별 분석 화면 진입
        ///     - 설정 버튼 -> 환경설정 화면 진입
        /// 2. YearMonth Section
        /// - 현재 연/월 텍스트 노출
        /// - 화살표버튼 혹은 Picker 로 연월 변경
        /// - Open Issue: 해당 Section 을 Summary Section 내부로 이동할지 여부 미정, 다른 섹션에 영향을 주는 요소로 분리되어야 한다고 생각
        ///
        /// 3. summary Section
        /// - 지출 합계는 항상 표시
        /// - 예살 설정이 없다면 예산 설정 안내 CTA 배너 표시
        /// - 예산, 남은 예산, 사용률, 남은 기간, 전월대비 지출 비교 노출
        /// 4. Calendar Section
        /// - 1. 정 연/월 달력 그리드
        /// - 2. 각 날짜 하단에 수입·지출 금액 색상 표시
        /// - 3. **Today** 날짜 하이라이트(굵은 테두리)
        /// - 4. 날짜 탭 → `selectedDate` Publish → MainView로 전달
        /// 5. Monthly Transaction List Section
        ///     1. Section Header 규칙
        ///     - 오늘 → “오늘”
        ///     - 1일 전 → “어제”
        ///     - 2·3일 전 → “2일전”, “3일전”
        ///     - 그 외 → `yyyy.MM.dd (E)` 형식(ex: 2025.07.01 (화))
        ///     2. 거래 셀: 카드형 레이아웃, 카테고리 아이콘·메모·금액 표시
        ///     3. 셀 탭 → FullScreenCover(모달) 또는 NavigationStack Push로 상세 페이지
        ///     4. **캘린더‑리스트 연동**: Calendar 날짜 선택 시 해당 날짜 Section으로 스크롤 to Top
        /// 6. 우측 하단 + 버튼 (Transaction 추가)
