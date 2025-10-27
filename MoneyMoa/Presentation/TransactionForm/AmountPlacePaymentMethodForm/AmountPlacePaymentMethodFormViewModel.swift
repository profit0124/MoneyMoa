//
//  AmountPlacePaymentMethodFormViewModel.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/18/25.
//

import Foundation
import Observation
import Combine

/// 거래 금액, 장소, 결제수단 입력을 관리하는 ViewModel
/// 
/// 주요 기능:
/// - 금액 입력 및 형식화 처리
/// - 결제수단 선택 및 동적 추가
/// - 포커스 상태 자동 관리
/// - 입력 유효성 검증
@Observable
final class AmountPlacePaymentMethodFormViewModel: Identifiable {

    // MARK: - Properties
    
    /// 고유 식별자
    let id = UUID()
    
    /// 활성 결제수단 조회 UseCase
    private var getActivePaymentMethodsUseCase: GetActivePaymentMethodsUseCase

    /// 결제수단 이벤트 퍼블리셔
    private var paymentMethodEventPublisher: any PaymentMethodEventPublisher

    /// 입력된 거래 금액 (nil이면 미입력 상태)
    var amount: Decimal?
    
    /// 거래 장소 또는 상대방
    var place: String
    
    /// 선택된 결제수단
    var selectedPaymentMethod: PaymentMethodDTO?
    
    /// 사용 가능한 결제수단 목록
    var paymentMethodOptions: [PaymentMethodDTO] = []
    
    /// 현재 포커스된 입력 필드
    var focusField: AmountPlacePaymentMethodFormField?

    // MARK: - Computed Properties
    
    /// 금액을 화폐 형식으로 포맷팅한 문자열 (₩ 제외)
    var formattedAmount: String {
        guard let amount else { return "" }
        let result = amount.formattedAmountWithoutWon
        return result
    }

    /// 카드 요약 정보 생성 (금액, 장소, 결제수단)
    var summary: String {
        var result: [String] = []
        if let amount, amount > 0 {
            result.append(amount.formattedAmountWithWon)
        }

        if !place.isEmpty {
            result.append(place)
        }

        if let paymentMethod = selectedPaymentMethod {
            result.append("💳 \(paymentMethod.name)")
        }

        return result.isEmpty ? "정보 없음" : result.joined(separator: " • ")
    }

    /// 폼 유효성 검증 (금액 > 0 && 결제수단 선택됨)
    var isValid: Bool {
        amount ?? 0 > 0 && selectedPaymentMethod != nil
    }

    /// Combine 구독 관리
    private var cancellables: Set<AnyCancellable> = []

    init(getActivePaymentMethodsUseCase: GetActivePaymentMethodsUseCase,
         paymentMethodEventPublisher: any PaymentMethodEventPublisher,
         amount: Decimal? = nil,
         place: String = "",
         selectedPaymentMethod: PaymentMethodDTO? = nil,
         paymentMethodOptions: [PaymentMethodDTO] = []) {
        self.getActivePaymentMethodsUseCase = getActivePaymentMethodsUseCase
        self.paymentMethodEventPublisher = paymentMethodEventPublisher
        self.amount = amount
        self.place = place
        self.selectedPaymentMethod = selectedPaymentMethod
        self.paymentMethodOptions = paymentMethodOptions
        self.focusField = nil

        setupPaymentMethodEventSubscription()
    }

    // MARK: - Action Handling
    
    /// 사용자 액션 정의
    enum Action {
        case onAppear                                    // 뷰 나타남
        case setSelectedPaymentMethod(PaymentMethodDTO)  // 결제수단 선택
        case setFocus(AmountPlacePaymentMethodFormField?) // 포커스 설정
        case presentPaymentMethodForm(AppRouter)         // 결제수단 추가 폼 표시
        case unsubscribe                                // 구독 해제
        case setDecimalAmount(String)                    // 금액 입력
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear:
            Task {
                try await getActivePaymentMethods()
                self.send(.setFocus(nil))
            }
        case .setSelectedPaymentMethod(let paymentMethod):
            self.send(.setFocus(.paymentMethod))
            setPaymentMethod(paymentMethod)

        case .setFocus(let field):
            setFocusField(field)

        case .presentPaymentMethodForm(let router):
            self.presentPaymentMethodForm(router)
            self.send(.setFocus(.paymentMethod))

        case .unsubscribe:
            cancellables.removeAll()

        case .setDecimalAmount(let text):
            setDecimalAmount(text)
        }
    }

    // MARK: - Private Methods
    
    @MainActor
    private func getActivePaymentMethods() async throws {
        self.paymentMethodOptions = try await getActivePaymentMethodsUseCase.execute()
    }

    /// 포커스 필드를 자동으로 설정
    private func setFocusField(_ field: AmountPlacePaymentMethodFormField?) {
        if let field {
            self.focusField = field
            return
        }

        if amount == nil {
            self.focusField = .amount
            return
        }

        if place.isEmpty {
            self.focusField = .place
            return
        }
    }

    private func setPaymentMethod(_ paymentMethod: PaymentMethodDTO) {
        self.selectedPaymentMethod = paymentMethod
    }

    private func presentPaymentMethodForm(_ router: AppRouter) {
        Task {
            await router.present(.settings(.paymentMethodForm(nil)), as: .sheet)
        }
    }

    private func setupPaymentMethodEventSubscription() {
        paymentMethodEventPublisher.paymentMethodEvents
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] event in
                guard let self = self else { return }

                switch event.type {
                case .created:
                    self.paymentMethodOptions.append(event.paymentMethod)
                    self.selectedPaymentMethod = event.paymentMethod

                case .updated:
                    // Remove existing item
                    self.paymentMethodOptions.removeAll { $0.id == event.paymentMethod.id }

                    // If active, add and sort
                    if event.paymentMethod.isActive {
                        self.paymentMethodOptions.append(event.paymentMethod)
                        self.paymentMethodOptions.sort()
                    } else {
                        // Clear selection if selected payment method becomes inactive
                        if self.selectedPaymentMethod?.id == event.paymentMethod.id {
                            self.selectedPaymentMethod = nil
                        }
                    }

                case .deleted:
                    self.paymentMethodOptions.removeAll { $0.id == event.paymentMethod.id }

                    // Clear selection if selected payment method is deleted
                    if self.selectedPaymentMethod?.id == event.paymentMethod.id {
                        self.selectedPaymentMethod = nil
                    }
                }
            })
            .store(in: &cancellables)
    }

    /// 텍스트 입력을 Decimal로 변환
    /// - 숫자만 추출하고 앞의 0 제거
    /// - 빈 문자열은 nil로 처리
    private func setDecimalAmount(_ text: String) {
        let digits = text.filter(\.isNumber)
        let dropped = digits.drop(while: { $0 == "0" })
        let normalized = dropped.isEmpty ? "" : String(dropped)

        self.amount = normalized.isEmpty ? nil : Decimal(string: normalized)
    }
}
