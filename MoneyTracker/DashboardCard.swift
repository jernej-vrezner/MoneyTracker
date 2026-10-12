//
//  DashboardCard.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 12. 10. 2026.
//

import Foundation

enum DashboardCard: String, CaseIterable, Identifiable {
    case budget
    case flows
    case projection
    case categories
    case recent

    var id: String { rawValue }

    var title: String {
        switch self {
        case .budget: return "Poraba vs. budget"
        case .flows: return "Prilivi in odlivi"
        case .projection: return "Projekcija"
        case .categories: return "Budget po kategorijah"
        case .recent: return "Zadnje transakcije"
        }
    }

    static func decode(_ raw: String) -> [DashboardCard] {
        var cards = raw.split(separator: ",").compactMap { DashboardCard(rawValue: String($0)) }
        for card in allCases where !cards.contains(card) {
            cards.append(card)
        }
        return cards
    }

    static func decodeSet(_ raw: String) -> Set<DashboardCard> {
        Set(raw.split(separator: ",").compactMap { DashboardCard(rawValue: String($0)) })
    }

    static func encode(_ cards: [DashboardCard]) -> String {
        cards.map(\.rawValue).joined(separator: ",")
    }
}
