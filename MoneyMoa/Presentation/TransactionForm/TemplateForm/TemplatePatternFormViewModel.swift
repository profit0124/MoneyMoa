//
//  TemplatePatternFormViewModel.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 9/24/25.
//

import Foundation
import Observation

/// 템플릿 반복 패턴과 메모를 관리하는 ViewModel
///
/// 특징:
/// - Transaction의 DateAdditionalFormViewModel과 유사하지만 템플릿에 특화
/// - 반복 패턴은 필수 (기본값: none)
/// - 메모 설정
/// - 템플릿 생성일은 변경하지 않음 (RecurrencePattern만 구성)
@Observable
final class TemplatePatternFormViewModel: Identifiable {

    // MARK: - Properties

    /// 고유 식별자
    let id = UUID()

    /// 템플릿 메모 (선택사항, 20자 이상 시 요약 표시)
    var memo: String

    /// 반복 패턴 (필수, 기본값: none - 일회성)
    var recurrencePattern: RecurrencePattern

    // MARK: - Computed Properties

    /// 폼 유효성 검증
    var isValid: Bool {
        return recurrencePattern.isValid
    }

    /// 자동 생성된 패턴 설명
    var patternDescription: String {
        guard recurrencePattern.period != .none else { return "일회성 템플릿" }

        switch recurrencePattern.period {
        case .weekly:
            if let weekday = recurrencePattern.weekday {
                let weekdayName = Calendar.current.weekdaySymbols[weekday - 1]
                return "매주 \(weekdayName)"
            } else {
                return "매주"
            }
        case .monthly:
            if let day = recurrencePattern.dayOfMonth {
                return "매월 \(day)일"
            } else {
                return "매월"
            }
        case .yearly:
            if let month = recurrencePattern.yearlyMonth,
               let day = recurrencePattern.yearlyDay {
                let monthName = Calendar.current.monthSymbols[month - 1]
                return "매년 \(monthName) \(day)일"
            } else {
                return "매년"
            }
        case .none:
            return "일회성"
        }
    }
    
    /// 카드 요약 정보 생성
    var summary: String {
        var result: [String] = []

        if !memo.isEmpty {
            let truncatedMemo = memo.count > 20
            ? String(memo.prefix(20)) + "..."
            : memo
            result.append("📝 \(truncatedMemo)")
        }

        result.append("🔄 \(patternDescription)")

        return result.isEmpty ? "정보 없음" : result.joined(separator: " • ")
    }

    init(memo: String = "",
         recurrencePattern: RecurrencePattern = RecurrencePattern(period: .none)) {
        self.memo = memo
        self.recurrencePattern = recurrencePattern
    }

    // MARK: - Action Handling

    /// 사용자 액션 정의
    enum Action {
        case selectRecurrencePeriod(RecurrencePeriod)
        case selectWeekday(Int)          // 주간 반복: 요일 선택
        case selectDayOfMonth(Int)       // 월간 반복: 일 선택
        case selectYearlyMonth(Int)      // 연간 반복: 월 선택
        case selectYearlyDay(Int)        // 연간 반복: 일 선택
        case setHour(Int)                // 실행 시간 (시)
        case setMinute(Int)              // 실행 시간 (분)
    }

    func send(_ action: Action) {
        switch action {
        case .selectRecurrencePeriod(let period):
            updateRecurrencePeriod(period)
        case .selectWeekday(let weekday):
            setWeeklyPattern(weekday: weekday)
        case .selectDayOfMonth(let day):
            setMonthlyPattern(day: day)
        case .selectYearlyMonth(let month):
            setYearlyPattern(month: month, day: recurrencePattern.yearlyDay ?? 1)
        case .selectYearlyDay(let day):
            setYearlyPattern(month: recurrencePattern.yearlyMonth ?? 1, day: day)
        case .setHour(let hour):
            updateTime(hour: hour, minute: nil)
        case .setMinute(let minute):
            updateTime(hour: nil, minute: minute)
        }
    }

    // MARK: - Private Methods

    /// 반복 주기 업데이트
    private func updateRecurrencePeriod(_ period: RecurrencePeriod) {
        switch period {
        case .none:
            recurrencePattern = RecurrencePattern(
                period: .none,
                hour: recurrencePattern.hour,
                minute: recurrencePattern.minute,
                endOfMonthRule: recurrencePattern.endOfMonthRule
            )

        case .weekly:
            // 현재 요일을 기본값으로 설정
            let currentWeekday = Calendar.current.component(.weekday, from: Date())
            setWeeklyPattern(weekday: currentWeekday)

        case .monthly:
            // 현재 날짜의 일을 기본값으로 설정
            let currentDay = Calendar.current.component(.day, from: Date())
            setMonthlyPattern(day: currentDay)

        case .yearly:
            // 현재 날짜의 월과 일을 기본값으로 설정
            let currentMonth = Calendar.current.component(.month, from: Date())
            let currentDay = Calendar.current.component(.day, from: Date())
            setYearlyPattern(month: currentMonth, day: currentDay)
        }
    }

    private func setWeeklyPattern(weekday: Int) {
        recurrencePattern = RecurrencePattern.weekly(
            on: weekday,
            hour: recurrencePattern.hour,
            minute: recurrencePattern.minute
        )
    }

    private func setMonthlyPattern(day: Int) {
        recurrencePattern = RecurrencePattern.monthly(
            on: day,
            hour: recurrencePattern.hour,
            minute: recurrencePattern.minute,
            endOfMonthRule: recurrencePattern.endOfMonthRule
        )
    }

    private func setYearlyPattern(month: Int, day: Int) {
        recurrencePattern = RecurrencePattern.yearly(
            month: month,
            day: day,
            hour: recurrencePattern.hour,
            minute: recurrencePattern.minute,
            endOfMonthRule: recurrencePattern.endOfMonthRule
        )
    }

    private func updateTime(hour: Int?, minute: Int?) {
        let newHour = hour ?? recurrencePattern.hour
        let newMinute = minute ?? recurrencePattern.minute

        switch recurrencePattern.period {
        case .none:
            recurrencePattern = RecurrencePattern(
                period: .none,
                hour: newHour,
                minute: newMinute,
                endOfMonthRule: recurrencePattern.endOfMonthRule
            )
        case .weekly:
            let weekday = recurrencePattern.weekday ?? Calendar.current.component(.weekday, from: Date())
            recurrencePattern = RecurrencePattern.weekly(
                on: weekday,
                hour: newHour,
                minute: newMinute
            )
        case .monthly:
            let day = recurrencePattern.dayOfMonth ?? Calendar.current.component(.day, from: Date())
            recurrencePattern = RecurrencePattern.monthly(
                on: day,
                hour: newHour,
                minute: newMinute,
                endOfMonthRule: recurrencePattern.endOfMonthRule
            )
        case .yearly:
            let month = recurrencePattern.yearlyMonth ?? Calendar.current.component(.month, from: Date())
            let day = recurrencePattern.yearlyDay ?? Calendar.current.component(.day, from: Date())
            recurrencePattern = RecurrencePattern.yearly(
                month: month,
                day: day,
                hour: newHour,
                minute: newMinute,
                endOfMonthRule: recurrencePattern.endOfMonthRule
            )
        }
    }
}
