//
//  GetStatisticsDashboardUseCase.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/29/25.
//

import Foundation

public protocol GetStatisticsDashboardUseCase {
    func execute(range: DateRange) async throws -> StatisticsDashboardDTO
}

actor StatisticsCache {
    private var map: [String: StatisticsDashboardDTO] = [:]
    private func key(for range: DateRange) -> String {
        "\(range.start.timeIntervalSince1970)-\(range.end.timeIntervalSince1970)"
    }
    func value(for range: DateRange) -> StatisticsDashboardDTO? { map[key(for: range)] }
    func set(_ v: StatisticsDashboardDTO, for range: DateRange) { map[key(for: range)] = v }
}
