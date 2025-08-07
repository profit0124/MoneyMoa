//
//  PaymentMethodExtensionTests.swift
//  MoneyMoaTests
//
//  Created by Claude on 8/3/25.
//

import XCTest
@testable import MoneyMoa

final class PaymentMethodExtensionTests: XCTestCase {
    
    // MARK: - PaymentMethodKind iconName Tests
    
    func testPaymentMethodKindIconNames() {
        // Given & When & Then
        XCTAssertEqual(PaymentMethodKind.cash.iconName, "banknote")
        XCTAssertEqual(PaymentMethodKind.credit.iconName, "creditcard")
        XCTAssertEqual(PaymentMethodKind.debit.iconName, "rectangle.and.hand.point.up.left")
        XCTAssertEqual(PaymentMethodKind.transfer.iconName, "building.columns")
    }
    
    // MARK: - PaymentMethodDTO displayIconName Tests
    
    func testDisplayIconNameWithCustomIcon() {
        // Given
        let paymentMethod = TestDataFactory.createPaymentMethod(
            name: "커스텀카드",
            kind: .credit,
            iconName: "creditcard.fill"
        )
        
        // When
        let displayIconName = paymentMethod.displayIconName
        
        // Then
        XCTAssertEqual(displayIconName, "creditcard.fill")
    }
    
    func testDisplayIconNameWithoutCustomIcon() {
        // Given
        let paymentMethod = TestDataFactory.createPaymentMethod(
            name: "일반신용카드",
            kind: .credit,
            iconName: nil
        )
        
        // When
        let displayIconName = paymentMethod.displayIconName
        
        // Then
        XCTAssertEqual(displayIconName, "creditcard") // kind의 기본 아이콘
    }
    
    func testDisplayIconNameFallbackForAllKinds() {
        // Given
        let cashMethod = TestDataFactory.createPaymentMethod(kind: .cash, iconName: nil)
        let creditMethod = TestDataFactory.createPaymentMethod(kind: .credit, iconName: nil)
        let debitMethod = TestDataFactory.createPaymentMethod(kind: .debit, iconName: nil)
        let transferMethod = TestDataFactory.createPaymentMethod(kind: .transfer, iconName: nil)
        
        // When & Then
        XCTAssertEqual(cashMethod.displayIconName, "banknote")
        XCTAssertEqual(creditMethod.displayIconName, "creditcard")
        XCTAssertEqual(debitMethod.displayIconName, "rectangle.and.hand.point.up.left")
        XCTAssertEqual(transferMethod.displayIconName, "building.columns")
    }
    
    func testDisplayIconNameCustomOverridesDefault() {
        // Given
        let customCashMethod = TestDataFactory.createPaymentMethod(
            kind: .cash,
            iconName: "dollarsign.circle.fill"
        )
        
        // When
        let displayIconName = customCashMethod.displayIconName
        
        // Then
        XCTAssertEqual(displayIconName, "dollarsign.circle.fill")
        XCTAssertNotEqual(displayIconName, PaymentMethodKind.cash.iconName)
    }
}
