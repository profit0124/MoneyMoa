//
//  Calendar+.swift
//  MoneyMoa
//
//  Created by Sooik Kim on 8/28/25.
//

import Foundation

public extension Calendar {
    /// 주어진 날짜의 달 시작일(1일 00:00)
    func startOfMonth(for date: Date) -> Date {
        let comps = dateComponents([.year, .month], from: date)
        return self.date(from: comps)!
    }
    /// 주어진 날짜가 속한 달의 exclusive end(다음 달 1일 00:00)
    func endOfMonthExclusive(for date: Date) -> Date {
        let s = startOfMonth(for: date)
        return self.date(byAdding: .month, value: 1, to: s)!
    }
}

// MARK: - Calendar.Identifier Extension

extension Calendar.Identifier {
    /// Calendar.Identifier를 문자열로 변환
    public var toString: String {
        switch self {
        case .gregorian: return "gregorian"
        case .buddhist: return "buddhist"
        case .chinese: return "chinese"
        case .coptic: return "coptic"
        case .ethiopicAmeteMihret: return "ethiopicAmeteMihret"
        case .ethiopicAmeteAlem: return "ethiopicAmeteAlem"
        case .hebrew: return "hebrew"
        case .iso8601: return "iso8601"
        case .indian: return "indian"
        case .islamic: return "islamic"
        case .islamicCivil: return "islamicCivil"
        case .japanese: return "japanese"
        case .persian: return "persian"
        case .republicOfChina: return "republicOfChina"
        case .islamicTabular: return "islamicTabular"
        case .islamicUmmAlQura: return "islamicUmmAlQura"
        default: return "gregorian"
        }
    }
}
