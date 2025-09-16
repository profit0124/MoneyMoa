//
//  TransactionFactory.swift
//  MoneyMoa
//
//  Created by Claude Code on 9/3/25.
//

import Foundation

/// Factory for generating Transaction test data
/// - Provides realistic transaction data for testing and previews
/// - Supports various scenarios and bulk generation
public enum TransactionFactory {
    
    // MARK: - Basic Builders
    
    /// Create a simple sample transaction for testing
    public static func sample() -> TransactionDTO {
        return create(
            amount: 50000,
            place: "Sample Place",
            memo: "Sample Memo",
            transactionType: .variableExpense,
            subCategory: .mockFoodExpense,
            paymentMethod: .mockCreditCard
        )
    }
    
    /// Create a single transaction with specified parameters
    public static func create(
        id: UUID = UUID(),
        amount: Decimal,
        date: Date = Date(),
        place: String? = nil,
        memo: String? = nil,
        transactionType: TransactionType,
        subCategory: SubCategoryDTO,
        paymentMethod: PaymentMethodDTO
    ) -> TransactionDTO {
        return TransactionDTO(
            id: id,
            amount: amount,
            date: date,
            place: place,
            memo: memo,
            transactionType: transactionType,
            subCategory: subCategory,
            paymentMethod: paymentMethod
        )
    }
    
    /// Create a random transaction with realistic data
    public static func createRandom(date: Date? = nil) -> TransactionDTO {
        let scenarios = TransactionScenario.allCases
        let scenario = scenarios.randomElement()!
        let transactionDate = date ?? randomDateInCurrentMonth()
        
        return create(
            amount: scenario.randomAmount(),
            date: transactionDate,
            place: scenario.randomPlace(),
            memo: scenario.randomMemo(),
            transactionType: scenario.transactionType,
            subCategory: scenario.randomSubCategory(),
            paymentMethod: scenario.randomPaymentMethod()
        )
    }
    
    // MARK: - Bulk Generators
    
    /// Generate a set of random transactions
    public static func randomSet(count: Int, context: YearMonth? = nil) -> [TransactionDTO] {
        let yearMonth = context ?? YearMonth(from: Date())
        
        return (0..<count).map { _ in
            let date = randomDateInMonth(yearMonth, dayBias: .random)
            return createRandom(date: date)
        }
    }
    
    /// Generate realistic transaction data with proper distribution
    public static func realistic() -> [TransactionDTO] {
        var transactions: [TransactionDTO] = []
        
        // Generate for last 3 months
        let currentMonth = YearMonth(from: Date())
        let months = [
            currentMonth.previousMonth().previousMonth(),
            currentMonth.previousMonth(),
            currentMonth
        ]
        
        for month in months {
            transactions.append(contentsOf: realisticMonthlyTransactions(for: month))
        }
        
        return transactions.sorted { $0.date > $1.date }
    }
    
    // MARK: - Test Scenarios
    
    /// Empty transaction list
    public static var empty: [TransactionDTO] { [] }
    
    /// Minimal transaction set for basic testing
    public static var minimal: [TransactionDTO] {
        [
            createRandom(),
            createRandom(),
            createRandom(),
            createRandom(),
            createRandom()
        ]
    }
    
    /// Normal transaction set for regular testing
    public static var normal: [TransactionDTO] {
        randomSet(count: 50)
    }
    
    /// Edge cases and boundary values
    public static var edge: [TransactionDTO] {
        [
            // Very small amount
            create(amount: 1, transactionType: .variableExpense, subCategory: .mockFoodExpense, paymentMethod: .mockCash),
            // Very large amount
            create(amount: 10_000_000, transactionType: .income, subCategory: .mockSalary, paymentMethod: .mockTransfer),
            // Future date
            create(amount: 50000, date: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(), transactionType: .variableExpense, subCategory: .mockFoodExpense, paymentMethod: .mockCreditCard),
            // Old date
            create(amount: 30000, date: Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date(), transactionType: .variableExpense, subCategory: .mockFoodExpense, paymentMethod: .mockCreditCard)
        ]
    }
    
    // MARK: - Private Helpers
    
    private static func realisticMonthlyTransactions(for yearMonth: YearMonth) -> [TransactionDTO] {
        var transactions: [TransactionDTO] = []
        
        // Fixed expenses (monthly recurring)
        transactions.append(contentsOf: generateFixedExpenses(for: yearMonth))
        
        // Variable expenses (daily activities)
        transactions.append(contentsOf: generateVariableExpenses(for: yearMonth))
        
        // Income (salary, allowances)
        transactions.append(contentsOf: generateIncome(for: yearMonth))
        
        return transactions
    }
    
    private static func generateFixedExpenses(for yearMonth: YearMonth) -> [TransactionDTO] {
        let firstDay = yearMonth.startOfMonth
        
        return [
            create(amount: 500000, date: firstDay, memo: "월세", transactionType: .fixedExpense, subCategory: .mockHousingRent, paymentMethod: .mockTransfer),
            create(amount: 80000, date: addDays(to: firstDay, days: 1), memo: "핸드폰 요금", transactionType: .fixedExpense, subCategory: .mockUtilitiesMobile, paymentMethod: .mockCreditCard),
            create(amount: 120000, date: addDays(to: firstDay, days: 2), memo: "인터넷 요금", transactionType: .fixedExpense, subCategory: .mockUtilitiesInternet, paymentMethod: .mockCreditCard)
        ]
    }
    
    private static func generateVariableExpenses(for yearMonth: YearMonth) -> [TransactionDTO] {
        var transactions: [TransactionDTO] = []
        let daysInMonth = Calendar.current.range(of: .day, in: .month, for: yearMonth.startOfMonth)?.count ?? 30
        
        // Daily expenses (70% of days)
        let activeDays = Int(Double(daysInMonth) * 0.7)
        let selectedDays = (1...daysInMonth).shuffled().prefix(activeDays)
        
        for day in selectedDays {
            let date = addDays(to: yearMonth.startOfMonth, days: day - 1)
            let dailyTransactionCount = Int.random(in: 1...4)
            
            for _ in 0..<dailyTransactionCount {
                transactions.append(createRandom(date: date))
            }
        }
        
        return transactions
    }
    
    private static func generateIncome(for yearMonth: YearMonth) -> [TransactionDTO] {
        let salaryDate = addDays(to: yearMonth.startOfMonth, days: 24) // 25th of month
        let allowanceDate = addDays(to: yearMonth.startOfMonth, days: 14) // 15th of month
        
        return [
            create(amount: Decimal(Int.random(in: 2_500_000...3_500_000)), date: salaryDate, memo: "월급", transactionType: .income, subCategory: .mockSalary, paymentMethod: .mockTransfer),
            create(amount: Decimal(Int.random(in: 100_000...300_000)), date: allowanceDate, memo: "용돈", transactionType: .income, subCategory: .mockIncomeAllowance, paymentMethod: .mockCash)
        ]
    }
    
    private static func randomDateInCurrentMonth() -> Date {
        let yearMonth = YearMonth(from: Date())
        return randomDateInMonth(yearMonth, dayBias: .current)
    }
    
    private static func randomDateInMonth(_ yearMonth: YearMonth, dayBias: DayBias) -> Date {
        let calendar = Calendar.current
        let startOfMonth = yearMonth.startOfMonth
        let daysInMonth = calendar.range(of: .day, in: .month, for: startOfMonth)?.count ?? 30
        
        let dayRange: ClosedRange<Int>
        switch dayBias {
        case .early:
            dayRange = 1...10
        case .middle:
            dayRange = 11...20
        case .late:
            dayRange = 21...daysInMonth
        case .current:
            let today = calendar.component(.day, from: Date())
            dayRange = 1...min(today, daysInMonth)
        case .random:
            dayRange = 1...daysInMonth
        }
        
        let randomDay = Int.random(in: dayRange)
        let randomHour = Int.random(in: 9...21)
        let randomMinute = Int.random(in: 0...59)
        
        var components = calendar.dateComponents([.year, .month], from: startOfMonth)
        components.day = randomDay
        components.hour = randomHour
        components.minute = randomMinute
        
        return calendar.date(from: components) ?? startOfMonth
    }
    
    private static func addDays(to date: Date, days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: date) ?? date
    }
    
    private enum DayBias {
        case early, middle, late, current, random
    }
}

// MARK: - Transaction Scenarios

private enum TransactionScenario: CaseIterable {
    case foodDelivery
    case restaurant
    case groceries
    case coffee
    case transport
    case shopping
    case beauty
    case entertainment
    case health
    case education
    
    var transactionType: TransactionType {
        return .variableExpense
    }
    
    func randomAmount() -> Decimal {
        let range: ClosedRange<Int>
        switch self {
        case .foodDelivery:
            range = 15_000...35_000
        case .restaurant:
            range = 25_000...80_000
        case .groceries:
            range = 30_000...150_000
        case .coffee:
            range = 4_000...8_000
        case .transport:
            range = 1_500...25_000
        case .shopping:
            range = 20_000...200_000
        case .beauty:
            range = 15_000...100_000
        case .entertainment:
            range = 10_000...50_000
        case .health:
            range = 20_000...80_000
        case .education:
            range = 50_000...300_000
        }
        
        return Decimal(Int.random(in: range))
    }
    
    func randomPlace() -> String? {
        let places: [String?]
        switch self {
        case .foodDelivery:
            places = ["배달의민족", "요기요", "쿠팡이츠", nil]
        case .restaurant:
            places = ["맥도날드", "스타벅스", "올리브영", "CGV", "교보문고", nil]
        case .groceries:
            places = ["이마트", "홈플러스", "롯데마트", "GS25", "CU"]
        case .coffee:
            places = ["스타벅스", "투썸플레이스", "카페베네", "이디야"]
        case .transport:
            places = [nil, "지하철", "버스", "택시"]
        case .shopping:
            places = ["온라인쇼핑", "백화점", "아웃렛", "H&M", "ZARA"]
        case .beauty:
            places = ["올리브영", "미용실", "네일샵", "마사지"]
        case .entertainment:
            places = ["CGV", "롯데시네마", "노래방", "PC방"]
        case .health:
            places = ["병원", "약국", "헬스장", "필라테스"]
        case .education:
            places = ["교보문고", "인강", "학원", "도서구입"]
        }
        
        return places.randomElement() ?? nil
    }
    
    func randomMemo() -> String? {
        let memos: [String?]
        switch self {
        case .foodDelivery:
            memos = ["점심 배달", "야식", "저녁식사", nil]
        case .restaurant:
            memos = ["점심식사", "저녁식사", "친구들과", "가족식사", nil]
        case .groceries:
            memos = ["장보기", "생필품", "식료품", nil]
        case .coffee:
            memos = ["커피", "음료", "디저트", nil]
        case .transport:
            memos = ["교통비", "출근", "외출", nil]
        case .shopping:
            memos = ["옷", "신발", "생활용품", "온라인쇼핑", nil]
        case .beauty:
            memos = ["화장품", "미용", "헤어", nil]
        case .entertainment:
            memos = ["영화", "여가", "오락", nil]
        case .health:
            memos = ["병원비", "약값", "운동", nil]
        case .education:
            memos = ["책", "강의", "공부", nil]
        }
        
        return memos.randomElement() ?? nil
    }
    
    func randomSubCategory() -> SubCategoryDTO {
        switch self {
        case .foodDelivery, .restaurant:
            return .mockFoodExpense
        case .groceries:
            return .mockFoodExpense
        case .coffee:
            return .mockFoodExpense
        case .transport:
            return .mockTransportBus
        case .shopping:
            return .mockShopping
        case .beauty:
            return .mockBeauty
        case .entertainment:
            return .mockEntertainment
        case .health:
            return .mockHealthcare
        case .education:
            return .mockEducation
        }
    }
    
    func randomPaymentMethod() -> PaymentMethodDTO {
        let methods: [PaymentMethodDTO] = [.mockCreditCard, .mockDebitCard, .mockCash, .mockTransfer]
        let weights: [Double]
        
        switch self {
        case .foodDelivery, .shopping:
            weights = [0.6, 0.2, 0.1, 0.1] // Credit card preferred
        case .transport, .coffee:
            weights = [0.3, 0.3, 0.3, 0.1] // Mixed
        default:
            weights = [0.4, 0.3, 0.2, 0.1] // Balanced
        }
        
        let random = Double.random(in: 0...1)
        var cumulative = 0.0
        
        for (index, weight) in weights.enumerated() {
            cumulative += weight
            if random <= cumulative {
                return methods[index]
            }
        }
        
        return methods.last!
    }
}
