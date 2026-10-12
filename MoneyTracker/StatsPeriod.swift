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

    func interval(offset: Int) -> DateInterval {
        let calendar = Calendar.current
        let shifted = calendar.date(byAdding: component, value: offset, to: Date())!
        return calendar.dateInterval(of: component, for: shifted)!
    }}
