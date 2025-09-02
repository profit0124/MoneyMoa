//
//  PaymentPreviewData.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/2/25.
//

import Foundation
import SwiftUI

public struct PaymentPreviewData {
    public static let paymentMethodRatios: [PaymentMethodRatioDTO] = {
        let methods = [
            ("신용카드", 45, 0.45),
            ("체크카드", 30, 0.30),
            ("현금", 15, 0.15),
            ("계좌이체", 10, 0.10)
        ]
        
        return methods.enumerated().map { index, value in
            PaymentMethodRatioDTO(
                methodId: "\(index)",
                methodName: value.0,
                ratio: value.2,
                amount: Decimal(value.1 * Int.random(in: 10000...50000)),
                count: value.1,
                color: StatisticsColorScheme.paymentMethodColor(at: index)
            )
        }
    }()
    
    public static let merchantRanking: MerchantRankingDTO = {
        let merchants = [
            ("스타벅스", Decimal(180000), 15),
            ("이마트", Decimal(220000), 8),
            ("맥도날드", Decimal(85000), 12),
            ("GS25", Decimal(95000), 20),
            ("올리브영", Decimal(120000), 6),
            ("교보문고", Decimal(65000), 4),
            ("CGV", Decimal(45000), 3),
            ("우버", Decimal(75000), 9)
        ]
        
        let entries = merchants.enumerated().map { (index, merchantData) in
            let (name, amount, count) = merchantData
            return MerchantRankingDTO.Entry(
                rank: index + 1,
                merchant: name,
                count: count,
                total: amount
            )
        }
        
        return MerchantRankingDTO(entries: entries)
    }()
}
