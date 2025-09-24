//
//  Transaction.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 7/26/25.
//

import Foundation
import SwiftData

// MARK: - Transaction Model

@Model
final class Transaction {
    @Attribute(.unique) var id: UUID
    var amount: Decimal
    var date: Date  // UTC로 저장되는 절대 시점
    var place: String?  // 거래 장소/대상 (맥도날드, 친구들과 더치페이, 어머니 용돈 등)
    var memo: String?
    var transactionTypeRawValue: String
    var transactionType: TransactionType {
        get { TransactionType(rawValue: transactionTypeRawValue) ?? .variableExpense }
        set { transactionTypeRawValue = newValue.rawValue }
    }
    
    // MARK: - TimeZone Context Fields
    /// 거래 발생 시점의 시간대 식별자 (e.g., "Asia/Seoul", "America/New_York")
    var timeZoneIdentifier: String?
    
    /// 거래 발생 시점의 캘린더 식별자 (e.g., "gregorian", "japanese")
    var calendarIdentifier: String?
    
    /// 거래 발생 시점의 로케일 식별자 (e.g., "ko_KR", "en_US")
    var localeIdentifier: String?
    
    @Relationship var subCategory: SubCategory
    @Relationship var paymentMethod: PaymentMethod
    @Relationship var template: TransactionTemplate?

    init(
        id: UUID = UUID(),
        amount: Decimal,
        date: Date = Date(),
        place: String? = nil,
        memo: String? = nil,
        transactionType: TransactionType,
        subCategory: SubCategory,
        paymentMethod: PaymentMethod,
        timeZoneIdentifier: String,
        calendarIdentifier: String,
        localeIdentifier: String?,
        template: TransactionTemplate? = nil
    ) {
        self.id = id
        self.amount = amount
        self.date = date
        self.place = place
        self.memo = memo
        self.transactionTypeRawValue = transactionType.rawValue
        self.subCategory = subCategory
        self.paymentMethod = paymentMethod
        
        // TimeZone Context - 제공되지 않으면 현재 기기 설정 사용
        self.timeZoneIdentifier = timeZoneIdentifier
        self.calendarIdentifier = calendarIdentifier
        self.localeIdentifier = localeIdentifier
        self.template = template
    }
}

// MARK: - Transaction to DTO Extensions

extension Transaction {
    /// Transaction을 TransactionDTO로 변환
    /// - date는 UTC로 저장된 값을 로컬 시간으로 변환하여 반환
    public func toDTO() -> TransactionDTO {
        let timeContext = TransactionTimeContext(
            timeZoneIdentifier: timeZoneIdentifier ?? TimeZone.current.identifier,
            calendarIdentifier: calendarIdentifier ?? TransactionTimeContext.current.calendarIdentifier,
            localeIdentifier: localeIdentifier ?? Locale.current.identifier
        )
        // UTC로 저장된 date를 사용자 경험 시간(로컬)으로 변환
        let localDate = self.date.toTimeContext(timeContext)
        return TransactionDTO(
            id: self.id,
            amount: self.amount,
            date: localDate,  // 로컬 시간으로 변환된 값
            place: self.place,
            memo: self.memo,
            transactionType: self.transactionType,
            subCategory: self.subCategory.toDTO(),
            paymentMethod: self.paymentMethod.toDTO(),
            timeContext: timeContext,
            transactionTemplate: self.template?.toDTO()
        )
    }
}

// MARK: - Collection Extensions

extension Collection where Element == Transaction {
    /// Transaction 배열을 TransactionDTO 배열로 변환
    func toDTOs() -> [TransactionDTO] {
        return self.map { $0.toDTO() }.sorted()
    }
}

// MARK: - DTO to SwiftData Model Extensions

extension TransactionDTO {
    /// TransactionDTO를 SwiftData Transaction 모델로 변환
    /// - Parameters:
    ///   - subCategory: 연결할 SubCategory 모델 (필수)
    ///   - paymentMethod: 연결할 PaymentMethod 모델 (필수)
    /// - Note: date는 로컬 시간에서 UTC로 변환되어 저장됨
    func toModel(subCategory: SubCategory, paymentMethod: PaymentMethod, template: TransactionTemplate? = nil) -> Transaction {
        // 로컬 시간(사용자 경험 시간)을 UTC로 변환하여 저장
        let utcDate = self.date.toUTC

        return Transaction(
            id: self.id,
            amount: self.amount,
            date: utcDate,  // UTC로 변환된 시간
            place: self.place,
            memo: self.memo,
            transactionType: self.transactionType,
            subCategory: subCategory,
            paymentMethod: paymentMethod,
            timeZoneIdentifier: self.timeContext.timeZoneIdentifier,
            calendarIdentifier: self.timeContext.calendarIdentifier,
            localeIdentifier: self.timeContext.localeIdentifier,
            template: template
        )
    }

    func toModelWithTemplate(subCategory: SubCategory, paymentMethod: PaymentMethod, template: TransactionTemplate) -> Transaction {
        let utcDate = self.date.toUTC

        return Transaction(
            id: self.id,
            amount: self.amount,
            date: utcDate,  // UTC로 변환된 시간
            place: self.place,
            memo: self.memo,
            transactionType: self.transactionType,
            subCategory: subCategory,
            paymentMethod: paymentMethod,
            timeZoneIdentifier: self.timeContext.timeZoneIdentifier,
            calendarIdentifier: self.timeContext.calendarIdentifier,
            localeIdentifier: self.timeContext.localeIdentifier,
            template: template
        )
    }

    func toTemplate(subCategory: SubCategory, paymentMethod: PaymentMethod, recurrencePeriod: RecurrencePeriod) -> TransactionTemplate {
        let calendar = self.timeContext.calendar
        let processCount = 1
        return TransactionTemplate(
            amount: self.amount,
            place: self.place,
            memo: self.memo,
            transactionType: self.transactionType,
            recurrencePeriod: recurrencePeriod,
            createdAt: self.date,
            lastAddedAt: self.date,
            nextDueDate: recurrencePeriod.calculateOccurenceDate(from: self.date, processCount: processCount, calendar: calendar),
            timeZoneIdentifier: self.timeContext.timeZoneIdentifier,
            calendarIdentifier: self.timeContext.calendarIdentifier,
            localeIdentifier: self.timeContext.localeIdentifier,
            subCategory: subCategory,
            paymentMethod: paymentMethod
        )
    }
}
