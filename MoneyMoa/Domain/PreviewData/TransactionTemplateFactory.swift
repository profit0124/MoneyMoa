//
//  TransactionTemplateFactory.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/15/25.
//

import Foundation

#if DEBUG

/// Factory for generating TransactionTemplate test data
/// - Provides realistic template data for testing and previews
/// - Supports Korean localization and various scenarios
/// - Includes both recurring and non-recurring templates
public enum TransactionTemplateFactory {

    // MARK: - Basic Builders

    /// Create a single template with specified parameters
    public static func createTemplate(
        config: TemplateConfig,
        subCategory: SubCategoryDTO,
        paymentMethod: PaymentMethodDTO
    ) -> TransactionTemplateDTO {
        return TransactionTemplateDTO(
            id: config.id,
            amount: config.amount,
            place: config.place,
            memo: config.memo,
            transactionType: config.transactionType,
            recurrencePeriod: config.recurrencePeriod,
            createdAt: config.createdAt,
            processedCount: config.processedCount,
            lastAddedAt: config.lastAddedAt,
            nextDueDate: config.nextDueDate,
            subCategory: subCategory,
            paymentMethod: paymentMethod
        )
    }

    public struct TemplateConfig {
        let id: UUID
        let amount: Decimal
        let place: String?
        let memo: String?
        let transactionType: TransactionType
        let recurrencePeriod: RecurrencePeriod
        let createdAt: Date
        let processedCount: Int
        let lastAddedAt: Date?
        let nextDueDate: Date?

        public init(
            id: UUID = UUID(),
            amount: Decimal,
            place: String?,
            memo: String?,
            transactionType: TransactionType,
            recurrencePeriod: RecurrencePeriod = .none,
            createdAt: Date = Date(),
            processedCount: Int = 1,
            lastAddedAt: Date? = nil,
            nextDueDate: Date? = nil
        ) {
            self.id = id
            self.amount = amount
            self.place = place
            self.memo = memo
            self.transactionType = transactionType
            self.recurrencePeriod = recurrencePeriod
            self.createdAt = createdAt
            self.processedCount = processedCount
            self.lastAddedAt = lastAddedAt
            self.nextDueDate = nextDueDate
        }
    }

    // MARK: - Predefined Template Sets

    /// 기본 템플릿 세트: none 1개, monthly 2개, yearly 1개
    public static func standardSet() -> [TransactionTemplateDTO] {
        let dependencies = createStandardDependencies()

        return [
            createOneTimeTemplate(dependencies: dependencies),
            createNetflixTemplate(dependencies: dependencies),
            createSpotifyTemplate(dependencies: dependencies),
            createInsuranceTemplate(dependencies: dependencies)
        ]
    }

    // MARK: - Private Helpers

    private static func createStandardDependencies() -> StandardDependencies {
        let categories = CategoryFactory.realistic()
        let paymentMethods = PaymentMethodFactory.standardSet()

        let subscriptionCategory = categories.subCategories.first { $0.name.contains("구독") }
            ?? CategoryFactory.createSubCategory(
                name: "구독서비스",
                transactionType: .fixedExpense,
                parentCategory: CategoryFactory.createCategory(
                    name: "구독", iconName: "tv", transactionType: .fixedExpense, orderIndex: 0
                ),
                orderIndex: 0
            )

        let insuranceCategory = categories.subCategories.first { $0.name.contains("보험") }
            ?? CategoryFactory.createSubCategory(
                name: "생명보험",
                transactionType: .fixedExpense,
                parentCategory: CategoryFactory.createCategory(
                    name: "보험료", iconName: "shield", transactionType: .fixedExpense, orderIndex: 0
                ),
                orderIndex: 0
            )

        let creditCard = paymentMethods.first { $0.kind == .credit }
            ?? PaymentMethodFactory.create(name: "신용카드", kind: .credit)

        return StandardDependencies(
            subscriptionCategory: subscriptionCategory,
            insuranceCategory: insuranceCategory,
            creditCard: creditCard
        )
    }

    private static func createOneTimeTemplate(dependencies: StandardDependencies) -> TransactionTemplateDTO {
        let now = Date()
        let createdAt = Calendar.current.date(byAdding: .day, value: -15, to: now) ?? now

        let config = TemplateConfig(
            amount: 50000,
            place: "생일선물",
            memo: "친구 생일선물",
            transactionType: .variableExpense,
            recurrencePeriod: .none,
            createdAt: createdAt
        )
        return createTemplate(
            config: config,
            subCategory: CategoryFactory.createSubCategory(
                name: "선물",
                transactionType: .variableExpense,
                parentCategory: CategoryFactory.createCategory(
                    name: "경조사", iconName: "gift", transactionType: .variableExpense, orderIndex: 0
                ),
                orderIndex: 0
            ),
            paymentMethod: dependencies.creditCard
        )
    }

    private static func createNetflixTemplate(dependencies: StandardDependencies) -> TransactionTemplateDTO {
        let now = Date()
        // 2개월 5일 전에 생성되어, 이미 2번 처리됨
        let createdAt = Calendar.current.date(byAdding: .day, value: -65, to: now) ?? now
        let processedCount = 2
        let lastAddedAt = RecurrencePeriod.monthly.calculateOccurenceDate(from: createdAt, processCount: processedCount - 1)

        // nextDueDate가 과거가 되도록 조정 (약 5일 전)
        let adjustedNextDueDate = Calendar.current.date(byAdding: .day, value: -5, to: now)

        let config = TemplateConfig(
            amount: 17000,
            place: "넷플릭스",
            memo: "월간 구독료",
            transactionType: .fixedExpense,
            recurrencePeriod: .monthly,
            createdAt: createdAt,
            processedCount: processedCount,
            lastAddedAt: lastAddedAt,
            nextDueDate: adjustedNextDueDate  // 처리 대상 (5일 전)
        )
        return createTemplate(config: config, subCategory: dependencies.subscriptionCategory, paymentMethod: dependencies.creditCard)
    }

    private static func createSpotifyTemplate(dependencies: StandardDependencies) -> TransactionTemplateDTO {
        let now = Date()
        // 2개월 25일 전에 생성되어, 이미 2번 처리됨
        let createdAt = Calendar.current.date(byAdding: .day, value: -85, to: now) ?? now
        let processedCount = 2
        let lastAddedAt = RecurrencePeriod.monthly.calculateOccurenceDate(from: createdAt, processCount: processedCount - 1)

        // nextDueDate가 며칠 후가 되도록 설정 (아직 처리 안 함)
        let nextDueDate = Calendar.current.date(byAdding: .day, value: 5, to: now)

        let config = TemplateConfig(
            amount: 10900,
            place: "스포티파이",
            memo: "음악 스트리밍",
            transactionType: .fixedExpense,
            recurrencePeriod: .monthly,
            createdAt: createdAt,
            processedCount: processedCount,
            lastAddedAt: lastAddedAt,
            nextDueDate: nextDueDate  // 미처리 (5일 후)
        )
        return createTemplate(config: config, subCategory: dependencies.subscriptionCategory, paymentMethod: dependencies.creditCard)
    }

    private static func createInsuranceTemplate(dependencies: StandardDependencies) -> TransactionTemplateDTO {
        let now = Date()
        // 1년 전에 생성되어, 이미 1번 처리됨 (생성 시)
        let createdAt = Calendar.current.date(byAdding: .year, value: -1, to: now) ?? now
        let processedCount = 1
        let lastAddedAt = createdAt
        let nextDueDate = RecurrencePeriod.yearly.calculateOccurenceDate(from: createdAt, processCount: processedCount) // 오늘 (처리 대상)

        let config = TemplateConfig(
            amount: 1200000,
            place: "삼성생명",
            memo: "연간 보험료",
            transactionType: .fixedExpense,
            recurrencePeriod: .yearly,
            createdAt: createdAt,
            processedCount: processedCount,
            lastAddedAt: lastAddedAt,
            nextDueDate: nextDueDate
        )
        return createTemplate(config: config, subCategory: dependencies.insuranceCategory, paymentMethod: dependencies.creditCard)
    }

    private struct StandardDependencies {
        let subscriptionCategory: SubCategoryDTO
        let insuranceCategory: SubCategoryDTO
        let creditCard: PaymentMethodDTO
    }

    // MARK: - Test Scenarios

    /// 처리 대상인 템플릿들만 반환
    public static func dueTemplates(relativeTo date: Date = Date()) -> [TransactionTemplateDTO] {
        return standardSet().filter { template in
            guard template.recurrencePeriod != .none else { return false }
            guard let nextDueDate = template.nextDueDate else { return false }
            return nextDueDate <= date
        }
    }

    /// 처리 대상이 아닌 템플릿들만 반환
    public static func notDueTemplates(relativeTo date: Date = Date()) -> [TransactionTemplateDTO] {
        return standardSet().filter { template in
            if template.recurrencePeriod == .none { return true }
            guard let nextDueDate = template.nextDueDate else { return true }
            return nextDueDate > date
        }
    }

    /// 월간 구독 템플릿들만 반환
    public static func monthlyTemplates() -> [TransactionTemplateDTO] {
        return standardSet().filter { $0.recurrencePeriod == .monthly }
    }

    /// 연간 템플릿들만 반환
    public static func yearlyTemplates() -> [TransactionTemplateDTO] {
        return standardSet().filter { $0.recurrencePeriod == .yearly }
    }

    /// 일회성 템플릿들만 반환
    public static func oneTimeTemplates() -> [TransactionTemplateDTO] {
        return standardSet().filter { $0.recurrencePeriod == .none }
    }

    // MARK: - Random Generators

    /// 랜덤 템플릿 생성
    public static func random() -> TransactionTemplateDTO {
        let templates = standardSet()
        return templates.randomElement() ?? templates[0]
    }

    /// 랜덤 템플릿 여러 개 생성
    public static func randomSet(count: Int) -> [TransactionTemplateDTO] {
        return (0..<count).map { _ in random() }
    }
}

// MARK: - Convenience Extensions

public extension TransactionTemplateFactory {
    /// 기본 세트에서 처리 대상 템플릿 개수
    static var dueTemplateCount: Int {
        dueTemplates().count
    }

    /// 기본 세트에서 미처리 템플릿 개수
    static var notDueTemplateCount: Int {
        notDueTemplates().count
    }

    /// 모든 반복 템플릿 (none 제외)
    static var recurringTemplates: [TransactionTemplateDTO] {
        standardSet().filter { $0.recurrencePeriod != .none }
    }
}

#endif
