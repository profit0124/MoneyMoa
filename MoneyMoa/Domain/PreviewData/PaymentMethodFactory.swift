//
//  PaymentMethodFactory.swift
//  MoneyMoa
//
//  Created by Claude on 9/4/25.
//

import Foundation

#if DEBUG

public enum PaymentMethodFactory {
    
    // MARK: - Basic Builders
    
    /// 기본 결제수단 생성
    /// - Parameters:
    ///   - name: 결제수단명
    ///   - kind: 결제수단 종류
    ///   - iconName: 아이콘명 (선택사항)
    ///   - orderIndex: 정렬 순서
    ///   - isActive: 활성 상태
    /// - Returns: PaymentMethodDTO
    public static func create(
        name: String,
        kind: PaymentMethodKind,
        iconName: String? = nil,
        orderIndex: Int = 0,
        isActive: Bool = true
    ) -> PaymentMethodDTO {
        return PaymentMethodDTO(
            name: name,
            kind: kind,
            iconName: iconName,
            orderIndex: orderIndex,
            isActive: isActive
        )
    }
    
    // MARK: - Standard Sets
    
    /// 기본 4가지 결제수단 세트
    /// - Returns: [현금, 체크카드, 신용카드, 계좌이체]
    public static func standardSet() -> [PaymentMethodDTO] {
        return [
            create(name: "현금", kind: .cash, orderIndex: 0),
            create(name: "체크카드", kind: .debit, orderIndex: 1),
            create(name: "신용카드", kind: .credit, orderIndex: 2),
            create(name: "계좌이체", kind: .transfer, orderIndex: 3)
        ]
    }
    
    /// 한국 은행 카드들
    /// - Returns: 주요 한국 은행들의 신용/체크카드
    public static func koreanBankCards() -> [PaymentMethodDTO] {
        let banks = ["국민", "신한", "우리", "하나", "기업", "농협", "카카오뱅크", "토스뱅크"]
        var paymentMethods: [PaymentMethodDTO] = []
        var orderIndex = 0
        
        // 현금 추가
        paymentMethods.append(create(name: "현금", kind: .cash, orderIndex: orderIndex))
        orderIndex += 1
        
        // 각 은행별 신용카드/체크카드
        for bank in banks {
            paymentMethods.append(create(
                name: "\(bank) 신용카드", 
                kind: .credit, 
                orderIndex: orderIndex
            ))
            orderIndex += 1
            
            paymentMethods.append(create(
                name: "\(bank) 체크카드", 
                kind: .debit, 
                orderIndex: orderIndex
            ))
            orderIndex += 1
        }
        
        // 계좌이체 추가
        paymentMethods.append(create(name: "계좌이체", kind: .transfer, orderIndex: orderIndex))
        
        return paymentMethods
    }
    
    /// 랜덤 결제수단 세트
    /// - Parameter count: 생성할 개수
    /// - Returns: 랜덤하게 생성된 결제수단 배열
    public static func randomSet(count: Int) -> [PaymentMethodDTO] {
        let kinds: [PaymentMethodKind] = [.cash, .credit, .debit, .transfer]
        let prefixes = ["국민", "신한", "우리", "하나", "기업", "농협", "카카오", "토스", "삼성", "현대"]
        let suffixes = ["카드", "체크카드", "신용카드", "페이", "머니"]
        
        return (0..<count).map { index in
            let kind = kinds.randomElement() ?? .credit
            let prefix = prefixes.randomElement() ?? "기본"
            let suffix = suffixes.randomElement() ?? "카드"
            let name = kind == .cash ? "현금" : 
                      kind == .transfer ? "계좌이체" : 
                      "\(prefix)\(suffix)"
            
            return create(
                name: name,
                kind: kind,
                orderIndex: index,
                isActive: Bool.random() ? true : Double.random(in: 0...1) > 0.2 // 80% 확률로 활성
            )
        }
    }
    
    // MARK: - Special Cases
    
    /// 긴 이름을 가진 결제수단 (UI 테스트용)
    /// - Returns: 매우 긴 이름의 결제수단
    public static func longNameCard() -> PaymentMethodDTO {
        return create(
            name: "매우긴이름을가진결제수단테스트용신용카드입니다",
            kind: .credit,
            orderIndex: 999
        )
    }
    
    /// 비활성 상태의 결제수단
    /// - Returns: 비활성 상태의 결제수단
    public static func inactiveCard() -> PaymentMethodDTO {
        return create(
            name: "비활성카드",
            kind: .credit,
            orderIndex: 1000,
            isActive: false
        )
    }
    
    /// 커스텀 아이콘을 가진 결제수단
    /// - Returns: 커스텀 아이콘이 설정된 결제수단
    public static func customIconCard() -> PaymentMethodDTO {
        return create(
            name: "특별카드",
            kind: .credit,
            iconName: "star.fill",
            orderIndex: 0
        )
    }
    
    // MARK: - Scenario-based Generators
    
    /// 최소한의 결제수단 (현금, 카드 1개)
    /// - Returns: 기본적인 2개 결제수단
    public static func minimalSet() -> [PaymentMethodDTO] {
        return [
            create(name: "현금", kind: .cash, orderIndex: 0),
            create(name: "주카드", kind: .credit, orderIndex: 1)
        ]
    }
    
    /// 현실적인 개인 결제수단 세트
    /// - Returns: 일반적인 개인이 사용할 법한 결제수단들
    public static func realisticPersonalSet() -> [PaymentMethodDTO] {
        return [
            create(name: "현금", kind: .cash, orderIndex: 0),
            create(name: "주카드(신용)", kind: .credit, orderIndex: 1),
            create(name: "체크카드", kind: .debit, orderIndex: 2),
            create(name: "카카오페이", kind: .transfer, orderIndex: 3),
            create(name: "예비카드", kind: .credit, orderIndex: 4, isActive: false)
        ]
    }
    
    /// 다양한 종류별 결제수단 세트
    /// - Returns: 모든 종류가 골고루 포함된 결제수단들
    public static func diverseSet() -> [PaymentMethodDTO] {
        return [
            // Cash
            create(name: "현금", kind: .cash, orderIndex: 0),
            
            // Credit Cards
            create(name: "신한카드", kind: .credit, orderIndex: 1),
            create(name: "국민카드", kind: .credit, orderIndex: 2),
            create(name: "삼성카드", kind: .credit, orderIndex: 3),
            
            // Debit Cards  
            create(name: "우리체크카드", kind: .debit, orderIndex: 4),
            create(name: "하나체크카드", kind: .debit, orderIndex: 5),
            
            // Transfers
            create(name: "계좌이체", kind: .transfer, orderIndex: 6),
            create(name: "카카오페이", kind: .transfer, orderIndex: 7),
            create(name: "토스페이", kind: .transfer, orderIndex: 8)
        ]
    }
    
    // MARK: - Edge Cases
    
    /// 테스트용 엣지 케이스들
    /// - Returns: 다양한 엣지 케이스를 포함한 결제수단들
    public static var edgeCases: [PaymentMethodDTO] {
        return [
            longNameCard(),
            inactiveCard(),
            customIconCard(),
            create(name: "1", kind: .cash, orderIndex: 0), // 최소 길이
            create(name: "", kind: .credit, orderIndex: 1) // 빈 이름 (검증용)
        ]
    }
    
    // MARK: - Quick Access
    
    /// 빈 목록
    public static var empty: [PaymentMethodDTO] { [] }
    
    /// 단일 현금
    public static var cashOnly: [PaymentMethodDTO] { 
        [create(name: "현금", kind: .cash, orderIndex: 0)]
    }
    
    /// 단일 카드
    public static var cardOnly: [PaymentMethodDTO] { 
        [create(name: "신용카드", kind: .credit, orderIndex: 0)]
    }
}
#endif
