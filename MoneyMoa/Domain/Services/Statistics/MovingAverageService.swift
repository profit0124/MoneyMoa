//
//  MovingAverageService.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/28/25.
//

import Foundation

// MARK: - MovingAverageService (7일 이동평균)
public protocol MovingAverageService { func ma7(_ daily: [DailyPointDTO], calendar: Calendar) -> [DailyPointDTO] }

public struct MovingAverageServiceImpl: MovingAverageService {
    public init() {}
    public func ma7(_ daily: [DailyPointDTO], calendar: Calendar = Calendar.current) -> [DailyPointDTO] {
        // 입력이 비어 있으면 빈 배열 반환 (차트 처리 단순화를 위한 계약)
        guard !daily.isEmpty else { return [] }
        // 날짜 오름차순 정렬 후 슬라이딩 윈도우(최대 7개)로 평균 계산
        let sorted = daily.sorted { $0.date < $1.date }
        var window: [Decimal] = []
        var out: [DailyPointDTO] = []
        for i in 0..<sorted.count {
            window.append(sorted[i].amount)
            if window.count > 7 { window.removeFirst() }
            let avg = window.reduce(0, +) / Decimal(window.count)
            out.append(.init(
                date: sorted[i].date,
                amount: sorted[i].amount,
                movingAverage: avg,
                isWeekend: sorted[i].isWeekend
            ))
        }
        return out
    }
}
