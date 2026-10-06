//
//  StatsPeriod.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 6. 10. 2026.
//

import Foundation

enum StatsPeriod: String, CaseIterable, Identifiable {
    case month = "Mesec"
    case quarter = "Kvartal"
    case year = "Leto"

    var id: String { rawValue }

    private var component: Calendar.Component {
        switch self {
        case .month: return .month
        case .quarter: return .quarter
        case .year: return .year
        }
    }

    var current: DateInterval {
        Calendar.current.dateInterval(of: component, for: Date())!
    }

    var previous: DateInterval {
        let justBeforeStart = current.start.addingTimeInterval(-1)
        return Calendar.current.dateInterval(of: component, for: justBeforeStart)!
    }
}
